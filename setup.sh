#!/usr/bin/env bash

# Copyright (c) 2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# Installs the pinned tools; prerequisites are in README.md.

# The driver must support the XLS release. ORFS pins OpenROAD, Yosys and ASAP7.
xls_version=v0.59.0
xls_codegen_sha256=53f0c11c2c23c0a153b91bd0acfd34ad6a444896823c7d809e6d7903925a6a6b
xls_libxls_sha256=2faf86a7aa83bb097df3b4862bf61ed58602fb0691ba0a46de409176eca4ef4b
xls_stdlib_sha256=ce4de2fcf79f960ade7987cbab9c1d1e2e4d2a2be4372aff8f18de69e908554d
xlsynth_driver_version=0.75.0
rust_toolchain=nightly-2026-09-01
orfs_commit=202c7fccbce32e86db899c54b0a0f0484f869cc3

for command in cc curl git make protoc rustup bazelisk; do
    command -v "$command" >/dev/null || { echo "Cannot find $command; see README.md" >&2; exit 1; }
done

proj_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tools="$proj_root/tools"
mkdir -p "$tools/xls"
cd "$tools/xls"

xls_url=https://github.com/xlsynth/xlsynth/releases/download/$xls_version
download() {
    [[ -f $1 ]] && echo "$2  $1" | sha256sum -c --status && return
    echo "Downloading $1"
    curl -fL "$xls_url/$1" -o "$1"
    echo "$2  $1" | sha256sum -c --status || { echo "Checksum failed: $1" >&2; exit 1; }
}
download codegen_main-ubuntu2004 "$xls_codegen_sha256"
download libxls-ubuntu2004.so.gz "$xls_libxls_sha256"
download dslx_stdlib.tar.gz "$xls_stdlib_sha256"
chmod +x codegen_main-ubuntu2004
libxls="libxls-$xls_version-ubuntu2004.so"
[[ -f $libxls ]] || { gzip -dc libxls-ubuntu2004.so.gz > "$libxls.tmp" && mv "$libxls.tmp" "$libxls"; }
tar -xzf dslx_stdlib.tar.gz

driver="$tools/xlsynth/bin/xlsynth-driver"
driver_stamp="$tools/xlsynth/.versions"
driver_want="$xlsynth_driver_version $xls_version $rust_toolchain"
if [[ ! -x "$driver" ]] || [[ "$(cat "$driver_stamp" 2>/dev/null)" != "$driver_want" ]]; then
    rustup toolchain install "$rust_toolchain" --profile minimal
    # The rpath lets xlsynth-driver find libxls without LD_LIBRARY_PATH.
    RUSTFLAGS="-C link-args=-Wl,-rpath,$tools/xls" \
    XLS_DSO_PATH="$tools/xls/$libxls" \
    DSLX_STDLIB_PATH="$tools/xls/xls/dslx/stdlib" \
    cargo "+$rust_toolchain" install xlsynth-driver --version "$xlsynth_driver_version" \
        --locked --force --root "$tools/xlsynth"
    echo "$driver_want" > "$driver_stamp"
fi

# ORFS's CORNER=TC libraries.
orfs_libs=(asap7sc7p5t_AO_RVT_TT_nldm_211120.lib.gz
           asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz
           asap7sc7p5t_OA_RVT_TT_nldm_211120.lib.gz
           asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib
           asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz)

orfs_url=https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts
mkdir -p "$tools/orfs" "$proj_root/lib"
pushd "$tools/orfs"
    [[ -d .git ]] || git clone "$orfs_url" .
    git cat-file -e "$orfs_commit^{commit}" 2>/dev/null || git fetch -q origin
    git checkout -q "$orfs_commit"
    rm -f "$proj_root"/lib/*.lib
    for lib in "${orfs_libs[@]}"; do
        zcat -f "flow/platforms/asap7/lib/NLDM/$lib" > "$proj_root/lib/${lib%.gz}"
    done
    # Also checks out the submodules.
    ./build_openroad.sh --local
popd

echo
echo "Installed tool versions:"
echo "  XLS release:       $xls_version"
echo "  XLS codegen:       $("$tools/xls/codegen_main-ubuntu2004" --version 2>&1 | head -1)"
echo "  xlsynth-driver:    $("$driver" version 2>&1 | head -1)"
echo "  Rust toolchain:    $rust_toolchain"
echo "  ORFS commit:       $(git -C "$tools/orfs" rev-parse HEAD)"
echo "  OpenROAD commit:   $(git -C "$tools/orfs/tools/OpenROAD" rev-parse HEAD)"
echo "  OpenROAD:          $("$tools/orfs/tools/install/OpenROAD/bin/openroad" -version 2>&1 | head -1)"
echo "  Yosys:             $("$tools/orfs/tools/install/yosys/bin/yosys" -V 2>&1 | head -1)"
