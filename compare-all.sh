#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# Usage: ./compare-all.sh [DESIGN_DIR]      (default: ./examples)
#                         [COMP_LOGS_DIR]   (default: ./comp_logs)
# Runs estimate-cell-area.sh on every `pub fn` and prints one table.
design_root=${1:-examples}
comp_logs_dir=${2:-./comp_logs}
export LC_ALL=C  # decimal point, not comma, in awk/printf

print_header() {
    printf '%-25s %10s %10s %6s %10s %10s %10s %10s\n' function g8r_um2 yosys_um2 ratio orfs_um2 ir2g8r_ms g8r_ms yosys_ms
}

print_header
for design_dir in $design_root/*; do
    if [ ! -d $design_dir ]; then continue; fi;
    if [ ! -d $comp_logs_dir/$(basename $design_dir) ]; then
        mkdir -p $comp_logs_dir/$(basename $design_dir)
    fi
    for design in $design_dir/*.x; do
        print_header > $comp_logs_dir/$(basename $design_dir)/$(echo $(basename $design) | cut -d '.' -f1).log
        for top in $(sed -n 's/^pub fn \([A-Za-z0-9_]*\).*/\1/p' "$design"); do
            build_dir="build/$design_dir/$(echo $(basename $design) | cut -d '.' -f1)"
            if [ -z $build_dir ]; then
                mkdir -p $build_dir
            fi
            ./estimate-cell-area.sh "$(realpath $design)" "$top" "$build_dir" 2>/dev/null | tail -6 | awk -v f="$top" '
            { a[NR] = $2 }
            END {
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
                printf " %10.2f %10.2f %10.2f %10.2f ", ORFS_AREA, IR2G8R_TIME, G8R_TIME, YOSYS_TIME
                printf "\n"
            }' | tee -a "$comp_logs_dir/$(basename "$design_dir")/$(basename "$design" | cut -d '.' -f1).log"
        done
    done
done
