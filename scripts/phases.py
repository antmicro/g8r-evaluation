#!/usr/bin/env python3

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

"""Turn timestamped tool output into the time of each pass, for time-passes.sh.

Reads lines "[SECONDS] TEXT" on stdin. Each argument is "STAGE|PASS|MARKER": the
pass starts at the first line that contains MARKER, or starts with it if MARKER
begins with ^, and lasts until the next pass starts. A line starts at most one
pass, the first in argument order whose marker it matches.

Prints "STAGE<TAB>PASS<TAB>MS" per pass, in the order of the output. A marker
that no line matches is an error, since its time would go to the pass before:
after a tool update, a reworded log line stops the analysis.
"""

import re
import sys


def matches(marker: str, text: str) -> bool:
    if marker.startswith("^"):
        return text.startswith(marker[1:])
    return marker in text


def main() -> None:
    passes = [arg.split("|", 2) for arg in sys.argv[1:]]
    starts: dict[int, tuple[int, float]] = {}  # pass index: (line number, seconds)
    for number, line in enumerate(sys.stdin):
        stamped = re.match(r"\[\s*([\d.]+)\] ?(.*)", line.rstrip("\n"))
        if not stamped:
            continue
        seconds, text = float(stamped[1]), stamped[2]
        for i, (_, _, marker) in enumerate(passes):
            if i not in starts and matches(marker, text):
                starts[i] = (number, seconds)
                break

    missing = [i for i in range(len(passes)) if i not in starts]
    for i in missing:
        print(f'time-passes.sh: no line contains "{passes[i][2]}" of pass "{passes[i][1]}"', file=sys.stderr)

    in_order = sorted(starts, key=lambda i: starts[i][0])
    for i, following in zip(in_order, in_order[1:]):
        stage, name, _ = passes[i]
        print(f"{stage}\t{name}\t{1e3 * (starts[following][1] - starts[i][1]):.3f}")
    if missing:
        sys.exit(1)


if __name__ == "__main__":
    main()
