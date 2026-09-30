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

printf '%-16s %10s %10s %6s\n' function g8r_um2 yosys_um2 ratio
for design_dir in $design_root/*; do
    if [ ! -d $design_dir ]; then continue; fi;
    if [ ! -d $comp_logs_dir/$(basename $design_dir) ]; then
        mkdir -p $comp_logs_dir/$(basename $design_dir)
    fi
    for design in $design_dir/*.x; do
        printf '%-16s %10s %10s %6s\n' function g8r_um2 yosys_um2 ratio > $comp_logs_dir/$(basename $design_dir)/$(echo $(basename $design) | cut -d '.' -f1).log
        for top in $(sed -n 's/^pub fn \([A-Za-z0-9_]*\).*/\1/p' "$design"); do
            build_dir="build/$design_dir/$(echo $(basename $design) | cut -d '.' -f1)"
            if [ -z $build_dir ]; then
                mkdir -p $build_dir
            fi
            ./estimate-cell-area.sh "$(realpath $design)" "$top" 2>/dev/null | tail -2 | awk -v f="$top" '
                { a[NR] = $2 }
            END {
                printf "%-16s %10.2f %10.2f %6.2f\n", f, a[1], a[2], a[1] / a[2]
            }' | tee -a $comp_logs_dir/$(basename $design_dir)/$(echo $(basename $design) | cut -d '.' -f1).log
        done
    done
done
