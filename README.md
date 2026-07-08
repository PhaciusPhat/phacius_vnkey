# phacius_vnkey

Vietnamese input method (IME) for macOS. Type Vietnamese with Telex or VNI using any keyboard — no special hardware required.

- **Telex** and **VNI** input methods
- Smart spell-check — only applies diacritics when the result is a valid Vietnamese syllable
- Auto-restores raw keystrokes for English and other non-Vietnamese words
- Modern and Classic tone placement (`hòa` vs `hoà`)
- Per-app on/off and a global toggle hotkey (`⌃⌥V`)
- Menu-bar status icon; SwiftUI preferences window

### ⬇️ [Download the latest release](https://github.com/PhaciusPhat/phacius_vnkey/releases/latest)

Grab `phacius_vnkey-<version>.dmg`, drag it to Applications, done. No Rust, no toolchain.

**Requires:** macOS 13 Ventura or later · Apple Silicon (M-series) Mac.

---

## Install (users)

1. Open the [**latest release**](https://github.com/PhaciusPhat/phacius_vnkey/releases/latest) and download **`phacius_vnkey-<version>.dmg`** under **Assets**.
2. Double-click the downloaded `.dmg`, then drag **phacius_vnkey** onto the **Applications** shortcut in the window that opens.
3. Open **phacius_vnkey** from Applications (or Launchpad). The **VN** icon appears in your menu bar.
4. On first launch macOS asks for **Accessibility** permission — grant it in
   System Settings → Privacy & Security → Accessibility. The keyboard hook
   activates immediately once granted (no restart needed).

> **First launch blocked?** The app is ad-hoc signed, not notarized, so macOS
> may say it's from an "unidentified developer." Right-click (or Control-click)
> **phacius_vnkey** in Applications → **Open** → **Open** again to allow it.
> Alternatively, run once in Terminal:
> `xattr -dr com.apple.quarantine /Applications/phacius_vnkey.app`

---

## Build from source (developers)

### Requirements

| Tool | Version |
|------|---------|
| macOS | 13 Ventura or later |
| Xcode Command Line Tools | 15+ |
| Rust | 1.70+ (via [rustup](https://rustup.rs) or [asdf](https://asdf-vm.com)) |
| cbindgen | latest (`cargo install cbindgen`) |


### 1. Clone the repo

```bash
git clone https://github.com/PhaciusPhat/phacius_vnkey.git
cd phacius_vnkey
```

### 2. Install Rust (if needed)

```bash
# via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# or via asdf
asdf plugin add rust
asdf install rust latest
asdf set rust latest        # global
# asdf set rust latest      # project-local (writes .tool-versions)
```

### 3. Install cbindgen

```bash
cargo install cbindgen
```

### 4. Build the Rust engine and generate the C header

```bash
bash scripts/build-engine.sh
```

This compiles `crates/vnkey-ffi` in release mode, runs cbindgen to emit
`apps/macos/Sources/VnkeyC/include/phacius_vnkey_engine.h`, and copies
`libvnkey_ffi.a` into place for the Swift build.

### 5. Build the macOS app

```bash
cd apps/macos
swift build
```

### 6. Run

```bash
.build/debug/VnkeyApp &
```

### 7. Package a distributable `.dmg` (maintainers)

```bash
bash scripts/package-app.sh
```

Builds the Rust engine, a release Swift binary, assembles `phacius_vnkey.app`,
ad-hoc signs it, and writes `dist/phacius_vnkey-<version>.dmg` — the file end
users download. To ship notarized, replace the `codesign --sign -` line in the
script with your Developer ID and run `xcrun notarytool`.

The **VN** icon appears in your menu bar. On first launch macOS will ask for
**Accessibility** permission — grant it in System Settings → Privacy & Security
→ Accessibility. The event tap activates once permission is granted (no restart
needed).

---

## Usage

| Action | How |
|--------|-----|
| Toggle Vietnamese on/off | Click the VN icon → toggle, or press `⌃⌥V` |
| Switch input method | Click the VN icon → Method → Telex / VNI |
| Open preferences | Click the VN icon → Preferences… (or `⌘,`) |

### Telex cheat-sheet

| Keys | Result | Keys | Result |
|------|--------|------|--------|
| `aa` | â | `s` | sắc ´ |
| `aw` | ă | `f` | huyền ` |
| `ee` | ê | `r` | hỏi |
| `oo` | ô | `x` | ngã ~ |
| `ow` | ơ | `j` | nặng · |
| `uw` | ư | `z` | remove tone |
| `dd` | đ | | |

### VNI cheat-sheet

| Key | Effect | Key | Effect |
|-----|--------|-----|--------|
| `1` | sắc | `6` | circumflex (â ê ô) |
| `2` | huyền | `7` | horn (ơ ư) |
| `3` | hỏi | `8` | breve (ă) |
| `4` | ngã | `9` | đ |
| `5` | nặng | `0` | remove tone |

---

## Development

```bash
# Run all Rust tests
cargo test --all

# Lint
cargo clippy --all-targets -- -D warnings

# Swift tests (after build-engine.sh)
cd apps/macos && swift test
```

CI runs `cargo test`, `cargo clippy`, and `swift build` on every push via
`.github/workflows/ci.yml`.

---

## Project layout

```
phacius_vnkey/
├── crates/
│   ├── vnkey-core/      # Pure Rust engine — input methods, validator, tone placement
│   └── vnkey-ffi/       # C ABI wrapper (cbindgen → phacius_vnkey_engine.h)
├── apps/
│   └── macos/           # Swift app — the only OS-specific code
│       ├── Sources/
│       │   ├── VnkeyC/      # Generated C header + static lib
│       │   ├── Bridge/      # Swift wrapper over the C API
│       │   ├── EventTap/    # CGEventTap listener + action synthesizer
│       │   ├── MenuBar/     # NSStatusItem + menu
│       │   ├── Preferences/ # SwiftUI preferences window
│       │   └── VnkeyApp/    # App entry point + AppDelegate
│       └── Package.swift
├── docs/specs/          # Design documents
└── scripts/
    └── build-engine.sh  # Builds Rust, runs cbindgen, copies artifacts
```

---

## License

MIT © 2026 Phacius
