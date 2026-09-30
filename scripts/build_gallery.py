#!/usr/bin/env python3

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

"""Build a directory-categorized HTML gallery from plots made by plot_logs.py."""

from __future__ import annotations

import argparse
import html
import json
import os
import shutil
import sys
from collections import defaultdict
from pathlib import Path


PAGE_STYLE = """
body { background: #f6f8fb; color: #172033; font: 16px/1.5 system-ui, sans-serif; margin: 0; }
main { margin: auto; max-width: 1440px; padding: 2rem; }
h1 { margin-bottom: .15rem; } .subtitle { color: #5c6577; margin-top: 0; }
.category { margin-top: 2.5rem; } .comparisons { display: grid; gap: 1.25rem; }
article { background: #fff; border: 1px solid #dce1eb; border-radius: .75rem; overflow: hidden; box-shadow: 0 2px 5px #1720330d; }
article h3 { font-size: 1rem; margin: 0; padding: .8rem 1rem; } .variants { display: grid; gap: 1px; background: #dce1eb; }
figure, .missing { background: #fff; margin: 0; min-width: 0; padding: .75rem; } figcaption { color: #5c6577; font-size: .875rem; font-weight: 700; margin-bottom: .5rem; }
img { display: block; height: auto; width: 100%; } .missing { color: #70798a; display: grid; min-height: 10rem; place-items: center; text-align: center; }
a { color: inherit; text-decoration: none; } a:hover img { outline: 2px solid #2855b8; outline-offset: 2px; }
@media (max-width: 760px) { .variants { grid-template-columns: 1fr !important; } }
"""


def load_manifest(plots_dir: Path) -> list[dict[str, str]]:
    manifest_path = plots_dir / "manifest.json"
    if manifest_path.is_file():
        contents = json.loads(manifest_path.read_text(encoding="utf-8"))
        if isinstance(contents, list):
            return contents

    return [
        {"category": item.parent.as_posix() if item.parent != Path(".") else "Uncategorized", "log": "", "plot": item.as_posix()}
        for item in sorted(plots_dir.rglob("*.png"))
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "plots_dirs",
        nargs="*",
        type=Path,
        default=[Path("plots")],
        help="One or more plot directories. Matching plots are displayed side by side.",
    )
    parser.add_argument("--output", type=Path, default=Path("site/index.html"))
    args = parser.parse_args()

    plots_dirs = [plots_dir.resolve() for plots_dir in args.plots_dirs]
    output_path = args.output.resolve()
    missing_directories = [str(plots_dir) for plots_dir in plots_dirs if not plots_dir.is_dir()]
    if missing_directories:
        print(f"Plots directory does not exist: {', '.join(missing_directories)}", file=sys.stderr)
        return 2
    directory_names = [plots_dir.name for plots_dir in plots_dirs]
    if len(set(directory_names)) != len(directory_names):
        print("Plot directory names must be unique so they can label comparisons.", file=sys.stderr)
        return 2

    categories: dict[str, dict[str, dict[str, Path]]] = defaultdict(lambda: defaultdict(dict))
    for plots_dir in plots_dirs:
        for item in load_manifest(plots_dir):
            plot_file = plots_dir / item["plot"]
            if plot_file.is_file():
                chart_key = item["log"] or item["plot"]
                categories[item["category"]][chart_key][plots_dir.name] = plot_file

    sections: list[str] = []
    for category in sorted(categories):
        cards = []
        for chart_key, variants in sorted(categories[category].items()):
            title = Path(chart_key).stem.replace("_", " ")
            columns = []
            for directory_name in directory_names:
                image_path = variants.get(directory_name)
                if image_path is None:
                    columns.append(f'<div class="missing"><strong>{html.escape(directory_name)}</strong><br>Plot not found</div>')
                    continue
                asset_path = output_path.parent / "assets" / directory_name / Path(chart_key).with_suffix(".png")
                asset_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(image_path, asset_path)
                relative_image = Path(os.path.relpath(asset_path, output_path.parent)).as_posix()
                columns.append(
                    f'<figure><figcaption>{html.escape(directory_name)}</figcaption><a href="{html.escape(relative_image)}">'
                    f'<img src="{html.escape(relative_image)}" alt="{html.escape(title)} from {html.escape(directory_name)}" loading="lazy"></a></figure>'
                )
            cards.append(
                f'<article><h3>{html.escape(title)}</h3><div class="variants" '
                f'style="grid-template-columns: repeat({len(directory_names)}, minmax(0, 1fr));">{"".join(columns)}</div></article>'
            )
        sections.append(f'<section class="category"><h2>{html.escape(category)}</h2><div class="comparisons">{"".join(cards)}</div></section>')

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
        f"<title>Benchmark plots</title><style>{PAGE_STYLE}</style></head><body><main>"
        f"<h1>Benchmark plot comparison</h1><p class=\"subtitle\">{sum(map(len, categories.values()))} matched plot(s) across {len(categories)} categor{ 'y' if len(categories) == 1 else 'ies'} and {len(plots_dirs)} plot director{'y' if len(plots_dirs) == 1 else 'ies'}.</p>"
        f"{''.join(sections) or '<p>No PNG plots found.</p>'}</main></body></html>\n",
        encoding="utf-8",
    )
    print(f"Created {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
