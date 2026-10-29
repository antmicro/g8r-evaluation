#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# Downloads XLS, builds xlsynth-driver into build/tools (Linux x86-64),
# downloads and extracts asap7 liberty files.
# Prerequisites: sudo apt install build-essential curl protobuf-compiler rustup yosys

for command in cc curl protoc rustup yosys bazelisk; do
    command -v "$command" >/dev/null || { echo "Cannot find $command; see README.md" >&2; exit 1; }
done

proj_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tools="$proj_root/tools"
mkdir -p "$tools/xls"
cd "$tools/xls"

xls_url=https://github.com/xlsynth/xlsynth/releases/download/v0.59.0
download() {
    [[ -f $1 ]] && echo "$2  $1" | sha256sum -c --status && return
    echo "Downloading $1"
    curl -fL "$xls_url/$1" -o "$1"
    echo "$2  $1" | sha256sum -c --status || { echo "Checksum failed: $1" >&2; exit 1; }
}
download codegen_main-ubuntu2004 53f0c11c2c23c0a153b91bd0acfd34ad6a444896823c7d809e6d7903925a6a6b
download libxls-ubuntu2004.so.gz 2faf86a7aa83bb097df3b4862bf61ed58602fb0691ba0a46de409176eca4ef4b
download dslx_stdlib.tar.gz ce4de2fcf79f960ade7987cbab9c1d1e2e4d2a2be4372aff8f18de69e908554d
chmod +x codegen_main-ubuntu2004
gzip -dkf libxls-ubuntu2004.so.gz
mv -f libxls-ubuntu2004.so libxls-v0.59.0-ubuntu2004.so
tar -xzf dslx_stdlib.tar.gz

driver="$tools/xlsynth/bin/xlsynth-driver"
if [[ ! -x "$driver" ]]; then
    toolchain=nightly-2026-09-01
    rustup toolchain install "$toolchain" --profile minimal
    # The rpath lets xlsynth-driver find libxls without LD_LIBRARY_PATH.
    RUSTFLAGS="-C link-args=-Wl,-rpath,$tools/xls" \
    XLS_DSO_PATH="$tools/xls/libxls-v0.59.0-ubuntu2004.so" \
    DSLX_STDLIB_PATH="$tools/xls/xls/dslx/stdlib" \
    cargo "+$toolchain" install xlsynth-driver --version 0.75.0 --locked --root "$tools/xlsynth"
fi

asap7_lib_url=https://github.com/The-OpenROAD-Project/asap7sc7p5t_28
asap7_files_7z=("asap7sc7p5t_AO_RVT_TT_nldm_211120.lib.7z"
                "asap7sc7p5t_OA_RVT_TT_nldm_211120.lib.7z"
                "asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.7z"
                "asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.7z"
                "asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib.7z");

mkdir -p "$tools/asap7"
pushd "$tools/asap7"
    if [[ ! -x .git ]]; then
        git clone --recursive $asap7_lib_url .
        for comp_file in "${asap7_files_7z[@]}"; do
            7z x "LIB/NLDM/$comp_file" -o"$proj_root"/lib/
        done
    fi
popd

orfs_url=https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts
mkdir -p "$tools/orfs"
pushd "$tools"/orfs
    if [[ ! -x .git ]]; then
        git clone --recursive $orfs_url .
    fi
    ./build_openroad.sh --local
popd

"$driver" version
"$tools/xls/codegen_main-ubuntu2004" --version
yosys -V
