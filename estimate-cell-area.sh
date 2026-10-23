#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

usage() {
    echo "Usage: ./estimate-cell-area.sh DESIGN.x TOP"
    echo
    echo "Compare g8r and SystemVerilog/Yosys area using the bundled ASAP7 library."
    echo "Results are written as build/TOP.*."
}

case "${1:-}" in
    ""|-h|--help) usage; exit 0 ;;
esac
[[ $# -eq 3 ]] || { usage >&2; exit 2; }

design=$1
top=$2
build_dir=${3:-./build}
output="build/$top"
libs=(lib/*.lib)
driver=tools/xlsynth/bin/xlsynth-driver
codegen=tools/xls/codegen_main-ubuntu2004

mkdir -p $build_dir

echo "1/7  Prepare ASAP7"
"$driver" lib2proto "${libs[@]}" \
    --include-timing \
    --output build/asap7.proto

echo "2/7  DSLX -> optimized IR"
"$driver" dslx2ir \
    --dslx_input_file "$design" --dslx_top "$top" --opt true \
    > "$output.opt.ir"

start_g8r=$(date +%s%3N)
echo "3/7  Prepare IR for gates"
"$driver" ir-prep-for-gates "$output.opt.ir" \
    --enable-formal-array-alias-analysis false \
    > "$output.prepared.ir"
diff -u "$output.opt.ir" "$output.prepared.ir" | sed -n '/^[-+]  /p' || true

start_ir2g8r=$(date +%s%3N)
echo "4/7  IR -> g8r and AIGER"
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
    --netlist_out "$output.g8r-mapped.v"
"$driver" gv-area \
    --netlist "$output.g8r-mapped.v" \
    --liberty_proto build/asap7.proto \
    --module_name "$top" \
    --json_out "$output.g8r-area.json" \
    > /dev/null
end_g8r=$(date +%s%3N)

start_yosys=$(date +%s%3N)
echo "6/7  IR -> SystemVerilog -> Yosys/ASAP7 cells"
"$codegen" \
    --generator=combinational \
    --delay_model=unit \
    --use_system_verilog \
    --module_name="$top" \
    "$output.opt.ir" \
    > "$output.sv"

liberty_args=$(printf ' -liberty %s' "${libs[@]}")
yosys -q -l "$output.yosys.log" -p \
    "read_verilog -sv $output.sv; hierarchy -top $top; synth -top $top -noabc; abc$liberty_args; opt_clean -purge; write_verilog -noattr -noexpr $output.yosys-mapped.v; stat $liberty_args"
end_yosys=$(date +%s%3N)

g8r_area=$(sed -n 's/.*"area": \([^,]*\),/\1/p' "$output.g8r-area.json" | head -1)
yosys_area=$(cat $output.yosys.log | grep 'Chip area for module' | cut -d ':' -f2)

echo
echo "Area and time comparison (ASAP7):"
LC_NUMERIC=C printf '  ir2g8r: %.2f ms\n  g8r:   %.2f ms\n  Yosys: %.2f ms\n' "$((end_ir2g8r - start_ir2g8r))" "$((end_g8r - start_g8r))" "$((end_yosys - start_yosys))"
LC_NUMERIC=C printf '  g8r:   %.2f um^2\n  Yosys: %.2f um^2\n' "$g8r_area" "$yosys_area"
