# g8r Area estimation analysis

Copyright (c) 2026 [Antmicro](https://www.antmicro.com)

Antmicro's demonstration of area estimation workflows with [xlsynth-crate](https://github.com/xlsynth/xlsynth-crate), [yosys](https://github.com/yosyshq/yosys) and [OpenROAD-flow-scripts](https://github.com/the-openroad-project/openroad-flow-scripts)

The results for the bundled examples are published at
[antmicro.github.io/g8r-evaluation](https://antmicro.github.io/g8r-evaluation/).

## Setup

Install the prerequisites:

```shell
sudo apt install build-essential curl git protobuf-compiler rustup
```

`setup.sh` also needs `bazelisk` and `uv` on the `PATH`, which are not packaged
for Debian. Both install into `~/.local/bin`, which must be on the `PATH`.

`bazelisk` builds OpenROAD and runs the Bazel version that OpenROAD pins in
`.bazelversion`. Install it from the
[Bazelisk releases](https://github.com/bazelbuild/bazelisk/releases), e.g. on
Linux x86-64:

```shell
curl -fL --create-dirs -o ~/.local/bin/bazelisk \
    https://github.com/bazelbuild/bazelisk/releases/download/v1.29.0/bazelisk-linux-amd64
chmod +x ~/.local/bin/bazelisk
```

`uv` installs Python and the packages for the plotting scripts. Install it with
the [standalone installer](https://docs.astral.sh/uv/getting-started/installation/):

```shell
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Then run the setup script:

```shell
./setup.sh
```

`setup.sh` downloads the XLS release assets (codegen and stdlib) into
`tools/xls`, builds `xlsynth-driver` into `tools/xlsynth`, clones and builds
OpenROAD-flow-scripts into `tools/orfs`, and copies the ASAP7 RVT TT Liberty
files that ORFS ships into `lib/`. The first run therefore
downloads and builds several large projects. Re-running the script skips
completed downloads and the xlsynth-driver build; `build_openroad.sh` runs every
time, but its builds are incremental.

All tool versions are pinned in the block at the top of `setup.sh`; edit them
there and re-run the script, which prints the installed versions when it
finishes. The ORFS commit also pins OpenROAD and Yosys, and the standalone
Yosys run uses the Yosys built by ORFS.

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
Each time is the median of `TIMING_RUNS` runs (default 5) after a warm-up run.
Each time line also shows the median CPU time (user + system) and the range of
the wall time over the runs; CPU time is less affected by other load on the machine.
Set `SKIP_ORFS=1` to skip the slow ORFS place-and-route run; the ORFS area is
then reported as 0, and `compare-all.sh` leaves out the `orfs_um2` column.
Intermediate files are written to `build/TOP.*`. Optional positional arguments
override the build directory, the xlsynth-driver path and the ORFS path.

```shell
./estimate-cell-area.sh examples/arithmetic/add.x arith_add8
```

`compare-all.sh` runs the area estimate for every `pub fn` in every design of a
directory tree and prints the results as one table per design file. It also
saves each table to a log file so the plots below can be regenerated later:

```shell
./compare-all.sh examples ./examples_logs
```

The positional arguments are the design directory (default `examples`) and the
logs directory (default `./comp_logs`). To run only a few representative
examples, set `EXAMPLES_FILTER` to a comma-separated list of `pub fn` names;
functions not in the list are skipped, and unknown names are reported and
ignored:

```shell
EXAMPLES_FILTER=dot8,sha256,zstd ./compare-all.sh
```

Additionally there is `SKIP_MUTATIONS`, which if defined skips every example
in `_mutations` directory and `RUN_ONLY_MUTATIONS`, which makes `compare-all.sh`
run only examples in `_mutations` directory.

The table columns are the function name, the three area estimates in um^2, the
g8r-to-Yosys ratio, and the ir2g8r, g8r and yosys stage CPU times in ms. The positional
arguments are the design directory (default `examples`) and the logs directory
(default `./comp_logs`). A function whose estimate fails is reported as `FAILED`
with the path to its error log, and the sweep continues.

## Examples

Designs are grouped by category in `examples/`: arithmetic, logic, XOR-heavy
logic, multiplexers (`sel`), shifts, control, floating point, and larger
designs such as CRC, Adler, dot product, SHA-256, zstd and others.
`examples/_mutations/` contains mutation studies: `chained` applies
successive mutations to one baseline function, and `fir` varies the
filter function, length and accumulator width.

## Estimating area

The gate count reported by g8r is useful for comparing versions of a design,
but it does not correspond to physical area, due to only reporting the gate count. 
Because of that physical estimate requires additional tools mapping the design to a
standard-cell library. `estimate-cell-area.sh` uses the ASAP7 RVT TT Liberty
files that `setup.sh` copies from ORFS into `lib/` and computes the area in three ways:

1. [`aig-tech-map`](https://github.com/xlsynth/xlsynth-crate/blob/main/xlsynth-driver/src/aig_tech_map.rs) maps the g8r gate graph to ASAP7 cells and `gv-area` sums
   the cell areas. Both of those tools are subprograms of [xlsynth-driver](https://crates.io/crates/xlsynth-driver) 
2. The same IR is emitted as SystemVerilog and synthesized with [Yosys](https://github.com/YosysHQ/yosys) against
   the full library, and `gv-area` sums the cell areas of its netlist as for g8r.
   Both timings include the `gv-area` run.
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
They run with [uv](https://docs.astral.sh/uv/), which installs Python and
the packages pinned in `uv.lock` into `.venv/`; `setup.sh` does this once, and `uv run --locked` checks it on every
run:

```shell
uv run --locked scripts/plot_logs.py comp_logs --output-dir plots
```

`run-flow.sh` runs everything end to end: `setup.sh`, `compare-all.sh` over
`examples/` (including `examples/_mutations/`), the area and timing plots, the mutation
ranking charts, and finally the HTML report in `report/`:

```shell
./run-flow.sh
```

Open `report/index.html` in a browser; the ranking subsite is linked from it.
