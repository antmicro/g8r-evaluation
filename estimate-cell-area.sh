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
    echo
    echo "Set SKIP_ORFS=1 to skip the slow ORFS place-and-route run; the ORFS area"
    echo "is then reported as 0."
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
orfs_path=${5:-tools/orfs}
yosys=$orfs_path/tools/install/yosys/bin/yosys

mkdir -p "$build_dir"

create_orfs_config() {
    DESIGN_FILE=$1
    DESIGN_NAME=$2

    OUT_FILE="$output.config.mk"

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
    echo "export SKIP_CTS_REPAIR_TIMING=1" >> "$OUT_FILE"
}

run_orfs() {
    local orfs=(make -C "$orfs_path"/flow DESIGN_CONFIG="$(realpath "$output.config.mk")"
                WORK_HOME="$(realpath "$output").orfs")
    rm -f "$output".orfs.log
    for stage in clean_all synth floorplan place cts route; do
        "${orfs[@]}" "$stage" >> "$output".orfs.log 2>&1 ||
            { echo "ORFS $stage failed, see $output.orfs.log" >&2; exit 1; }
    done
}

require_area() {
    [[ -n $2 ]] || { echo "Could not read $1 area from $3" >&2; exit 1; }
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
    --output "$build_dir/asap7.proto"

echo "2/7  DSLX -> optimized IR"
"$driver" dslx2ir \
    --dslx_input_file "$design" --dslx_top "$top" --opt true \
    > "$output.opt.ir"

echo "3/7  Prepare IR for gates"
"$driver" ir-prep-for-gates "$output.opt.ir" \
    --enable-formal-array-alias-analysis false \
    > "$output.prepared.ir"
diff -u "$output.opt.ir" "$output.prepared.ir" | sed -n '/^[-+]  /p' || true

liberty_args=$(printf ' -liberty %s' "${libs[@]}")
# Run both flows in each iteration, so load affects them alike.
timing_runs=${TIMING_RUNS:-5}
((timing_runs >= 1)) || { echo "TIMING_RUNS must be >= 1" >&2; exit 2; }
TIMEFORMAT='%3R %3U %3S'
# Run a command; print its wall and CPU (user + system) time in ms.
timed() {
    local t
    t=$( { time "$@" 2>&4; } 4>&2 2>&1 ) || return
    set -- $t
    echo "$((10#${1/[.,]/})) $((10#${2/[.,]/} + 10#${3/[.,]/}))"
}
run_ir2g8r() {
    "$driver" ir2g8r "$output.opt.ir" \
        --enable-formal-array-alias-analysis false \
        --aiger-out "$output.aag" \
        > /dev/null
}
run_g8r_mapping() {
    "$driver" aig-tech-map "$output.aag" \
        --strategy area \
        --liberty_proto "$build_dir/asap7.proto" \
        --module_name "$top" \
        --netlist_out "$output.g8r-mapped.v" \
        > "$output.aig-tech-map.log"
    "$driver" gv-area \
        --netlist "$output.g8r-mapped.v" \
        --liberty_proto "$build_dir/asap7.proto" \
        --module_name "$top" \
        --json_out "$output.g8r-area.json" \
        > /dev/null
}
run_yosys() {
    "$codegen" \
        --generator=combinational \
        --delay_model=unit \
        --use_system_verilog \
        --module_name="$top" \
        "$output.opt.ir" \
        > "$output.sv"

    # opt_clean -purge drops the unused wires, some driven by 'x, that gv-area
    # cannot read.
    "$yosys" -q -l "$output.yosys.log" -p \
        "read_verilog -sv $output.sv; hierarchy -top $top; synth -top $top -noabc; tee -o $output.abc.log abc$liberty_args; opt; opt_clean -purge; write_verilog -noattr -noexpr $output.yosys-mapped.v"
    "$driver" gv-area \
        --netlist "$output.yosys-mapped.v" \
        --liberty_proto "$build_dir/asap7.proto" \
        --module_name "$top" \
        --json_out "$output.yosys-area.json" \
        > /dev/null
}
ir2g8r_ms=() g8r_ms=() yosys_ms=() ir2g8r_cpu=() g8r_cpu=() yosys_cpu=()
for ((run = 0; run <= timing_runs; run++)); do
    echo "4-6/7  Run $run/$timing_runs: IR -> g8r -> ASAP7 cells, IR -> SystemVerilog -> Yosys/ASAP7 cells"
    ir2g8r=($(timed run_ir2g8r))
    mapping=($(timed run_g8r_mapping))
    yosys_run=($(timed run_yosys))
    ((run > 0)) || continue # run 0 is a warm-up
    ir2g8r_ms+=("${ir2g8r[0]}")
    g8r_ms+=($((ir2g8r[0] + mapping[0])))
    yosys_ms+=("${yosys_run[0]}")
    ir2g8r_cpu+=("${ir2g8r[1]}")
    g8r_cpu+=($((ir2g8r[1] + mapping[1])))
    yosys_cpu+=("${yosys_run[1]}")
done

g8r_area=$(sed -n 's/.*"area": \([^,]*\),/\1/p' "$output.g8r-area.json" | head -1)
yosys_area=$(sed -n 's/.*"area": \([^,]*\),/\1/p' "$output.yosys-area.json" | head -1)
require_area g8r "$g8r_area" "$output.g8r-area.json"
require_area Yosys "$yosys_area" "$output.yosys-area.json"

if [[ ${SKIP_ORFS:-0} != 0 ]]; then
    echo "7/7  ORFS area estimation skipped (SKIP_ORFS)"
    ORFS_AREA=0
else
    echo "7/7  ORFS area estimation"
    create_orfs_config "$output.sv" "$top"
    run_orfs

    ORFS_AREA=$(sed -n 's/.*Design area \([^ ]*\).*/\1/p' "$output".orfs.log | tail -1)
    require_area ORFS "$ORFS_AREA" "$output.orfs.log"
fi

median() {
    printf '%s\n' "$@" | sort -n | sed -n "$((($# + 1) / 2))p"
}

echo
echo "Timing, area and time comparison (ASAP7):"
# Median wall time, CPU time (read by compare-all.sh) and wall-time range.
timing_line() {
    local wall=($2) cpu=($3)
    local range=($(printf '%s\n' "${wall[@]}" | sort -n | sed -n '1p;$p'))
    LC_NUMERIC=C printf '  %-16s%.2f ms  (CPU %.2f ms; wall min %.2f, max %.2f ms over %d runs)\n' \
        "$1:" "$(median "${wall[@]}")" "$(median "${cpu[@]}")" "${range[0]}" "${range[-1]}" "${#wall[@]}"
}
timing_line ir2g8r "${ir2g8r_ms[*]}" "${ir2g8r_cpu[*]}"
timing_line g8r "${g8r_ms[*]}" "${g8r_cpu[*]}"
timing_line Yosys "${yosys_ms[*]}" "${yosys_cpu[*]}"
LC_NUMERIC=C printf '  g8r:            %.2f um^2\n  Yosys:          %.2f um^2\n  ORFS:           %.2f um^2\n' "$g8r_area" "$yosys_area" "$ORFS_AREA"
