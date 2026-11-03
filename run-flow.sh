#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

echo "Usage: ./run-flow.sh"
echo
echo "Runs the whole flow, from setup.sh via compare-all.sh to plots"
echo "and report generation"


set -euo pipefail

./setup.sh

./compare-all.sh ./examples ./examples_logs

uv run --locked ./scripts/plot_logs.py ./examples_logs --mode time --output-dir ./plots_examples_time
uv run --locked ./scripts/plot_logs.py ./examples_logs --mode area --output-dir ./plots_examples

mkdir -p ranking_plots

uv run --locked ./scripts/plot_ranking.py --input ./examples_logs/_mutations/chained.log --output ranking_plots/operations_mutations.png --base-function baseline
uv run --locked ./scripts/plot_ranking.py --input ./examples_logs/_mutations/fir.log --output ranking_plots/fir_mutations.png --base-function fir_00_base8


mkdir -p report

uv run --locked ./scripts/build_gallery.py --output report/index.html ./plots_examples ./plots_examples_time --ranking-plots ./ranking_plots/*
