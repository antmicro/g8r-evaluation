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

echo "1/5  DSLX -> IR -> g8r"
./show-raw-g8r.sh "$design" "$top"

echo
echo "2/5  Prepare ASAP7"
"$driver" lib2proto "${libs[@]}" \
    --include-timing \
    --output build/asap7.proto

echo "3/5  g8r -> ASAP7 cells -> area"
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

echo "4/5  IR -> SystemVerilog -> Yosys/ASAP7 cells"
"$codegen" \
    --generator=combinational \
    --delay_model=unit \
    --use_system_verilog \
    --module_name="$top" \
    "$output.opt.ir" \
    > "$output.sv"

liberty_args=$(printf ' -liberty %s' "${libs[@]}")
yosys -q -l "$output.yosys.log" -p \
    "read_verilog -sv $output.sv; hierarchy -top $top; synth -top $top -noabc; abc$liberty_args; opt_clean -purge; write_verilog -noattr -noexpr $output.yosys-mapped.v"

echo "5/5  Yosys cells -> area"
"$driver" gv-area \
    --netlist "$output.yosys-mapped.v" \
    --liberty_proto build/asap7.proto \
    --module_name "$top" \
    --json_out "$output.yosys-area.json" \
    > /dev/null

g8r_area=$(sed -n 's/.*"area": \([^,]*\),/\1/p' "$output.g8r-area.json" | head -1)
yosys_area=$(sed -n 's/.*"area": \([^,]*\),/\1/p' "$output.yosys-area.json" | head -1)

echo
echo "Area comparison (ASAP7):"
LC_NUMERIC=C printf '  g8r:   %.2f um^2\n  Yosys: %.2f um^2\n' "$g8r_area" "$yosys_area"
