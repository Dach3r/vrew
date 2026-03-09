# 🍺 Vrew

<img width="405" height="220" alt="image" src="https://github.com/user-attachments/assets/1e5233ef-720b-4293-82a4-19021c4cf891" />

A native macOS menu bar app for managing Homebrew services.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)

---

## Install

1. Download `vrew.zip` from the [latest release](../../releases/latest)
2. Unzip and move `vrew.app` to `/Applications`
3. Remove the Gatekeeper quarantine flag:
```bash
xattr -cr /Applications/vrew.app
```
4. Open `vrew.app` — the 🍺 icon appears in your menu bar

> Requires macOS 13 Ventura or later and [Homebrew](https://brew.sh) installed.

---

## Features

- Lists all `brew services` with live status
- Start, Stop, Restart any service with one click
- Refreshes automatically every time you open the popover
- Supports Apple Silicon and Intel Macs

---

## Build from source

```bash
git clone https://github.com/youruser/vrew
cd vrew
bash scripts/build.sh
```

Output: `build/vrew.app` and `build/vrew.zip`

Requires Xcode 15+ and `xcpretty` (optional, `gem install xcpretty`).

---

## Release a new version

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions builds and publishes the release automatically.

---

## License

MIT
