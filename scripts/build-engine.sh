#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_DIR="$REPO_ROOT/apps/macos/Sources/Bridge"
# The VnkeyC SwiftPM target's header lives here (path Sources/VnkeyC,
# publicHeadersPath include). Both are gitignored build artifacts, so the
# dirs may not exist on a fresh checkout — create them.
VNKEYC_INCLUDE="$REPO_ROOT/apps/macos/Sources/VnkeyC/include"

echo "==> Building vnkey-ffi (release)..."
cd "$REPO_ROOT"
cargo build --release -p vnkey-ffi

echo "==> Generating C header with cbindgen..."
if ! command -v cbindgen &>/dev/null; then
    echo "cbindgen not on PATH — installing / reshimming..."
    cargo install cbindgen
    command -v asdf &>/dev/null && asdf reshim rust 2>/dev/null || true
fi
mkdir -p "$VNKEYC_INCLUDE"
cbindgen "$REPO_ROOT/crates/vnkey-ffi" \
    --config "$REPO_ROOT/crates/vnkey-ffi/cbindgen.toml" \
    --output "$VNKEYC_INCLUDE/phacius_vnkey_engine.h"

echo "==> Copying static lib (Bridge links it)..."
cp "$REPO_ROOT/target/release/libvnkey_ffi.a" "$BRIDGE_DIR/"

echo "==> Done. Header in $VNKEYC_INCLUDE, lib in $BRIDGE_DIR"
