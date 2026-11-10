# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

# Tools, flow settings and helpers shared by the scripts, which source this file
# from the repository root.

# Paths below are relative to the repository, not to the current directory.
repo=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
driver=$repo/tools/xlsynth/bin/xlsynth-driver
yosys=$repo/tools/orfs/tools/install/yosys/bin/yosys
abc=$yosys-abc
codegen=$repo/tools/xls/codegen_main-ubuntu2004
libs=("$(realpath -m "$repo/lib")"/*.lib)
export LC_ALL=C

# The flows: the g8r options and the ABC scripts are defined here, the Yosys
# flow in yosys-flow.ys.
# ir2g8r and aig-tech-map options of every g8r flow.
ir2g8r_flags=(--enable-formal-array-alias-analysis false)
tech_map_flags=(--strategy area)
# ir2g8r flags of the flows that leave the optimization to ABC.
g8r_noopt=(--fraig false --reassociation false --cut-db-rewrite false)
# The script of Yosys's abc pass with -liberty (ABC_COMMAND_LIB in passes/techmap/abc.cc).
abc_map_script='strash; &get -n; &fraig -x; &put; scorr; dc2; dretime; strash; &get -n; &dch -f; &nf; &put'
# The g8r + ABC opt + g8r map flow: ABC only optimizes, without choices, and g8r maps.
abc_opt_script='strash; &get -n; &fraig -x; &put; dc2'

# The commands of yosys-flow.ys, one per line, from SystemVerilog SV to the
# netlist V of module TOP.
yosys_commands() {
    # Only these names, so any other $ in the script stays as it is.
    # shellcheck disable=SC2016
    SV=$1 V=$2 TOP=$3 LIBERTY="${libs[*]/#/-liberty }" \
        envsubst '$SV $V $TOP $LIBERTY' < "$repo/yosys-flow.ys" | grep -v '^\(#\|$\)'
}

# Exits unless all the files exist.
require() {
    local f
    for f in "$@"; do
        [[ -f $f ]] || { echo "Cannot find $f; run ./estimate-cell-area.sh first" >&2; exit 1; }
    done
}

# ABC reads the libraries in its binary format; Yosys's abc pass caches the same.
make_scl() {
    [[ -f $1/asap7.scl ]] ||
        "$abc" -s -q "read_lib ${libs[0]};$(printf ' read_lib -m %s;' "${libs[@]:1}") write_scl $1/asap7.scl" > /dev/null
}

# Writes DIR/abc.script, one command per line. ABC names the module after the
# AIGER file, so the g8r + ABC opt + ABC map flow reads TOP.aig in a directory
# of its own.
write_abc_map_script() {
    local dir=$1 top=$2 cmds
    IFS=';' read -ra cmds <<< "$abc_map_script"
    printf '%s\n' "read_scl ../asap7.scl" "&r $top.aig" "&put" "${cmds[@]# }" "write_verilog $top.v" > "$dir/abc.script"
}

# Writes DIR/abc.script of the g8r + ABC opt + g8r map flow, in.aig to out.aig.
# write_aiger, since aig-tech-map rejects the binary comments that &w adds.
write_abc_opt_script() {
    local cmds
    IFS=';' read -ra cmds <<< "$abc_opt_script"
    printf '%s\n' "&r in.aig" "&put" "${cmds[@]# }" "write_aiger -s out.aig" > "$1/abc.script"
}

TIMEFORMAT='%3R %3U %3S'
# Runs a command; prints its wall and CPU (user + system) time in ms.
timed() {
    local t
    t=$( { time "$@" 2>&4; } 4>&2 2>&1 ) || return
    set -- $t
    echo "$((10#${1/[.,]/})) $((10#${2/[.,]/} + 10#${3/[.,]/}))"
}

median() {
    printf '%s\n' "$@" | sort -n | sed -n "$((($# + 1) / 2))p"
}
