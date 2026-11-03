#!/usr/bin/env python3

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

"""
commonize_ports.py g8r_mapped_input.v

Commonizes the input/output ports inside g8r generated mapped verilog files,
to be in the same form as inside yosys generated ones. This allows kepler-formal
SEC checks to run.

It achieves this by postfixing generated module name with '_', and generating
module with original name, that has input wires declared as wire array (like yosys does),
and renames output port from output to out.
"""

import sys
import re

def parse_file(path):
    txt = open(path, 'r').read()
    m = re.search(r'module\s+(\w+)\s*\((.*?)\)\s*;', txt, re.DOTALL)
    if not m:
        raise SystemExit('module header not found')
    orig_name = m.group(1)
    ports_str = m.group(2)
    ports = [p.strip() for p in ports_str.split(',') if p.strip()]

    inputs = set()
    for decl in re.findall(r'\binput\s+([^;]+);', txt):
        inputs.update([n.strip() for n in decl.split(',')])
    outputs = set()
    for decl in re.findall(r'\boutput\s+([^;]+);', txt):
        outputs.update([n.strip() for n in decl.split(',')])

    return txt, orig_name, ports, inputs, outputs

def build_wrapper(txt, orig_name, ports, inputs, outputs):
    mod_name = orig_name.rstrip('_') + '_'
    wrapper_name = orig_name.rstrip('_') or orig_name + '_wrap'

    port_to_group = {}
    groups = {}
    for p in ports:
        m2 = re.match(r'^(.+?)_(\d+)$', p)
        if not m2:
            continue
        base, idx = m2.group(1), int(m2.group(2))
        dirc = 'input' if p in inputs else 'output' if p in outputs else None
        if not dirc:
            continue
        key = (dirc, base)
        groups.setdefault(key, set()).add(idx)
        port_to_group[p] = (key, idx)

    def bus_of(p):
        """(direction, bus name, bit index or None, group base) of port p."""
        if p in port_to_group:
            (dirc, base), idx = port_to_group[p]
        else:
            # A one-bit port without an _N suffix, e.g. a bare output_value.
            dirc = 'input' if p in inputs else 'output' if p in outputs else None
            base, idx = p, None
        bus_name = 'out' if dirc == 'output' and base == 'output_value' else base
        return dirc, bus_name, idx, base

    seen = {}
    bus_defs = []
    args = []
    for p in ports:
        dirc, bus_name, idx, base = bus_of(p)
        if not dirc:
            args.append(p)
            continue
        if (dirc, bus_name) not in seen:
            seen[(dirc, bus_name)] = True
            width = 1 if idx is None else max(groups[(dirc, base)]) + 1
            bus_defs.append((dirc, bus_name, width))
        args.append(bus_name if idx is None else f'{bus_name}[{idx}]')

    port_list = [bn for _, bn, _ in bus_defs]

    lines = []
    lines.append(f'module {wrapper_name}({", ".join(port_list)});')
    for dirc, bn, w in bus_defs:
        if w == 1:
            lines.append(f'  {dirc} {bn};')
        else:
            lines.append(f'  {dirc} [{w-1}:0] {bn};')
    lines.append(f'  {mod_name} dv8({", ".join(args)});')
    lines.append('endmodule')
    lines.append('')

    # rewrite the original module header to the guaranteed name
    modified_original = re.sub(
        r'^module\s+' + re.escape(orig_name) + r'\b',
        f'module {mod_name}',
        txt,
        count=1,
        flags=re.MULTILINE
    )
    lines.append(modified_original.strip())
    return '\n'.join(lines)

def main():
    if len(sys.argv) < 2:
        print('Usage: wrap_verilog.py input.v')
        sys.exit(1)
    path = sys.argv[1]
    txt, orig_name, ports, inputs, outputs = parse_file(path)
    out = build_wrapper(txt, orig_name, ports, inputs, outputs)
    out_path = path.rsplit('.', 1)[0] + '_wrapped.v'
    open(out_path, 'w').write(out)
    print(f'Wrote {out_path}')

if __name__ == '__main__':
    main()
