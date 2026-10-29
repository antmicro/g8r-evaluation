#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

usage() {
    echo "Usage: ./show-raw-g8r.sh DESIGN.x TOP"
    echo -e "\t[DESIGN_PATH]"
    echo -e "\t[TOP_MODULE]"
    echo
    echo "Writes optimized IR, prepared IR, g8r, AIGER, and stats to build/."
}

case "${1:-}" in
    ""|-h|--help) usage; exit 0 ;;
esac
[[ $# -eq 2 ]] || { usage >&2; exit 2; }

design=$1
top=$2
output="build/$top"

[[ -f "$design" ]] || { echo "Cannot find $design" >&2; exit 1; }
[[ "$top" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || { echo "Invalid top: $top" >&2; exit 2; }

driver=tools/xlsynth/bin/xlsynth-driver
[[ -x "$driver" ]] || { echo "Run ./setup.sh first." >&2; exit 1; }

mkdir -p build
echo "Input: $design:$top"

echo "1/3  DSLX -> optimized IR"
"$driver" dslx2ir \
    --dslx_input_file "$design" --dslx_top "$top" --opt true \
    > "$output.opt.ir"

echo "2/3  Prepare IR for gates"
"$driver" ir-prep-for-gates "$output.opt.ir" \
    --enable-formal-array-alias-analysis false \
    > "$output.prepared.ir"
diff -u "$output.opt.ir" "$output.prepared.ir" | sed -n '/^[-+]  /p' || true

echo "3/3  IR -> g8r and AIGER"
"$driver" ir2g8r "$output.opt.ir" \
    --enable-formal-array-alias-analysis false \
    --aiger-out "$output.aag" \
    --stats-out "$output.stats.json" \
    > "$output.g8r"

read -r _ _ inputs _ outputs ands < "$output.aag"
depth=$(sed -n 's/.*"deepest_path": \([0-9]*\).*/\1/p' "$output.stats.json")

echo
echo "$inputs inputs, $outputs outputs, $ands AND nodes, depth $depth"
echo "Files: $output.{opt.ir,prepared.ir,g8r,aag,stats.json}"
