# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

"""Colors, labels and axis style shared by the analysis charts."""

# Flows as compare-flows.sh and time-passes.sh name them, in report order, with
# their labels.
LABELS = {
    "g8r": "g8r",
    "g8r-abc": "g8r + ABC opt + ABC map",
    "g8r-abc-g8r": "g8r + ABC opt + g8r map",
    "yosys": "Yosys",
}

# Stages in legend order.
STAGES = {
    "front end": "#2a78d6",
    "AIG optimization": "#eb6834",
    "library load": "#1baf7a",
    "mapping": "#eda100",
    "area report": "#e87ba4",
    "startup + I/O": "#008300",
}
DARK_STAGES = {"front end", "startup + I/O"}  # white value labels
SURFACE, INK, INK_2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#d9d8d4"


def style(ax, grid_axis: str = "x") -> None:
    ax.set_facecolor(SURFACE)
    ax.grid(axis=grid_axis, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(GRID)
    ax.tick_params(colors=INK_2, length=0)
