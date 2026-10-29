#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

usage() {
    echo "Usage: ./estimate-cell-area.sh"
    echo -e "\t[DESIGN_PATH]"
    echo -e "\t[TOP_MODULE]"
    echo -e "\t[BUILD_DIR]\t(default: ./build)"
    echo -e "\t[XLSYNTH_DRIVER_PATH]\t(default: tools/xlsynth/bin/xlsynth-driver)"
    echo -e "\t[ORFS_PATH]\t(default: tools/orfs)"
    echo
    echo "Estimates area of physical design and compares the results"
    echo "from g8r, Yosys and OpenROAD. Also includes ir2g8r, g8r and Yosys area"
    echo "estimation execution time. g8r time includes also the time spent inside ir2g8r."
}

case "${1:-}" in
    ""|-h|--help) usage; exit 0 ;;
esac
[[ $# -ge 2 ]] && [[ $# -le 5 ]] || { usage >&2; exit 2; }

design=$1
top=$2
build_dir=${3:-./build}
output="$build_dir/$top"
libs=(lib/*.lib)
driver=${4:-tools/xlsynth/bin/xlsynth-driver}
codegen=tools/xls/codegen_main-ubuntu2004
orfs_path=${5:-tools/orfs/}

mkdir -p "$build_dir"

create_orfs_config() {
    DESIGN_FILE=$1
    DESIGN_NAME=$2

    OUT_FILE="config.mk"

    echo "export PLATFORM=asap7" > "$OUT_FILE"
    echo "export DESIGN_NAME=${DESIGN_NAME}" >> "$OUT_FILE"
    echo "export DESIGN_NICKNAME=${DESIGN_NAME}" >> "$OUT_FILE"
    echo "export VERILOG_FILES=$(realpath "$DESIGN_FILE")" >> "$OUT_FILE"
    echo "export SDC_FILE=$(pwd)/empty.sdc" >> "$OUT_FILE"
    echo "export CORE_UTILIZATION=0.70" >> "$OUT_FILE"
    echo "export CORE_ASPECT_RATIO=1" >> "$OUT_FILE"
    echo "export CORE_MARGIN=2" >> "$OUT_FILE"
    echo "export PLACE_DENSITY=0.75" >> "$OUT_FILE"
    echo "export TNS_END_PERCENT=100" >> "$OUT_FILE"
    echo "export SYNTH_USE_SYN=1" >> "$OUT_FILE"
}

run_orfs() {
    make -C "$orfs_path"/flow DESIGN_CONFIG="$(pwd)"/config.mk clean_all synth RESULTS_DIR=res_dir 2>/dev/null > "$output".orfs.log
    make -C "$orfs_path"/flow DESIGN_CONFIG="$(pwd)"/config.mk floorplan RESULTS_DIR=res_dir 2>/dev/null >> "$output".orfs.log
    make -C "$orfs_path"/flow DESIGN_CONFIG="$(pwd)"/config.mk cts RESULTS_DIR=res_dir 2>/dev/null >> "$output".orfs.log
    make -C "$orfs_path"/flow DESIGN_CONFIG="$(pwd)"/config.mk place RESULTS_DIR=res_dir 2>/dev/null >> "$output".orfs.log
    make -C "$orfs_path"/flow DESIGN_CONFIG="$(pwd)"/config.mk route RESULTS_DIR=res_dir 2>/dev/null >> "$output".orfs.log
}

echo "DSLX design file: $design"
echo "Top pub fn name: $top"
echo "Directory for generated files: $build_dir"
echo "xlsynth-driver path :$driver"
echo "OpenROAD flow scripts path: $orfs_path"

echo
echo "1/7  Prepare ASAP7"
"$driver" lib2proto "${libs[@]}" \
    --include-timing \
    --output build/asap7.proto

echo "2/7  DSLX -> optimized IR"
"$driver" dslx2ir \
    --dslx_input_file "$design" --dslx_top "$top" --opt true \
    > "$output.opt.ir"

echo "3/7  Prepare IR for gates"
start_g8r=$(date +%s%3N)
"$driver" ir-prep-for-gates "$output.opt.ir" \
    --enable-formal-array-alias-analysis false \
    > "$output.prepared.ir"
diff -u "$output.opt.ir" "$output.prepared.ir" | sed -n '/^[-+]  /p' || true

echo "4/7  IR -> g8r"
start_ir2g8r=$(date +%s%3N)
"$driver" ir2g8r "$output.opt.ir" \
    --enable-formal-array-alias-analysis false \
    --aiger-out "$output.aag" \
    --stats-out "$output.stats.json" \
    > "$output.g8r"
end_ir2g8r=$(date +%s%3N)

echo "5/7  g8r -> ASAP7 cells -> area"
"$driver" aig-tech-map "$output.aag" \
    --strategy area \
    --liberty_proto build/asap7.proto \
    --module_name "$top" \
    --netlist_out "$output.g8r-mapped.v" \
    > "$output.aig-tech-map.log"
"$driver" gv-area \
    --netlist "$output.g8r-mapped.v" \
    --liberty_proto build/asap7.proto \
    --module_name "$top" \
    --json_out "$output.g8r-area.json" \
    > /dev/null
end_g8r=$(date +%s%3N)

echo "6/7  IR -> SystemVerilog -> Yosys/ASAP7 cells"
start_yosys=$(date +%s%3N)
"$codegen" \
    --generator=combinational \
    --delay_model=unit \
    --use_system_verilog \
    --module_name="$top" \
    "$output.opt.ir" \
    > "$output.sv"

liberty_args=$(printf ' -liberty %s' "${libs[@]}")
yosys -q -l "$output.yosys.log" -p \
    "read_verilog -sv $output.sv; hierarchy -top $top; synth -top $top -noabc; tee -o run.abc.log  abc$liberty_args; opt; write_verilog -noattr -noexpr $output.yosys-mapped.v; stat $liberty_args;"
end_yosys=$(date +%s%3N)

g8r_area=$(sed -n 's/.*"area": \([^,]*\),/\1/p' "$output.g8r-area.json" | head -1)
yosys_area=$(cat "$output".yosys.log | grep 'Chip area for module' | cut -d ':' -f2)

echo "7/7  ORFS area estimation"
create_orfs_config "$output.sv" "$top"
run_orfs

ORFS_AREA=$(tail -n 10 "$output".orfs.log | grep 'Design area' | cut -d' ' -f3)

echo
echo "Timing, area and time comparison (ASAP7):"
LC_NUMERIC=C printf '  ir2g8r:         %.2f ms\n  g8r:            %.2f ms\n  Yosys:          %.2f ms\n' "$((end_ir2g8r - start_ir2g8r))" "$((end_g8r - start_g8r))" "$((end_yosys - start_yosys))"
LC_NUMERIC=C printf '  g8r:            %.2f um^2\n  Yosys:          %.2f um^2\n  ORFS:           %.2f um^2\n' "$g8r_area" "$yosys_area" "$ORFS_AREA"
