# Getting started with g8r

g8r is the gate-level backend of the [xlsynth](https://github.com/xlsynth)
toolchain. It lowers an XLS IR design into an And-Inverter Graph and optimizes
the graph. The resulting gate count and logic depth give a quick estimate of
design size and delay without a full synthesis flow.

This repository provides scripts for running g8r on DSLX designs and for
estimating their cell area.

## Setup

The setup is supported on Debian and Ubuntu for x86-64. Install the
prerequisites and run the setup script:

```shell
sudo apt install build-essential curl protobuf-compiler rustup yosys
./setup.sh
```

## Usage

All scripts are run from the repository root. Each script takes a DSLX file and
the name of the top function:

```shell
./show-raw-g8r.sh example.x arith_add8
./estimate-cell-area.sh example.x arith_add8
```

`show-raw-g8r.sh` reports the gate count and logic depth of the design.
`estimate-cell-area.sh` reports its cell area. `compare-all.sh` runs the area
estimate for every function in a file and prints the results as a table. By
default it uses `example.x`:

```shell
./compare-all.sh
```

The file `example.x` contains 35 designs covering arithmetic, XOR logic,
multiplexers, control logic and floating point.

## Estimating area

The gate count reported by g8r is useful for comparing versions of a design,
but it does not correspond to physical area. A physical estimate requires
mapping the design to a standard-cell library. `estimate-cell-area.sh` uses the
ASAP7 library in `lib/` and computes the area in two ways. The first maps the
g8r gate graph to NAND2 and inverter cells. The second generates SystemVerilog
from the same design and synthesizes it with Yosys.

```text
$ ./estimate-cell-area.sh example.x arith_add8
...
Area comparison (ASAP7):
  g8r:   11.55 um^2
  Yosys: 3.11 um^2
```

The Yosys result is the more realistic estimate because Yosys can use the full
cell library. The g8r mapping typically produces an area two to eight times
larger. Neither estimate accounts for placement or wiring.
