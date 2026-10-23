#!/usr/bin/env python3

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

# Generate a chart comparing g8r_um2, yosys_um2 and (when present) orfs_um2
# differences vs a baseline function. The baseline is selected with
# --base-function and defaults to the first data row of the input table.
#
# Usage:
#   python plot_ranking.py --input table.tsv --output chart.png \
#       [--base-function fir_00_base8]
#
# Dependencies:
#   pip install pandas matplotlib

import argparse
import re
from io import StringIO

import pandas as pd

try:
    import matplotlib.pyplot as plt
except ImportError:
    plt = None


# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# (short name, table column) pairs compared in the ranking chart. Only
# columns actually present in the input table are plotted.
METRIC_COLUMNS = [
    ("g8r", "g8r_um2"),
    ("yosys", "yosys_um2"),
    ("orfs", "orfs_um2"),
]

# Set this to False if you do not want the 0% line in the printed Mermaid code.
INCLUDE_ZERO_LINE_IN_MERMAID = True

# ------------------------------------------------------------
# Table loading and cleaning
# ------------------------------------------------------------

def read_table_text(path: str) -> str:
    """
    Read the table from the mandatory --input file path.
    """
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def clean_table_text(text: str) -> str:
    """
    Remove markdown code fences and convert markdown pipe tables to whitespace.
    Also skips separator lines like:
        |----|----|
        |:--:|---:|
    """
    out_lines = []

    for raw_line in text.splitlines():
        line = raw_line.strip()

        if not line:
            continue

        # Skip markdown code fences
        if line.startswith("```"):
            continue

        # Skip markdown separator lines like |---|---| or :---:
        if re.match(r"^\s*[|\s:-]+\s*$", line):
            continue

        # If it looks like a markdown table row, replace pipes with spaces.
        if "|" in line:
            line = line.strip("|").strip()
            line = line.replace("|", " ")

        out_lines.append(line)

    return "\n".join(out_lines)


def load_dataframe(text: str) -> pd.DataFrame:
    """
    Load table text into a DataFrame.

    Expected columns:
        function, g8r_um2, yosys_um2[, ratio][, orfs_um2],
    """
    cleaned = clean_table_text(text)

    df = pd.read_csv(
        StringIO(cleaned),
        sep=r"\s+",
        engine="python",
    )

    df.columns = df.columns.str.strip()

    required = ["function", "g8r_um2", "yosys_um2"]
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    # Convert numeric columns
    for col in ["g8r_um2", "yosys_um2", "orfs_um2", "ratio", ""]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # Drop rows that failed numeric parsing
    df = df.dropna(subset=["g8r_um2", "yosys_um2"]).copy()

    if df.empty:
        raise ValueError("No usable data rows found after parsing table.")

    return df


# ------------------------------------------------------------
# Chart helpers
# ------------------------------------------------------------

def short_label(function_name: str) -> str:
    """
    Turn fir_08_tree8 into f08, fir_15_sym12 into f15, etc.

    This keeps x-axis labels short so they do not dominate the chart.
    """

    # Fallback: use up to 4 characters
    return '_'.join(function_name.split("_")[2:])


def unique_labels(labels):
    """
    Make labels unique.
    Example: if two entries produce f08, they become f08, f08_2.
    """
    seen = {}
    out = []

    for label in labels:
        seen[label] = seen.get(label, 0) + 1

        if seen[label] == 1:
            out.append(label)
        else:
            out.append(f"{label}_{seen[label]}")

    return out


def metric_columns(df: pd.DataFrame):
    """Short (column, table column) pairs actually present in the table."""
    return [(short, col) for short, col in METRIC_COLUMNS if col in df.columns]


def compute_differences(df: pd.DataFrame, base_function: str | None):
    """
    Compute percent differences vs base_function and sort ascending by %Δ g8r.

    When base_function is None (or names a row the table does not contain),
    the first data row of the table is used as the baseline.
    """
    metrics = metric_columns(df)

    # Find baseline. Without an explicit baseline, or when the requested
    # baseline is missing, use the first row.
    base_rows = df[df["function"] == base_function] if base_function else pd.DataFrame()

    if base_rows.empty:
        base_rows = df.iloc[:1]

    base_row = base_rows.iloc[0]
    base_function = base_row["function"]
    bases = {short: float(base_row[col]) for short, col in metrics}

    # Remove baseline from plotted data
    work = df[df["function"] != base_function].copy()

    if work.empty:
        raise ValueError(f"No non-base rows remain after removing {base_function}.")

    # Percent differences vs baseline
    for short, col in metrics:
        work[f"{short}_pct"] = 100.0 * (work[col] / bases[short] - 1.0)

    # Sort ascending by g8r percent difference (first available metric)
    sort_column = f"{metrics[0][0]}_pct"
    work = work.sort_values(sort_column, ascending=True).reset_index(drop=True)

    return work, base_function, metrics, bases


def bar_descriptions(metrics) -> str:
    """Describe the bar order for chart titles: '1st bar: g8r, 2nd bar: yosys'."""
    suffixes = {1: "st", 2: "nd", 3: "rd"}
    return ", ".join(
        f"{index + 1}{suffixes.get(index + 1, 'th')} bar: {short}"
        for index, (short, _) in enumerate(metrics)
    )


def make_mermaid(work: pd.DataFrame, labels, base_function: str, metrics) -> str:
    """
    Generate Mermaid xychart-beta code from computed data.
    """
    if work.empty:
        return "No data available to plot."

    pct_columns = [f"{short}_pct" for short, _ in metrics]

    vals = [float(v) for column in pct_columns for v in work[column].tolist()] + [0.0]

    y_min = min(vals) - 15
    y_max = max(vals) + 15

    x_axis = ", ".join(f'"{label}"' for label in labels)
    zero_line = ", ".join("0" for _ in labels)

    init_line = '%%{init: {"xyChart": {"fontSize": 8}}}%%'

    lines = [
        init_line,
        "xychart-beta",
        f'    title "Δ% vs {base_function} — {bar_descriptions(metrics)}"',
        f"    x-axis [{x_axis}]",
        f'    y-axis "Δ% vs {base_function}" {y_min:.1f} --> {y_max:.1f}',
    ]

    for column in pct_columns:
        bars = ", ".join(f"{float(v):.1f}" for v in work[column])
        lines.append(f"    bar [{bars}]")

    if INCLUDE_ZERO_LINE_IN_MERMAID:
        lines.append(f"    line [{zero_line}]")

    return "\n".join(lines)


def save_plot(work, labels, base_function, out_file, metrics, force_rotation=None, label_fontsize=8):
    """
    Grouped bar chart with a dashed zero line.
    Labels are readable regardless of length: horizontal when short,
    rotated 90 deg (right-aligned) when long, with bottom margin reserved.
    """
    if plt is None:
        print("Matplotlib not available; skipping interactive plot.")
        return

    n = len(labels)
    if n == 0:
        print("No rows to plot.")
        return

    max_len = max(len(s) for s in labels)

    # Decide orientation: keep horizontal only for short, few labels (readable inline).
    if force_rotation is None:
        rotation = 0 if (max_len <= 8 and n <= 18) else 90
    else:
        rotation = force_rotation

    # Wider figure for horizontal long labels; taller+margin for rotated ones.
    if rotation == 0:
        fig_w = max(11.0, 0.6 * n)
        fig_h = 6.5
    else:
        fig_w = max(9.0, 0.32 * n)
        fig_h = 6.8

    x = list(range(n))
    width = 0.8 / len(metrics)
    value_lists = [[float(v) for v in work[f"{short}_pct"]] for short, _ in metrics]
    all_vals = [v for vals in value_lists for v in vals] + [0.0]
    y_min, y_max = min(all_vals) - 15, max(all_vals) + 15

    fig, ax = plt.subplots(figsize=(fig_w, fig_h))

    for index, ((short, col), vals) in enumerate(zip(metrics, value_lists)):
        offset = (index - (len(metrics) - 1) / 2) * width
        ax.bar([xi + offset for xi in x], vals, width,
               label=f"Δ% {col} vs {base_function}")
    ax.axhline(0, linestyle="--", linewidth=1.2, color="black", label="0% difference")

    ax.set_title(
        f"Difference vs {base_function}, "
        f"sorted ascending by Δ% {metrics[0][1]}"
    )
    ax.set_xlabel("function")
    ax.set_ylabel("percent difference vs baseline")
    ax.set_xticks(x)
    ax.set_xticklabels(
        labels, fontsize=label_fontsize, rotation=rotation,
        ha="right" if rotation == 90 else "center",
        va="center" if rotation == 90 else "top",
    )
    ax.tick_params(axis="x", labelsize=label_fontsize, pad=24)
    ax.tick_params(axis="y", labelsize=9)
    ax.set_ylim(y_min, y_max)
    ax.grid(axis="y", linestyle=":", alpha=0.45)
    ax.legend(fontsize=8)

    # Reserve enough bottom space for the labels BEFORE saving.
    if rotation == 90:
        # vertical text height ≈ chars * per-char line height; convert to figure fraction
        needed_in = max_len * (label_fontsize * 0.011) + 0.4
        bottom = min(0.55, needed_in / fig_h)
        fig.subplots_adjust(left=0.07, right=0.98, top=0.93, bottom=bottom)
    else:
        fig.tight_layout()

    # Correct order: lay out first, then save, then show.
    fig.savefig(out_file, dpi=400)

def main():
    parser = argparse.ArgumentParser(
        description="Generate a chart comparing g8r_um2, yosys_um2 and orfs_um2 "
        "(when present) vs the baseline."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to the input table file (TSV or markdown table).",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to the output table file.",
    )
    parser.add_argument(
        "--base-function",
        default=None,
        help="Function used as the 0%% baseline. Defaults to the first data "
        "row of the input table.",
    )
    args = parser.parse_args()

    table_text = read_table_text(args.input)
    df = load_dataframe(table_text)
    work, base_function, metrics, bases = compute_differences(
        df,
        args.base_function,
    )
    labels = unique_labels([short_label(fn) for fn in work["function"]])
    print("Sorted data used for chart:")
    display_cols = ["function"]
    round_cols = []
    for short, col in metrics:
        display_cols += [col, f"{short}_pct"]
        round_cols += [col, f"{short}_pct"]
    display = work[display_cols].copy()
    display[round_cols] = display[round_cols].round(2)
    print(display.to_string(index=False))
    print("\nBaseline:")
    baseline_parts = ", ".join(
        f"{col}={bases[short]:.2f}" for short, col in metrics
    )
    print(f"{base_function}: {baseline_parts}")
    print("\nGenerated Mermaid chart code:")
    print(make_mermaid(work, labels, base_function, metrics))
    # Optional Matplotlib chart
    save_plot(work, labels, base_function, args.output, metrics)

if __name__ == "__main__":
    main()
