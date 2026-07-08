#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_DIR="$REPO_ROOT/apps/macos/Sources/Bridge"

echo "==> Building vnkey-ffi (release)..."
cd "$REPO_ROOT"
cargo build --release -p vnkey-ffi

echo "==> Generating C header with cbindgen..."
if ! command -v cbindgen &>/dev/null; then
    echo "cbindgen not found — installing..."
    cargo install cbindgen
fi
cbindgen "$REPO_ROOT/crates/vnkey-ffi" \
    --config "$REPO_ROOT/crates/vnkey-ffi/cbindgen.toml" \
    --output "$BRIDGE_DIR/phacius_vnkey_engine.h"

echo "==> Copying static lib..."
cp "$REPO_ROOT/target/release/libvnkey_ffi.a" "$BRIDGE_DIR/"

echo "==> Done. Header and lib are in $BRIDGE_DIR"
