#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

usage() {
    echo "Usage: ./analyze-flows.sh"
    echo -e "\t[DESIGN_LIST]\t(default: analysis-designs.txt, one pub fn name per line)"
    echo -e "\t[OUTPUT_DIR]\t(default: ./flow_analysis)"
    echo
    echo "For each function: estimate-cell-area.sh (without ORFS) prepares the inputs,"
    echo "compare-flows.sh compares the four flows, and time-passes.sh times their"
    echo "passes. Writes OUTPUT_DIR/flows.tsv and OUTPUT_DIR/passes/<function>.tsv,"
    echo "which scripts/flows_report.py summarizes, and the output of each step in"
    echo "OUTPUT_DIR/build/<function>/."
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac
[[ $# -le 2 ]] || { usage >&2; exit 2; }

list=${1:-analysis-designs.txt}
out_dir=${2:-./flow_analysis}
# Start from empty outputs: flows_report.py reads every TSV in passes/, so
# nothing may remain from another run.
mkdir -p "$out_dir/passes"
rm -f "$out_dir/flows.tsv" "$out_dir"/passes/*

while read -r top; do
    # Skip blank lines and comments of the design list.
    [[ -n $top && $top != \#* ]] || continue
    # Find the example that defines the function; skip unknown names.
    design=$(grep -lE "^pub fn $top\b" examples/*/*.x) || { echo "No pub fn $top under examples/" >&2; continue; }
    build=$out_dir/build/$top
    mkdir -p "$build"
    echo "== $top ($design)" >&2

    # Prepare the optimized IR and the Liberty proto that the flows start from.
    if ! SKIP_ORFS=1 TIMING_RUNS=1 ./estimate-cell-area.sh "$design" "$top" "$build" \
        > "$build/estimate.log" 2>&1; then
        echo "FAILED: estimate-cell-area.sh, see $build/estimate.log" >&2
        continue
    fi
    # Measure the area and CPU time of the four flows.
    if ! ./compare-flows.sh "$build" "$top" > "$build/flows.tsv" 2> "$build/flows.err"; then
        echo "FAILED: compare-flows.sh, see $build/flows.err" >&2
        continue
    fi
    # Time every pass of the four flows.
    if ! ./time-passes.sh "$build" "$top" > "$build/passes.tsv" 2> "$build/passes.err"; then
        echo "FAILED: time-passes.sh, see $build/passes.err" >&2
        continue
    fi

    # Show the results of the design on the console.
    column -t -s $'\t' "$build/flows.tsv" >&2

    # Add the design to the outputs, now that all its steps succeeded; the
    # first one also gives the header.
    [[ -s $out_dir/flows.tsv ]] || head -1 "$build/flows.tsv" > "$out_dir/flows.tsv"
    tail -n +2 "$build/flows.tsv" >> "$out_dir/flows.tsv"
    cp "$build/passes.tsv" "$out_dir/passes/$top.tsv"
done < "$list"

[[ -s $out_dir/flows.tsv ]] || { echo "No design was analyzed" >&2; exit 1; }
