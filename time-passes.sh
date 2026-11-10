#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
# A failed step inside $( ) stops the script too.
shopt -s inherit_errexit

# A pass lasts from its marker line in the timestamped tool output to the next:
# g8r log lines, an echo before each ABC command, and log lines between the Yosys
# commands. A missing marker stops the script, so a reworded log line after a
# tool update shows here.

usage() {
    echo "Usage: ./time-passes.sh"
    echo -e "\t[BUILD_DIR]\t(the build directory given to estimate-cell-area.sh)"
    echo -e "\t[TOP_MODULE]"
    echo -e "\t[XLSYNTH_DRIVER_PATH]\t(default: tools/xlsynth-analysis/bin/xlsynth-driver)"
    echo -e "\t[ORFS_PATH]\t(default: tools/orfs)"
    echo
    echo "Times every pass of the four flows of compare-flows.sh on the files that"
    echo "estimate-cell-area.sh wrote, TIMING_RUNS times (default 5) after a warm-up run,"
    echo "and prints one tab-separated row per pass: run, flow, stage, pass, ms."
    echo "The default driver is the one setup.sh builds with patches/xlsynth-phase-timing.patch."
    echo "The logging adds a little time, so the flow totals come from compare-flows.sh."
}

case "${1:-}" in
    ""|-h|--help) usage; exit 0 ;;
esac
[[ $# -ge 2 ]] && [[ $# -le 4 ]] || { usage >&2; exit 2; }

build_dir=$(realpath "$1")
top=$2
out=$build_dir/$top
source common.sh
# The driver with the phase log lines, which setup.sh builds, unless one is given,
# and Yosys and ABC from ORFS_PATH, if given.
driver=$(realpath -m "${3:-$repo/tools/xlsynth-analysis/bin/xlsynth-driver}")
[[ -x $driver ]] || { echo "Cannot find $driver; run ./setup.sh" >&2; exit 1; }
if [[ -n ${4:-} ]]; then
    yosys=$(realpath "$4")/tools/install/yosys/bin/yosys
    abc=$yosys-abc
fi
require "$out.opt.ir" "$build_dir/asap7.proto"
make_scl "$build_dir"

# Prefixes each line with the seconds since $T0, taken before the process starts.
# Perl, since it starts in a few ms and reads a microsecond clock for each line.
stamp() {
    perl -MTime::HiRes=time -ne '
        BEGIN { $t0 = $ENV{T0}; $| = 1; print "[0.000000] <start>\n" }
        printf "[%.6f] %s", time - $t0, $_;
        END { printf "[%.6f] <eof>\n", time - $t0 }'
}

# Arguments are "stage|pass|marker"; prints "stage<TAB>pass<TAB>ms" per pass.
phases() {
    python3 "$repo/scripts/phases.py" "$@"
}

# Runs "$@" with its stdout and stderr stamped; with --log, only stderr, where
# the g8r tools log.
stamped() {
    local t0 stdout=/dev/stdout
    [[ $1 != --log ]] || { stdout=/dev/null; shift; }
    t0=$(date +%s.%N)
    "$@" 2>&1 > "$stdout" | T0=$t0 stamp
}

# Prints "stage|pass|marker" for each command of the ABC script on stdin. ABC
# prints "+ <command>" before each command; the pass is the command and its flags.
abc_markers() {
    local cmd words word pass stage
    while read -r cmd; do
        read -ra words <<< "${cmd%;}"
        pass=${words[0]}
        for word in "${words[@]:1}"; do
            [[ $word != -* ]] || pass+=" $word"
        done
        case $pass in
            read_scl) stage="library load" ;;
            "&nf"*) stage=mapping ;;
            read_*|write_*|"&r") stage="startup + I/O" ;;
            *) stage="AIG optimization" ;;
        esac
        echo "$stage|ABC $pass|+ $pass"
    done
}

# Markers of the g8r passes, from the log lines of the patched driver.
front_end=(
    "front end|PIR parse|g8r-phase: pir-parse"
    "front end|array alias analysis|g8r-phase: array-alias-analysis"
    "front end|range analysis|g8r-phase: libxls-range-analysis"
    "front end|prep_for_gatify|g8r-phase: prep-for-gatify"
    "front end|gatify|g8r-phase: gatify-lower"
    "front end|post-gatify|IR top:"
)
# With g8r_noopt, only these run.
no_optimization=(
    "AIG optimization|load cut DB|g8r-phase: cut-db-load"
    "AIG optimization|dce|g8r-phase: dce"
)
g8r_optimization=(
    "${no_optimization[@]}"
    "AIG optimization|fraig|fraig is enabled"
    "AIG optimization|reassociation|pre-cut-db ordinary reassociation enabled"
    "AIG optimization|cut-db setup|cut-db rewrite enabled"
    "AIG optimization|cut-db small cuts, delay|cut-db depth round"
    "AIG optimization|cut-db large cones, delay|cut-db large-cone depth round"
    "AIG optimization|cut-db small cuts, area|cut-db area round"
    "AIG optimization|cut-db large cones, area|cut-db large-cone round"
    "AIG optimization|reuse reassociation|post-cut-db guarded reuse reassociation enabled"
)
tech_map=(
    "startup + I/O|load AIGER|g8r-phase: techmap-load-aiger"
    "library load|load Liberty proto|g8r-phase: techmap-load-liberty"
    "mapping|cell index|g8r-phase: techmap-cell-index"
    "mapping|cover|g8r-phase: techmap-cover"
    "startup + I/O|write netlist|g8r-phase: techmap-emit"
)

# The timed tool runs of the flows; each prints the time of its passes.

# ir2g8r to AIG, with its own optimization (opt) or without it (noopt), as the
# ABC flows run it.
time_ir2g8r() {
    local aig=$1 flags=() optimization=("${g8r_optimization[@]}")
    [[ $2 == opt ]] || { flags=("${g8r_noopt[@]}"); optimization=("${no_optimization[@]}"); }
    stamped --log env RUST_LOG=info "$driver" ir2g8r "$out.opt.ir" "${ir2g8r_flags[@]}" \
        "${flags[@]}" --aiger-out "$aig" | phases "startup + I/O|ir2g8r start|<start>" "${front_end[@]}" \
        "${optimization[@]}" "startup + I/O|stats + AIGER write|gate fn signature" "|end|<eof>"
}

# aig-tech-map from AIG to NETLIST.
time_tech_map() {
    stamped --log env RUST_LOG=info "$driver" aig-tech-map "$1" "${tech_map_flags[@]}" \
        --liberty_proto "$build_dir/asap7.proto" --module_name "$top" --netlist_out "$2" |
        phases "startup + I/O|aig-tech-map start|<start>" "${tech_map[@]}" "|end|<eof>"
}

time_gv_area() {
    stamped --log "$driver" gv-area --netlist "$1" --liberty_proto "$build_dir/asap7.proto" \
        --module_name "$top" | phases "area report|gv-area|<start>" "|end|<eof>"
}

# yosys-abc on DIR/abc.script, with an echo before each command as its marker.
# ABC exits with 0 even when a command fails, so it fails here when OUTPUT is
# missing, and the old OUTPUT goes first.
time_abc() {
    local dir=$1 output=$1/$2 markers
    rm -f "$output"
    sed 's/.*/echo + &\n&/' "$dir/abc.script" > "$dir/passes.script"
    mapfile -t markers < <(abc_markers < "$dir/abc.script")
    (cd "$dir" && stamped stdbuf -oL "$abc" -s -f passes.script) |
        phases "startup + I/O|ABC start|<start>" "${markers[@]}" "|end|<eof>"
    [[ -f $output ]] || { echo "ABC wrote no $2 for $top" >&2; exit 1; }
}

# The flows as in compare-flows.sh, each ABC flow in a directory of its own.
abc_dir=$build_dir/passes-g8r-abc
abc_opt_dir=$build_dir/passes-g8r-abc-g8r
mkdir -p "$abc_dir" "$abc_opt_dir"
write_abc_map_script "$abc_dir" "$top"
write_abc_opt_script "$abc_opt_dir"

g8r_flow() {
    time_ir2g8r "$out.passes.aag" opt
    time_tech_map "$out.passes.aag" "$out.passes-g8r.v"
    time_gv_area "$out.passes-g8r.v"
}

g8r_abc_flow() {
    time_ir2g8r "$abc_dir/$top.aig" noopt
    time_abc "$abc_dir" "$top.v"
    time_gv_area "$abc_dir/$top.v"
}

g8r_abc_g8r_flow() {
    time_ir2g8r "$abc_opt_dir/in.aig" noopt
    time_abc "$abc_opt_dir" out.aig
    time_tech_map "$abc_opt_dir/out.aig" "$out.passes-g8r-abc-g8r.v"
    time_gv_area "$out.passes-g8r-abc-g8r.v"
}

# The Yosys passes, by the command of yosys-flow.ys that starts them; a command
# not listed here counts in the pass before it.
declare -A yosys_markers=(
    [read_verilog]="front end|Yosys synth -noabc"
    [abc]="startup + I/O|Yosys abc setup"
    [opt]="mapping|Yosys opt"
    [write_verilog]="startup + I/O|write netlist"
)

# Writes yosys-flow.ys to FILE with a "log Y@<n>:" marker before each command
# that starts a pass, and prints the "stage|pass|marker" of each pass.
yosys_script() {
    local file=$1 commands cmd name i=0 markers=()
    commands=$(yosys_commands "$out.passes.sv" "$out.passes-yosys.v" "$top")
    while read -r cmd; do
        name=${cmd%% *}
        if [[ -v yosys_markers[$name] ]]; then
            echo "log Y@$((++i)):"
            markers+=("${yosys_markers[$name]}|^Y@$i:")
        fi
        if [[ $name == abc ]]; then
            # Yosys logs ABC's output only after ABC exits, so -nocleanup keeps
            # its input and script for time_abc_rerun.
            cmd+=" -nocleanup -showtmp"
            markers+=("|abc|Extracting gate netlist" "startup + I/O|Yosys BLIF import|Executed ABC.")
        fi
        echo "$cmd"
    done <<< "$commands" > "$file"
    echo "log Y@end:" >> "$file"
    printf '%s\n' "${markers[@]}" "|end|^Y@end:"
}

# Yosys on the flow script, with markers between its passes. Prints the time of
# each command, and of the process start and exit as the time outside them.
time_yosys() {
    local markers start end passes
    markers=$(yosys_script "$out.passes-yosys.ys")
    mapfile -t markers <<< "$markers"
    start=$(date +%s%N)
    (cd "$build_dir" && "$yosys" -t -l "$out.passes-yosys.log" -s "$out.passes-yosys.ys" > /dev/null)
    end=$(date +%s%N)
    passes=$(phases "${markers[@]}" < "$out.passes-yosys.log")
    awk -F '\t' -v wall_ns=$((end - start)) '
        { passes_ms += $3 }
        END { printf "startup + I/O\tYosys start + exit\t%.3f\n", wall_ns / 1e6 - passes_ms }' <<< "$passes"
    echo "$passes"
}

# Reruns the ABC of the Yosys run on the input and script it kept, and prints
# the time of each ABC command. Stops if the rerun gives another netlist.
time_abc_rerun() {
    local dir markers abc_passes
    # Yosys logs the directory it runs ABC in.
    dir=$(sed -n 's/.*Extracting gate netlist of module .* to `\(.*\)\/input.blif.*/\1/p' "$out.passes-yosys.log")
    [[ -n $dir ]] || { echo "Yosys ran no ABC for $top" >&2; exit 1; }
    dir=$build_dir/$dir
    [[ -f $dir/output.blif ]] || { echo "ABC wrote no netlist for $top" >&2; rm -r "$dir"; exit 1; }
    # Yosys already puts an echo before each command, as marker.
    sed "s|output.blif|rerun.blif|" "$dir/abc.script" > "$dir/rerun.script"
    mapfile -t markers < <(grep -v '^echo' "$dir/abc.script" | abc_markers)
    abc_passes=$(cd "$build_dir" && stamped stdbuf -oL "$abc" -s -f "$dir/rerun.script" |
        phases "startup + I/O|ABC start|<start>" "${markers[@]}" "|end|<eof>")
    # The first line differs: it holds the time ABC wrote the file.
    cmp -s <(sed 1d "$dir/output.blif") <(sed 1d "$dir/rerun.blif") ||
        { echo "The ABC rerun differs from the ABC run inside Yosys" >&2; rm -r "$dir"; exit 1; }
    rm -r "$dir"
    echo "$abc_passes"
}

# Replaces the abc pass in YOSYS_PASSES with the ABC commands in ABC_PASSES of the
# rerun, scaled to the time of that pass, which includes the BLIF export.
split_abc_window() {
    awk -F '\t' '
        NR == FNR { rerun[++n] = $0; rerun_ms += $3; next }
        $2 == "abc" {
            for (i = 1; i <= n; i++) {
                split(rerun[i], pass, "\t")
                printf "%s\t%s\t%.3f\n", pass[1], pass[2], pass[3] * $3 / rerun_ms
            }
            next
        }
        { print }' <(echo "$2") <(echo "$1")
}

yosys_flow() {
    local yosys_passes abc_passes
    stamped "$codegen" --generator=combinational --delay_model=unit --use_system_verilog --module_name="$top" \
        --output_verilog_path="$out.passes.sv" "$out.opt.ir" | phases "startup + I/O|codegen|<start>" "|end|<eof>"
    yosys_passes=$(time_yosys)
    abc_passes=$(time_abc_rerun)
    split_abc_window "$yosys_passes" "$abc_passes"
    time_gv_area "$out.passes-yosys.v"
}

flows() {
    g8r_flow | sed "s/^/$1\tg8r\t/"
    g8r_abc_flow | sed "s/^/$1\tg8r-abc\t/"
    g8r_abc_g8r_flow | sed "s/^/$1\tg8r-abc-g8r\t/"
    yosys_flow | sed "s/^/$1\tyosys\t/"
}

printf 'run\tflow\tstage\tpass\tms\n'
flows 0 > /dev/null # a warm-up, as in estimate-cell-area.sh
for ((run = 1; run <= ${TIMING_RUNS:-5}; run++)); do
    flows "$run"
done
