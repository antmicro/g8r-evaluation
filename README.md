# g8r Area estimation analysis

Copyright (c) 2026 [Antmicro](https://www.antmicro.com)

Antmicro's demonstration of area estimation workflows with [xlsynth-crate](https://github.com/xlsynth/xlsynth-crate), [yosys](https://github.com/yosyshq/yosys) and [OpenROAD-flow-scripts](https://github.com/the-openroad-project/openroad-flow-scripts)

## Setup

Install the prerequisites and run the setup script:

```shell
sudo apt install build-essential curl protobuf-compiler rustup yosys
./setup.sh
```

The OpenROAD build also needs `bazelisk` on the `PATH`, which is not packaged
for Debian; install it from the
[Bazelisk releases](https://github.com/bazelbuild/bazelisk/releases) or via
`curl -L https://github.com -o bazelisk && chmod +x bazelisk`

`setup.sh` downloads the XLS release assets (codegen and stdlib) into
`tools/xls`, builds `xlsynth-driver` into `tools/xlsynth`, and clones and
builds OpenROAD-flow-scripts into `tools/orfs`. The first run therefore
downloads and builds several large projects. Re-running the script skips
completed steps.

## Usage

All scripts are run from the repository root. Each script takes a DSLX file and
the name of a top function:

`show-raw-g8r.sh` - gives quick technology-agnostic overview of the design complexity,
reports the input/output count, AND node count and logic depth of the design
and writes the intermediate IR, g8r and AIGER files to
`build/`.

```shell
./show-raw-g8r.sh examples/arithmetic/add.x arith_add8
```

`estimate-cell-area.sh` - estimates area of physical design and compares the results
from `g8r`, `Yosys` and `OpenROAD`. Also includes `ir2g8r`, `g8r` and `Yosys` area 
estimation execution time. g8r time includes also the time spent inside ir2g8r.
Intermediate files are written to `build/TOP.*`. Optional positional arguments
override the build directory, the xlsynth-driver path and the ORFS path.

```shell
./estimate-cell-area.sh examples/arithmetic/add.x arith_add8
```

`compare-all.sh` runs the area estimate for every `pub fn` in every design of a
directory tree and prints the results as one table per design file. It also
saves each table to a log file so the plots below can be regenerated later:

```shell
./compare-all.sh examples ./lib ./examples_logs
```

The table columns are the function name, the three area estimates in um^2, the
g8r-to-Yosys ratio, and the ir2g8r, g8r and yosys stage timings in ms. The positional
arguments are the design directory (default `examples`), the Liberty library
directory (default `./lib`), the logs directory (default `./comp_logs`) and the
driver path.

## Examples

Designs are grouped by category in `examples/`: arithmetic, logic, XOR-heavy
logic, multiplexers (`sel`), shifts, control, floating point, and larger
designs such as CRC, Adler, dot product, SHA-256, zstd and others.
`examples_mutation/` contains mutation studies: `chained_mut` applies
successive mutations to one baseline function, and `fir` varies the
filter function, length and accumulator width.

## Estimating area

The gate count reported by g8r is useful for comparing versions of a design,
but it does not correspond to physical area, due to only reporting the gate count. 
Because of that physical estimate requires additional tools mapping the design to a
standard-cell library. `estimate-cell-area.sh` uses the bundled ASAP7 library in `lib/`
(see `lib/README.md`) and computes the area in three ways:

1. [`aig-tech-map`](https://github.com/xlsynth/xlsynth-crate/blob/main/xlsynth-driver/src/aig_tech_map.rs) maps the g8r gate graph to ASAP7 cells and `gv-area` sums
   the cell areas. Both of those tools are subprograms of [xlsynth-driver](https://crates.io/crates/xlsynth-driver) 
2. The same IR is emitted as SystemVerilog and synthesized with [Yosys](https://github.com/YosysHQ/yosys) against
   the full library.
3. The SystemVerilog is run through the [OpenROAD-flow-scripts](https://github.com/the-openroad-project/openroad-flow-scripts) synthesis,
   floorplan, placement, CTS and routing stages, giving a post-layout estimate.

```text
$ ./estimate-cell-area.sh examples/arithmetic/add.x arith_add8
...
Timing, area and time comparison (ASAP7):
  ir2g8r:         18.00 ms
  g8r:            75.00 ms
  Yosys:          178.00 ms
  g8r:            3.02 um^2
  Yosys:          3.12 um^2
  ORFS:           10.00 um^2
```

Across the bundled examples the g8r mapping is typically within a factor of two
of Yosys. The ORFS result includes placement and wiring overhead and varies
more between designs, this can be observed inside `orfs.log` files from the design,
initially after synthesis result the same to `Yosys` one, and after place and
route it is significantly higher.

## Plots and report

`scripts/` contains three Python scripts that turn the logs written by
`compare-all.sh` into bar charts, ranking charts against a baseline function,
and a browsable HTML gallery. See `scripts/README.md` for their usage.
Install the dependencies with:

```shell
python3 -m pip install matplotlib numpy pandas
```

`run-flow.sh` runs everything end to end: `setup.sh`, `compare-all.sh` over
`examples/` and `examples_mutation/`, the area and timing plots, the mutation
ranking charts, and finally the HTML report in `report/`:

```shell
./run-flow.sh
```

Open `report/index.html` in a browser; the ranking subsite is linked from it.
