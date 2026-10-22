#!/usr/bin/env python3

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

"""Create one PNG chart per whitespace-delimited benchmark log file.

Expected input resembles:
    function  g8r_um2  yosys_um2  ratio  orfs_um2  ir2g8r_ms  g8r_ms  yosys_ms
    arith_add8  3.02  3.12  0.97  10.00     17.00      80.00  201.00

The first column is used as a category. All remaining columns whose values can
be parsed as numbers are plotted. The script recursively discovers ``*.log``
files so newly added folders and logs are included without configuration.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", str(Path(tempfile.gettempdir()) / "matplotlib-cache"))

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Patch


@dataclass
class LogTable:
    labels: list[str]
    series: dict[str, list[float]]


def parse_number(value: str) -> float:
    """Parse ordinary or scientific-notation values, optionally with commas."""
    return float(value.replace(",", ""))


def parse_log(path: Path) -> LogTable:
    rows: list[list[str]] = []
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith(("#", "//")):
            continue
        cells = re.split(r"\s+", line)
        if len(cells) > 1:
            rows.append(cells[0:5])

    if len(rows) < 2:
        raise ValueError("expected a header and at least one data row")

    header = rows[0]
    data_rows = rows[1:]
    if len(header) < 2:
        raise ValueError("expected a label column and at least one value column")

    labels: list[str] = []
    raw_columns: dict[str, list[str]] = {name: [] for name in header[1:]}
    for row_index, row in enumerate(data_rows, start=2):
        if len(row) != len(header):
            raise ValueError(
                f"line {row_index}: expected {len(header)} columns, found {len(row)}"
            )
        labels.append(row[0])
        for column_index, name in enumerate(header[1:], start=1):
            raw_columns[name].append(row[column_index])

    series: dict[str, list[float]] = {}
    for name, values in raw_columns.items():
        try:
            series[name] = [parse_number(value) for value in values]
        except ValueError:
            continue
    if not series:
        raise ValueError("no numeric data columns found")
    return LogTable(labels=labels, series=series)


def plot_table(table: LogTable, source: Path, destination: Path) -> None:
    series_names = list(table.series)
    ratio_names = [name for name in series_names if name.casefold() == "ratio"]
    bar_series_names = [name for name in series_names if name not in ratio_names]
    if not bar_series_names:
        bar_series_names = series_names
        ratio_names = []

    row_count = len(table.labels)
    figure_width = max(10, min(22, 0.32 * row_count + 6))
    fig, axis = plt.subplots(figsize=(figure_width, 6.5))

    x_positions = np.arange(row_count)
    bar_width = 0.82 / len(bar_series_names)
    for index, series_name in enumerate(bar_series_names):
        offset = (index - (len(bar_series_names) - 1) / 2) * bar_width
        axis.bar(x_positions + offset, table.series[series_name], bar_width, label=series_name)

    maximum_bar_value = max(max(table.series[name]) for name in bar_series_names)
    if ratio_names:
        label_offset = max(maximum_bar_value * 0.025, 0.05)
        for row_index, x_position in enumerate(x_positions):
            ratio_text = str(f"g8r/yosys: {table.series["ratio"][row_index]:.3g}")
            axis.text(
                x_position,
                max(table.series[name][row_index] for name in bar_series_names) + label_offset,
                ratio_text,
                ha="center",
                va="bottom",
                fontsize=8,
                fontweight="bold",
            )
        axis.set_ylim(top=maximum_bar_value + label_offset * 3)

    axis.set_title(source.stem.replace("_", " "), pad=20)
    axis.set_xlabel("Function")
    axis.set_ylabel("Value")
    axis.set_xticks(x_positions, table.labels, rotation=45, ha="right")
    axis.grid(axis="y", alpha=0.25)
    legend_handles, legend_labels = axis.get_legend_handles_labels()
    if ratio_names:
        ratio_mean_summary = "  •  ".join(
            f"mean {name}: {np.mean(table.series[name]):.3g}" for name in ratio_names
        )
        legend_handles.append(Patch(visible=False))
        legend_labels.append(ratio_mean_summary)
    axis.legend(legend_handles, legend_labels)
    fig.tight_layout()
    destination.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(destination, dpi=180, bbox_inches="tight")
    plt.close(fig)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_dir", nargs="?", type=Path, default=Path("comp_logs"))
    parser.add_argument("--output-dir", type=Path, default=Path("plots"))
    args = parser.parse_args()

    input_dir = args.input_dir.resolve()
    output_dir = args.output_dir.resolve()
    if not input_dir.is_dir():
        print(f"Input directory does not exist: {input_dir}", file=sys.stderr)
        return 2

    manifest: list[dict[str, str]] = []
    failed = 0
    for log_path in sorted(input_dir.rglob("*.log")):
        relative_path = log_path.relative_to(input_dir)
        plot_path = output_dir / relative_path.with_suffix(".png")
        try:
            plot_table(parse_log(log_path), relative_path, plot_path)
            manifest.append(
                {
                    "category": relative_path.parent.as_posix() if relative_path.parent != Path(".") else "Uncategorized",
                    "log": relative_path.as_posix(),
                    "plot": plot_path.relative_to(output_dir).as_posix(),
                }
            )
            print(f"Created {plot_path}")
        except (OSError, ValueError) as error:
            failed += 1
            print(f"Skipped {log_path}: {error}", file=sys.stderr)

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Processed {len(manifest)} file(s); skipped {failed}. Manifest: {output_dir / 'manifest.json'}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
