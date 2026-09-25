#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# Usage: ./compare-all.sh [DESIGN.x]   (default: example.x)
# Runs estimate-cell-area.sh on every `pub fn` and prints one table.
design=${1:-example.x}
export LC_ALL=C  # decimal point, not comma, in awk/printf

printf '%-16s %10s %10s %6s\n' function g8r_um2 yosys_um2 ratio
for top in $(sed -n 's/^pub fn \([A-Za-z0-9_]*\).*/\1/p' "$design"); do
    ./estimate-cell-area.sh "$design" "$top" 2>/dev/null | tail -2 | awk -v f="$top" '
        { a[NR] = $2 }
        END { printf "%-16s %10.2f %10.2f %6.1f\n", f, a[1], a[2], a[1] / a[2] }'
done
