# Behavioral simulation testbenches (sim_tbs)

SystemVerilog testbenches, run with [Verilator](https://verilator.org) by
`check-g8r-yosys-equiv.sh` before the formal checks. Each one applies a few
hardcoded input vectors to a design and prints the output for every vector.
The script runs it three times, once per version of the design, and the check
passes when the Yosys-mapped and g8r-mapped printouts match the XLS
reference's exactly.

| Run   | Design file (from the build directory)                                              |
|-------|-------------------------------------------------------------------------------------|
| xls   | `<top>.sv` (clean XLS reference)                                                    |
| yosys | `<top>.yosys-mapped.v`                                                              |
| g8r   | `<top>.g8r-mapped_wrapped.v` (bus ports, written by `scripts/commonize_ports.py`) |

The testbenches hold no design code; the design file is passed straight to
Verilator. All three files declare the same module, `<top>`, which is why each
one is simulated on its own.

## Files

* `sim_tbs/<top>.sv` — per design: the inputs, `out`, `SIM_IN` (the inputs as
  one vector) and `VECS` (the vectors to apply to `SIM_IN`).
* `sim_tbs/lib/tb.svh` — shared testbench body: instantiates `` `SIM_TOP ``,
  applies one vector per clock and prints the output.
* `sim_tbs/lib/main.cpp` — Verilator main that toggles the clock until `$finish`.
* `sim_tbs/asap7_cells.v` — behavioral models of the ASAP7 cells, generated from
  the Liberty `function` attributes by `sim_tests/gen_asap7_cells.py`.

## Running one testbench

```shell
dir=build/examples/arithmetic/add   # holds the build files
top=arith_add8
design=$dir/$top.yosys-mapped.v     # or $top.sv, $top.g8r-mapped_wrapped.v
verilator --cc --exe --build -Wno-fatal -Wno-lint --top-module tb \
    +incdir+sim_tbs/lib +define+SIM_TOP=$top \
    sim_tbs/asap7_cells.v $design sim_tbs/$top.sv sim_tbs/lib/main.cpp
./obj_dir/Vtb
```

The g8r wrapper comes from `python3 scripts/commonize_ports.py $dir/$top.g8r-mapped.v`.

## Scope

The narrowest and the widest width of each simple family: `arith_*`,
`logic_*` and `xor_*`. Other designs show `NO TESTBENCH (SKIPPED)` and go
straight to the formal checks.

## Requirements

`verilator` and a C++ compiler. The testbenches use no delays, `--binary` or
other newer features; they're tested with the Ubuntu packages (4.038 on
22.04, 5.020 on 24.04) and with 5.055.
