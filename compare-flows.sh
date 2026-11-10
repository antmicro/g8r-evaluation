#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

usage() {
    echo "Usage: ./compare-flows.sh"
    echo -e "\t[BUILD_DIR]\t(the build directory given to estimate-cell-area.sh)"
    echo -e "\t[TOP_MODULE]"
    echo
    echo "Runs four IR-to-cells flows on the files that estimate-cell-area.sh wrote:"
    echo "g8r, g8r + ABC opt + ABC map, g8r + ABC opt + g8r map and Yosys."
    echo "Prints one tab-separated row per flow: design, flow, area, cells, and median"
    echo "CPU time over TIMING_RUNS runs (default 5) after a warm-up."
}

case "${1:-}" in
    ""|-h|--help) usage; exit 0 ;;
esac
[[ $# -eq 2 ]] || { usage >&2; exit 2; }

build_dir=$(realpath "$1")
top=$2
out=$build_dir/$top
source common.sh
require "$out.opt.ir" "$build_dir/asap7.proto"
make_scl "$build_dir"
abc_dir=$build_dir/cmp-g8r-abc
abc_opt_dir=$build_dir/cmp-g8r-abc-g8r
mkdir -p "$abc_dir" "$abc_opt_dir"
write_abc_map_script "$abc_dir" "$top"
write_abc_opt_script "$abc_opt_dir"
# Written here, so the timed runs only run Yosys.
yosys_commands "$out.cmp-yosys.sv" "$out.cmp-yosys.v" "$top" > "$out.cmp-yosys.ys"

# The g8r front end: IR to an AIG, with the given ir2g8r flags.
g8r_aig() {
    local aig=$1
    shift
    "$driver" ir2g8r "$out.opt.ir" "${ir2g8r_flags[@]}" "$@" --aiger-out "$aig" > /dev/null
}

# The g8r mapper: an AIG to a netlist of ASAP7 cells.
g8r_map() {
    "$driver" aig-tech-map "$1" "${tech_map_flags[@]}" --liberty_proto "$build_dir/asap7.proto" \
        --module_name "$top" --netlist_out "$2" > "${2%.v}.log" 2>&1
}

# set -e is off inside timed, so each step runs only if the previous one succeeded.
flow_g8r() {
    g8r_aig "$out.cmp-g8r.aig" && g8r_map "$out.cmp-g8r.aig" "$out.cmp-g8r.v"
}

# ABC exits with 0 even when a command fails, so its old output is removed first
# and a failed run leaves nothing for the next step.
flow_g8r_abc() {
    rm -f "$abc_dir/$top.v"
    g8r_aig "$abc_dir/$top.aig" "${g8r_noopt[@]}" &&
        (cd "$abc_dir" && "$abc" -s -f abc.script > abc.log) &&
        cp "$abc_dir/$top.v" "$out.cmp-g8r-abc.v"
}

# ABC only optimizes and g8r maps, which skips ABC's library load and mapper.
flow_g8r_abc_g8r() {
    rm -f "$abc_opt_dir/out.aig"
    g8r_aig "$abc_opt_dir/in.aig" "${g8r_noopt[@]}" &&
        (cd "$abc_opt_dir" && "$abc" -s -f abc.script > abc.log) &&
        g8r_map "$abc_opt_dir/out.aig" "$out.cmp-g8r-abc-g8r.v"
}

flow_yosys() {
    "$codegen" --generator=combinational --delay_model=unit --use_system_verilog \
        --module_name="$top" "$out.opt.ir" > "$out.cmp-yosys.sv" &&
        "$yosys" -q -s "$out.cmp-yosys.ys"
}

# Each flow's time includes its area report, as in estimate-cell-area.sh. The
# old netlist goes first, so a failed flow cannot report its area.
run_flow() {
    rm -f "$out.cmp-$1.v" "$out.cmp-$1.area.json"
    "flow_${1//-/_}" &&
        "$driver" gv-area --netlist "$out.cmp-$1.v" --liberty_proto "$build_dir/asap7.proto" --module_name "$top" \
            --json_out "$out.cmp-$1.area.json" > /dev/null
}

flows=(g8r g8r-abc g8r-abc-g8r yosys)
declare -A cpu
# Run the flows in turn in each iteration, so load affects them alike.
for ((run = 0; run <= ${TIMING_RUNS:-5}; run++)); do
    for flow in "${flows[@]}"; do
        t=$(timed run_flow "$flow") || { echo "The $flow flow failed" >&2; exit 1; }
        read -r _ cpu_ms <<< "$t"
        ((run > 0)) || continue # run 0 is a warm-up
        cpu[$flow]+=" $cpu_ms"
    done
done

printf 'design\tflow\tarea_um2\tcells\tcpu_ms\n'
for flow in "${flows[@]}"; do
    read -r area cells < <(python3 -c 'import json, sys; d = json.load(open(sys.argv[1])); print(d["area"], d["cell_count"])' \
        "$out.cmp-$flow.area.json")
    printf '%s\t%s\t%.2f\t%s\t%s\n' "$top" "$flow" "$area" "$cells" "$(median ${cpu[$flow]})"
done
