#!/usr/bin/env python3

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

"""Summarize the output of analyze-flows.sh.

Writes OUTPUT_DIR/report.md with the per-design results, geometric means
relative to Yosys and the time per stage of each flow; the charts of time per
stage in OUTPUT_DIR/comparison; and a chart of the passes and areas of each
design next to its TSV in OUTPUT_DIR/passes.
"""

from __future__ import annotations

import argparse
from math import exp, log
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
import plot_passes
from plot_style import DARK_STAGES, INK, INK_2, LABELS, STAGES, SURFACE, style


def geomean(values: pd.Series) -> float:
    values = list(values.dropna())
    return exp(sum(log(v) for v in values) / len(values))


def stage_bars(values: pd.DataFrame, fmt, title: str, xlabel: str, path: Path, totals: bool = False) -> None:
    """One stacked bar per flow (rows) split into stages (columns), with value labels."""
    fig, ax = plt.subplots(figsize=(10, 2.6), facecolor=SURFACE)
    style(ax)
    left = pd.Series(0.0, index=values.index)
    xmax = values.sum(axis=1).max()
    for stage, color in STAGES.items():
        bars = ax.barh([LABELS[f] for f in values.index], values[stage], left=left, color=color,
                       height=0.6, edgecolor=SURFACE, linewidth=2, label=stage)
        ax.bar_label(bars, labels=[fmt(v) if v >= 0.06 * xmax else "" for v in values[stage]],
                     label_type="center", fontsize=9, color="white" if stage in DARK_STAGES else INK)
        left += values[stage]
    if totals:
        for y, total in enumerate(left):
            ax.text(total, y, f"  {fmt(total)} s", va="center", color=INK, fontsize=10, fontweight="bold")
    ax.invert_yaxis()
    ax.set_title(title, loc="left", color=INK, fontsize=13, fontweight="bold")
    ax.set_xlim(0, xmax * (1.15 if totals else 1))
    ax.set_xlabel(xlabel, color=INK_2)
    ax.tick_params(axis="y", labelsize=11, labelcolor=INK)
    ax.legend(ncols=len(STAGES), loc="upper center", bbox_to_anchor=(0.5, -0.32), frameon=False,
              fontsize=9, labelcolor=INK_2, handlelength=1.2)
    fig.savefig(path, dpi=150, facecolor=SURFACE, bbox_inches="tight")
    plt.close(fig)


def stage_shares(passes_dir: Path) -> pd.DataFrame:
    """Median ms per flow and stage for each design."""
    rows = []
    for tsv in sorted(passes_dir.glob("*.tsv")):
        per_pass, _ = plot_passes.median_passes(tsv)
        if per_pass.empty:
            continue
        stage = per_pass.groupby(["flow", "stage"])["ms"].sum().reset_index()
        stage["design"] = tsv.stem
        rows.append(stage)
    return pd.concat(rows) if rows else pd.DataFrame(columns=["flow", "stage", "ms", "design"])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output_dir", type=Path, help="output directory of analyze-flows.sh")
    args = parser.parse_args()
    out = args.output_dir
    (out / "comparison").mkdir(exist_ok=True)

    flows = pd.read_csv(out / "flows.tsv", sep="\t")
    designs = list(dict.fromkeys(flows["design"]))
    area = flows.pivot(index="design", columns="flow", values="area_um2").reindex(designs)
    cpu = flows.pivot(index="design", columns="flow", values="cpu_ms").reindex(designs)
    cells = flows.pivot(index="design", columns="flow", values="cells").reindex(designs)
    flow_names = [f for f in LABELS if f in area.columns]

    md = ["# Flow comparison results", "",
          f"{len(designs)} designs; area by gv-area for every netlist, CPU time is the median",
          "over the runs of compare-flows.sh. Ratios below 1 mean smaller or faster than Yosys.", ""]

    # Summary: geometric means relative to Yosys and wins.
    md += ["## Summary", "", "| flow | area / Yosys (geomean) | CPU time / Yosys (geomean) | smallest area | fastest |",
           "| --- | --- | --- | --- | --- |"]
    # Ties count as a win for every tied flow.
    best_area = area[flow_names].round(2).pipe(lambda t: t.eq(t.min(axis=1), axis=0))
    best_cpu = cpu[flow_names].pipe(lambda t: t.eq(t.min(axis=1), axis=0))
    best_cells = cells[flow_names].pipe(lambda t: t.eq(t.min(axis=1), axis=0))
    for flow in flow_names:
        md.append(f"| {LABELS[flow]} | {geomean(area[flow] / area['yosys']):.3f} | {geomean(cpu[flow] / cpu['yosys']):.3f} "
                  f"| {best_area[flow].sum()} of {len(designs)} | {best_cpu[flow].sum()} of {len(designs)} |")

    # Per design.
    md += ["", "## Per design", "",
           "| design | " + " | ".join(f"{LABELS[f]} µm²" for f in flow_names) + " | "
           + " | ".join(f"{LABELS[f]} cells" for f in flow_names) + " | "
           + " | ".join(f"{LABELS[f]} ms" for f in flow_names) + " |",
           "| --- |" + " --- |" * (3 * len(flow_names))]
    for d in designs:
        def fmt(table, flow, spec, best):
            if pd.isna(table.loc[d, flow]):
                return "-"
            text = format(table.loc[d, flow], spec)
            return f"**{text}**" if best.loc[d, flow] else text
        md.append(f"| {d} | " + " | ".join(fmt(area, f, ".2f", best_area) for f in flow_names) + " | "
                  + " | ".join(fmt(cells, f, ".0f", best_cells) for f in flow_names) + " | "
                  + " | ".join(fmt(cpu, f, ".0f", best_cpu) for f in flow_names) + " |")

    # Stages.
    stages = stage_shares(out / "passes")
    if not stages.empty:
        totals = stages.groupby(["design", "flow"])["ms"].transform("sum")
        stages["share"] = stages["ms"] / totals
        share = stages.groupby(["flow", "stage"])["share"].mean().unstack().reindex(columns=list(STAGES)).fillna(0)
        share = share.reindex([f for f in flow_names if f in share.index])
        md += ["", "## Time per stage", "",
               "Mean share of each stage in the per-pass time of a flow, over the designs:", "",
               "| flow | " + " | ".join(STAGES) + " |", "| --- |" + " --- |" * len(STAGES)]
        for flow in share.index:
            md.append(f"| {LABELS[flow]} | " + " | ".join(f"{100 * share.loc[flow, s]:.0f}%" for s in STAGES) + " |")
        md.append("")

        n = stages["design"].nunique()
        stage_bars(share * 100, lambda v: f"{v:.0f}%", f"Time per stage, mean share over {n} designs",
                   "share of the flow's time, %", out / "comparison" / "stages.png")
        md += ["![Time per stage](comparison/stages.png)", ""]

        # The sum over the designs, dominated by the slowest ones.
        seconds = stages.groupby(["flow", "stage"])["ms"].sum().unstack().reindex(columns=list(STAGES)).fillna(0) / 1000
        seconds = seconds.reindex(share.index)
        md += [f"Total time of each stage over the {n} designs, in seconds:", "",
               "| flow | " + " | ".join(STAGES) + " | total |", "| --- |" + " --- |" * (len(STAGES) + 1)]
        for flow in seconds.index:
            md.append(f"| {LABELS[flow]} | " + " | ".join(f"{seconds.loc[flow, s]:.2f}" for s in STAGES)
                      + f" | {seconds.loc[flow].sum():.2f} |")
        md.append("")
        stage_bars(seconds, lambda v: f"{v:.1f}", f"Time per stage, sum over {n} designs (dominated by the slowest)",
                   "time, s", out / "comparison" / "stages_s.png", totals=True)
        md += ["![Total time per stage](comparison/stages_s.png)", ""]

    # One chart of the passes of each design.
    for tsv in sorted((out / "passes").glob("*.tsv")):
        passes, runs = plot_passes.median_passes(tsv)
        if not passes.empty:
            plot_passes.draw(passes, runs, tsv.stem, tsv.with_suffix(".png"),
                             area.loc[tsv.stem].dropna().to_dict() if tsv.stem in area.index else None)

    (out / "report.md").write_text("\n".join(md).rstrip() + "\n")
    print(f"wrote {out / 'report.md'}")


if __name__ == "__main__":
    main()
