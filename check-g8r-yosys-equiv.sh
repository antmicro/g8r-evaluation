#!/bin/bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

# This script does check if g8r and yosys generated mapped verilog
# files represent logically equal designs for each generated example
# inside build_dir.
#
# For every example it first runs the SystemVerilog behavioral testbench for
# that single example (sim_tbs/): the yosys-mapped and g8r-mapped netlists
# are simulated with Verilator and checked against the clean XLS reference.
# This is the first check and it gates the rest: if the testbench fails, the (expensive)
# kepler-formal and eqy equivalence passes are NOT run for that example.
#
# When the testbench passes (or no testbench exists for the design) it achieves
# formal logic equality using commonize_ports.py to make input/output port
# names the same, then runs kepler-formal and yosys eqy to verify logic
# equality.

set -euo pipefail

# Without ORFS (SKIP_ORFS) there is no ORFS area, so leave out its column.
skip_eqy=0
if [[ ${SKIP_EQY:-0} != 0 ]]; then
    skip_eqy=1
fi

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

# Simulate sim_tbs/$1.sv with the design file $2 and print its outputs.
function sim_tb() {
    top=$1
    design=$2
    work=$(mktemp -d)
    ret=0
    ./tools/verilator/bin/verilator --cc --exe --build -Wno-fatal -Wno-lint --top-module tb -Mdir "$work" \
        +incdir+"./sim_tbs/lib" +define+SIM_TOP="$top" \
        "./sim_tbs/asap7_cells.v" "$design" "./sim_tbs/$top.sv" \
        "./sim_tbs/lib/main.cpp" > "$work/build.log" 2>&1 \
        && "$work/Vtb" > "$work/sim.log" 2>&1 \
        && grep '^vec' "$work/sim.log" \
        || { cat "$work/build.log" "$work/sim.log" >&2 2>/dev/null; ret=1; }
    rm -rf "$work"
    return $ret
}

function check_design_sv_bench() {
    top=$1
    local build_dir=$2
    [[ -f ./sim_tbs/$top.sv ]] || return 2

    # The XLS reference, yosys and g8r designs all declare module $top, so each
    # one is simulated on its own and the outputs are compared afterwards.
    ref=$(sim_tb "$top" "$build_dir/$top.sv") || return 1
    for netlist in yosys-mapped.v g8r-mapped_wrapped.v; do
        out=$(sim_tb "$top" "$build_dir/$top.$netlist") || return 1
        if [[ $out != "$ref" ]]; then
            echo "$top.$netlist differs from the XLS reference:" >&2
            diff <(echo "$ref") <(echo "$out") >&2
            return 1
        fi
    done
    return 0
}

printf '%-25s %-25s %-25s %-25s\n' function sv_bench kepler yosys_eqy
for logs_dir in "$build_dir"/*; do
    if [ ! -d "$logs_dir" ]; then
        continue
    fi;

    for examples_dir in "$logs_dir"/*; do
        for g8r_netlist in "$examples_dir"/*g8r-mapped.v; do
            top_name=$(basename "$g8r_netlist" | cut -d'.' -f1)

            commonize_designs "$top_name" "$examples_dir" > /dev/null

            # Allow for check_design_equiv to return non-zero return value
            # 1st check: the SystemVerilog behavioral testbench
            set +euo pipefail
                check_design_sv_bench "$top_name" "$examples_dir"
                sv_ret=$?
            set -euo pipefail

            sv_res=""
            case $sv_ret in
                0) sv_res="PASS";;
                1) sv_res="FAIL";;
                2) sv_res="NO TESTBENCH (SKIPPED)";;
                *) sv_res="UNKNOWN RETURN VALUE";;
            esac

            if [[ $sv_ret -eq 1 ]]; then
                printf '%-25s %-25s %-25s %-25s\n' \
                    "$top_name" "$sv_res" "SKIPPED (bench failed)" "SKIPPED (bench failed)"
                continue
            fi

            # 2nd check: kepler-formal equivalence.
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

            if (( skip_eqy )); then
                eqy_res="SKIPPED"
            else
                # 3rd check: yosys eqy equivalence.
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
            fi

            printf '%-25s %-25s %-25s %-25s\n' "$top_name" "$sv_res" "$kepler_res" "$eqy_res"
        done
    done
done
