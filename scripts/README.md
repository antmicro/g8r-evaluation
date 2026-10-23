# Benchmark Plot Gallery

Copyright (c) 2026 [Antmicro](https://www.antmicro.com)

Three scripts turn benchmark logs and summary tables into individual plots and a browsable HTML gallery. They recursively discover every `*.log` file, so folders and files added later require no configuration.

| Script | Purpose |
| --- | --- |
| `plot_logs.py` | One PNG bar chart per `*.log` benchmark log |
| `plot_ranking.py` | Ranking chart of `g8r_um2`/`yosys_um2` vs a baseline from a summary table |
| `build_gallery.py` | HTML gallery over plot directories, plus an optional rankings subsite |

## Install dependencies

```sh
python3 -m pip install matplotlib numpy pandas
```

## Generate plots and site

```sh
python3 plot_logs.py comp_logs --output-dir plots
python3 build_gallery.py plots --output site/index.html
```

Open `site/index.html` in a browser. The gallery groups plots using each log's parent directory.

To compare parameter runs, pass multiple plot directories. Charts with the same source log are placed side by side and labeled with their plots directory name.

```sh
python3 build_gallery.py plots-default plots-tuned --output site/index.html
```

## Ranking charts

`plot_ranking.py` builds a chart comparing `g8r_um2`, `yosys_um2` and (when the column is present) `orfs_um2` per function against a baseline, and prints the sorted table and equivalent Mermaid chart code to stdout:

```sh
python3 plot_ranking.py --input design.log --output rankings/table_a.png
```

By default the first data row of the log is the baseline (the 0% reference). Pass `--base-function NAME` to pick another function; if the named function is missing from the table, the first data row is used.

The input is a log file from compare-all.sh script run with at least the columns `function`, `g8r_um2`, `yosys_um2`; an optional `ratio` column is accepted and an optional `orfs_um2` column is plotted as a third bar series.

Pass the generated ranking PNGs to `build_gallery.py --ranking-plots` to add a `rankings/index.html` subsite with a navigation link from the main comparison page. Ranking charts are grouped by their parent directory name, so keep charts for one comparison in one directory.

```sh
python3 build_gallery.py plots --output site/index.html \
    --ranking-plots rankings/table_a.png rankings/table_b.png
```

## Log format

Logs must have a whitespace-delimited header, a first (label) column, and one or more numeric columns. Blank lines and lines beginning with `#` or `//` are ignored.

When a numeric column is named `ratio`, it is rendered as a label above each group of bars instead of as its own bar. The plot also includes that ratio's mean in the legend.

For timing logs whose value columns begin with the three area columns (e.g. `g8r_um2  yosys_um2  ratio`) followed by timing columns, pass `--mode time`. The leading area columns are dropped and only the timing columns are plotted, with the y-axis labelled in milliseconds:

```sh
python3 plot_logs.py comp_logs --output-dir plots-time --mode time
```

## Custom locations

```sh
python3 plot_logs.py /path/to/logs --output-dir /path/to/plots
python3 build_gallery.py /path/to/plots --output /path/to/site/index.html
```
