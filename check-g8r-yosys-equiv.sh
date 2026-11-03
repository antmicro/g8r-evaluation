#!/bin/bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

# This script does check if g8r and yosys generated mapped verilog
# files represent logically equal designs for each generated example
# inside build_dir.
#
# It achieves this using commonize_ports.py script to make input/output
# port names the same, later it runs kepler-formal to actually verify
# logic equality.

set -euo pipefail

usage() {
    echo "Usage: ./check-g8r-yosys-equiv.sh"
    echo -e "\t[BUILD_DIR]\t(default: ./build/examples)"
    echo
    echo "Checks if g8r and yosys generated mapped verilog"
    echo "files represent logically equal designs for each generated example"
    echo "inside build_dir."
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac
[[ $# -le 1 ]] || { usage >&2; exit 2; }

build_dir=${1:-./build/examples}

function commonize_designs() {
    top=$1
    local build_dir=$2
    g8r_netlist=$build_dir/$top.g8r-mapped.v

    python3 ./scripts/commonize_ports.py $g8r_netlist
}

function check_design_equiv_kepler() {
    top=$1
    local build_dir=$2
    yosys_netlist=$build_dir/$top.yosys-mapped.v
    g8r_netlist_postcommonized=$build_dir/$top.g8r-mapped_wrapped.v

    ./tools/kepler/bin/kepler-formal -verilog \
        --design1 "$g8r_netlist_postcommonized" \
        --design2 "$yosys_netlist" \
        --liberty ./lib/*.lib \
        --allow-boundary-mismatch -v sec

    return $?
}

function create_eqy_cfg() {
    top=$1
    local build_dir=$2

    yosys_netlist=$build_dir/$top.yosys-mapped.v
    g8r_netlist_postcommonized=$build_dir/$top.g8r-mapped_wrapped.v
    libs=(./lib/*.lib)
    liberty_args=$(printf 'read_liberty -ignore_miss_func %s\n' "${libs[@]}")

cat << EOF > $build_dir/$top.cfg.eqy
    [options]

    [gold]
    $liberty_args
    read_verilog $yosys_netlist
    prep -top $top
    flatten
    memory_map

    [gate]
    $liberty_args
    read_verilog $g8r_netlist_postcommonized
    prep -top $top
    flatten
    memory_map

    [collect $top]
    join *
    group out*
    group *

    [strategy simple]
    use sat
    depth 3
EOF
}

function check_design_equiv_eqy() {
    top=$1
    local build_dir=$2
    yosys_netlist=$build_dir/$top.yosys-mapped.v
    g8r_netlist_postcommonized=$build_dir/$top.g8r-mapped_wrapped.v

    create_eqy_cfg $top $build_dir


    yosys_bin=$(pwd)/tools/orfs/tools/install/yosys/bin
    YOSYS=$yosys_bin/yosys ABC=$yosys_bin/yosys-abc SMTBMC=$yosys_bin/yosys-smtbmc \
    python3 ./tools/eqy/src/eqy.py $build_dir/$top.cfg.eqy -d $build_dir/$top.eqy_dir -f \
        > "$build_dir/$top.eqy.log" 2>&1
    return $?
}

printf '%-25s %-25s %-25s\n' function kepler yosys_eqy
for logs_dir in "$build_dir"/*; do
    if [ ! -d "$logs_dir" ]; then
        continue
    fi;

    for examples_dir in "$logs_dir"/*; do
        for g8r_netlist in "$examples_dir"/*g8r-mapped.v; do
            top_name=$(basename "$g8r_netlist" | cut -d'.' -f1)

            commonize_designs "$top_name" "$examples_dir" > /dev/null

            # Allow for check_design_equiv to return non-zero return value
            set +euo pipefail
                check_design_equiv_kepler "$top_name" "$examples_dir" > "$examples_dir"/"$top_name".kepler.log 2>&1
                equivalence_ret=$?
            set -euo pipefail

            kepler_res=""
            case $equivalence_ret in
                0) kepler_res="PROVEN EQUAL";;
                1) if grep -q 'SEC partially proved equivalence' "$examples_dir"/"$top_name".kepler.log; then
                       kepler_res="PARTIALLY PROVEN (FAIL)"
                   else
                       kepler_res="ERROR (see kepler.log)"
                   fi;;
                2) kepler_res="INCONCLUSIVE";;
                3) kepler_res="DEFINITELY UNEQUAL";;
                *) kepler_res="ERROR (rc=$equivalence_ret)";;
            esac

            set +euo pipefail
                check_design_equiv_eqy "$top_name" "$examples_dir"
                equivalence_ret=$?
            set -euo pipefail

            # Exit codes from eqy_job.py; 1 is eqy's own error (bad config, crash).
            eqy_res=""
            case $equivalence_ret in
                0) eqy_res="PROVEN EQUAL";;
                2) eqy_res="DESIGN NOT EQUAL";;
                4) eqy_res="INCONCLUSIVE";;
                8) eqy_res="TIMEOUT";;
                1) eqy_res="ERROR (see eqy.log)";;
                *) eqy_res="ERROR (rc=$equivalence_ret)";;
            esac

            printf '%-25s %-25s %-25s\n' "$top_name" "$kepler_res" "$eqy_res"
        done
    done
done
