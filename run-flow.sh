# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

./setup.sh

./compare-all.sh ./examples ./examples_logs

python3 ./scripts/plot_logs.py ./examples_logs --mode time --output-dir ./plots_examples_time
python3 ./scripts/plot_logs.py ./examples_logs --mode area --output-dir ./plots_examples

mkdir -p ranking_plots

python3 ./scripts/plot_ranking.py --input ./examples_logs/_mutations/chained/chained.log --output ranking_plots/operations_mutations.png --base-function baseline
python3 ./scripts/plot_ranking.py --input ./examples_logs/_mutations/fir/fir.log --output ranking_plots/fir_mutations.png --base-function fir_00_base8


mkdir -p report

python3 ./scripts/build_gallery.py --output report/index.html ./plots_examples ./plots_examples_time --ranking-plots ./ranking_plots/*
