#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

usage() {
    echo "Usage: ./compare-all.sh"
    echo -e "\t[DESIGN_DIRECTORY]\t(default: examples)"
    echo -e "\t[LOGS_DIRECTORY]\t(default: ./comp_logs)"
    echo
    echo "Environment variables:"
    echo -e "\tEXAMPLES_FILTER\tcomma-separated pub fn names to run instead of"
    echo -e "\t\tevery function (e.g. EXAMPLES_FILTER=dot8,sha256,zstd). Files"
    echo -e "\t\twithout a selected function are skipped. Unknown names are"
    echo -e "\t\treported and ignored."
    echo -e "\tSKIP_MUTATIONS\tinteger that when present skips all the"
    echo -e "\t\texamples inside _mutations subdirectory"
    echo -e "\tRUN_ONLY_MUTATIONS\tinteger that when present runs only"
    echo -e "\t\texamples inside mutations directory"
    echo
    echo "runs the area estimate for every pub fn in every design of a"
    echo "directory tree and prints the results as one table per design file. It also"
    echo "saves each table to a log file so the plots below can be regenerated later."
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac
[[ $# -le 2 ]] || { usage >&2; exit 2; }

design_root=${1:-examples}
comp_logs_dir=${2:-./comp_logs}
export LC_ALL=C  # decimal point, not comma, in awk/printf

# EXAMPLES_FILTER: comma-separated pub fn names to run instead of every
# function, e.g. EXAMPLES_FILTER=dot8,sha256,zstd
examples_filter=${EXAMPLES_FILTER:-}
if [[ -n "$examples_filter" ]]; then
    IFS=',' read -ra filter_names <<< "$examples_filter"
    filter_set=$(printf '%s\n' "${filter_names[@]}" | sort -u)
    echo "Running only selected functions: $examples_filter" >&2
fi

in_filter() {
    [[ -z "$examples_filter" ]] && return 0
    grep -qxF "$1" <<< "$filter_set"
}

known_functions=$(find "$design_root" -mindepth 2 -maxdepth 2 -name '*.x' -exec sed -n 's/^pub fn \([A-Za-z0-9_]*\).*/\1/p' {} + 2>/dev/null | sort -u)
if [[ -n "$examples_filter" ]]; then
    while IFS= read -r name; do
        if ! grep -qxF "$name" <<< "$known_functions"; then
            echo "warning: no pub fn named '$name' under $design_root, skipping" >&2
        fi
    done <<< "$filter_set"
fi

# Without ORFS (SKIP_ORFS) there is no ORFS area, so leave out its column.
skip_orfs=0
if [[ ${SKIP_ORFS:-0} != 0 ]]; then
    skip_orfs=1
fi

print_header() {
    if ((skip_orfs)); then
        printf '%-25s %10s %10s %6s %10s %10s %10s\n' function g8r_um2 yosys_um2 ratio ir2g8r_ms g8r_ms yosys_ms
    else
        printf '%-25s %10s %10s %6s %10s %10s %10s %10s\n' function g8r_um2 yosys_um2 ratio orfs_um2 ir2g8r_ms g8r_ms yosys_ms
    fi
}

print_header
for design_dir in "$design_root"/*; do
    if [ ! -d "$design_dir" ]; then
        continue
    fi;

    if (( ${SKIP_MUTATIONS:-0} )); then
        if [[ $(basename "$design_dir") == "_mutations" ]]; then
            continue
        fi
    fi

    if (( ${RUN_ONLY_MUTATIONS:-0} )); then
        if [[ $(basename "$design_dir") != "_mutations" ]]; then
            continue
        fi
    fi

    logs_design_dir=$comp_logs_dir/$(basename "$design_dir")
    if [ ! -d "$logs_design_dir" ]; then
        mkdir -p "$logs_design_dir"
    fi

    for design in "$design_dir"/*.x; do
        design_name=$(basename "$design" | cut -d '.' -f1)
        output_file=$logs_design_dir/$design_name

        PRINTED_HEADER=0
        for top in $(sed -n 's/^pub fn \([A-Za-z0-9_]*\).*/\1/p' "$design"); do
            if ! in_filter "$top"; then
                continue
            fi
            if [[ $PRINTED_HEADER -eq 0 ]]; then
                print_header > "$output_file".log
                PRINTED_HEADER=1
            fi
            build_dir="build/$design_dir/$design_name"
            mkdir -p "$build_dir"

            err_log="$build_dir/$top.err.log"
            if ! result=$(./estimate-cell-area.sh "$(realpath "$design")" "$top" "$build_dir" 2>"$err_log" | tail -6); then
                echo "FAILED: $design $top, see $err_log" >&2
                continue
            fi
            echo "$result" | awk -v f="$top" -v skip_orfs="$skip_orfs" '
            {
                # CPU time (field 5) of the timing lines, then the areas.
                a[NR] = NR <= 3 ? $5 : $2
            } END {
                IR2G8R_TIME = a[1];
                G8R_TIME = a[2];
                YOSYS_TIME = a[3];
                G8R_AREA = a[4];
                YOSYS_AREA = a[5];
                ORFS_AREA = a[6];

                printf "%-25s %10.2f %10.2f", f, G8R_AREA, YOSYS_AREA

                if (YOSYS_AREA != 0) {
                    printf " %6.2f", G8R_AREA / YOSYS_AREA
                } else {
                    printf "   inf"
                }

                if (!skip_orfs) {
                    printf " %10.2f", ORFS_AREA
                }
                printf " %10.2f %10.2f %10.2f ", IR2G8R_TIME, G8R_TIME, YOSYS_TIME
                printf "\n"
            }' | tee -a "$comp_logs_dir/$(basename "$design_dir")/$(basename "$design" | cut -d '.' -f1).log"
        done
    done
done
