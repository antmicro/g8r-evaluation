# Log Plot Gallery

Copyright (c) 2026 [Antmicro](https://www.antmicro.com)

Two scripts turn a tree of benchmark logs into individual plots and a browsable HTML gallery. They recursively discover every `*.log` file, so folders and files added later require no configuration.

## Install dependency

```sh
python3 -m pip install matplotlib numpy
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
