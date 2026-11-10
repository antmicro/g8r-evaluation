#!/usr/bin/env python3

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

"""Plot the per-pass times written by time-passes.sh.

Sums the passes that run more than once in a run (such as ABC's strash), takes
the median of each pass over the runs, prints the passes of each flow in
execution order, and draws the time of each flow split into stages, above the
largest passes of each flow.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
from plot_style import DARK_STAGES, GRID, INK, INK_2, LABELS, STAGES, SURFACE, style

TOP_PASSES = 7


def median_passes(tsv: Path) -> tuple[pd.DataFrame, int]:
    runs = pd.read_csv(tsv, sep="\t")
    # sort=False keeps the flows and passes in execution order.
    keys = ["flow", "stage", "pass"]
    per_run = runs.groupby(["run"] + keys, sort=False)["ms"].sum().reset_index()
    return per_run.groupby(keys, sort=False)["ms"].median().reset_index(), runs["run"].nunique()


def plot_stages(ax, passes: pd.DataFrame, area: dict[str, float] | None = None) -> None:
    stages = passes.pivot_table(index="flow", columns="stage", values="ms", aggfunc="sum", sort=False)
    stages = stages.reindex(columns=list(STAGES), fill_value=0).fillna(0)
    totals = stages.sum(axis=1)
    left = pd.Series(0.0, index=stages.index)
    for stage, color in STAGES.items():
        bars = ax.barh([LABELS.get(f, f) for f in stages.index], stages[stage], left=left, color=color, height=0.6,
                       edgecolor=SURFACE, linewidth=2, label=stage)  # 2 px gap between segments
        labels = [f"{v:.0f}" if v >= 0.05 * totals.max() else "" for v in stages[stage]]
        ax.bar_label(bars, labels=labels, label_type="center", fontsize=9,
                     color="white" if stage in DARK_STAGES else INK)
        left += stages[stage]
    # In brackets, the ratio to Yosys.
    def vs_yosys(flow, value, ref):
        return f" ({value / ref:.2f}×)" if flow != "yosys" and ref else ""
    for y, (flow, total) in enumerate(totals.items()):
        ax.text(total, y, f"  {total:.0f} ms{vs_yosys(flow, total, totals.get('yosys'))}", va="center", color=INK,
                fontsize=10, fontweight="bold")
        if area and flow in area:
            ax.text(total, y + 0.3, f"   {area[flow]:.2f} µm²{vs_yosys(flow, area[flow], area.get('yosys'))}",
                    va="center", color=INK_2, fontsize=9)
    ax.invert_yaxis()
    ax.set_xlim(0, totals.max() * 1.2)
    ax.set_xlabel("ms", color=INK_2)
    ax.tick_params(axis="y", labelsize=11, labelcolor=INK)
    ax.legend(ncols=len(STAGES), loc="upper center", bbox_to_anchor=(0.5, -0.32), frameon=False,
              fontsize=9, labelcolor=INK_2, handlelength=1.2)


def plot_top_passes(ax, rows: pd.DataFrame, flow: str) -> None:
    top = rows.nlargest(TOP_PASSES, "ms")
    rest = rows.drop(top.index)
    names = list(top["pass"]) + ([f"{len(rest)} other passes"] if len(rest) else [])
    values = list(top["ms"]) + ([rest["ms"].sum()] if len(rest) else [])
    colors = [STAGES.get(s, INK_2) for s in top["stage"]] + ([GRID] if len(rest) else [])
    bars = ax.barh(names, values, color=colors, height=0.65, edgecolor=SURFACE, linewidth=2)
    ax.bar_label(bars, labels=[f" {v:.1f}" for v in values], color=INK, fontsize=9)
    ax.invert_yaxis()
    # A scale per flow, since the slowest pass of one flow can hide all passes of another.
    ax.set_xlim(0, max(values) * 1.15)
    ax.xaxis.set_major_locator(matplotlib.ticker.MaxNLocator(4))
    ax.set_title(LABELS.get(flow, flow), loc="left", color=INK, fontsize=11)
    ax.set_xlabel("ms", color=INK_2)
    ax.tick_params(axis="y", labelsize=9, labelcolor=INK)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tsv", type=Path, help="output of time-passes.sh")
    parser.add_argument("--output", type=Path, required=True, help="PNG to write")
    parser.add_argument("--title", default=None,
                        help="chart title (default: the TSV name, or its directory for passes.tsv)")
    args = parser.parse_args()

    passes, runs = median_passes(args.tsv)
    for flow, rows in passes.groupby("flow", sort=False):
        print(f"{LABELS.get(flow, flow)}: {rows['ms'].sum():.1f} ms")
        for stage, name, ms in zip(rows["stage"], rows["pass"], rows["ms"]):
            print(f"  {stage:<17} {ms:9.2f}  {name}")

    default_title = args.tsv.resolve().parent.name if args.tsv.stem == "passes" else args.tsv.stem
    draw(passes, runs, args.title or default_title, args.output)


def draw(passes: pd.DataFrame, runs: int, title: str, output: Path, area: dict[str, float] | None = None) -> None:
    """The time per stage of each flow, with its area if given, above the largest passes of each flow."""
    flows = list(dict.fromkeys(passes["flow"]))
    fig = plt.figure(figsize=(max(12, 4 * len(flows)), 7.5), facecolor=SURFACE)
    grid = fig.add_gridspec(2, len(flows), height_ratios=[1, 1.6], hspace=0.65, wspace=0.8)
    ax = fig.add_subplot(grid[0, :])
    style(ax)
    plot_stages(ax, passes, area)
    for i, (flow, rows) in enumerate(passes.groupby("flow", sort=False)):
        ax = fig.add_subplot(grid[1, i])
        style(ax)
        plot_top_passes(ax, rows, flow)
    fig.suptitle(title, x=0.05, ha="left", color=INK, fontsize=15, fontweight="bold")
    fig.text(0.05, 0.925, f"Time per stage and largest passes, median of {runs} runs" + (", area by gv-area" if area else ""), color=INK_2, fontsize=10)
    fig.savefig(output, dpi=150, facecolor=SURFACE, bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    main()
