<p align="center">
<br>
<a href="http://makeapullrequest.com"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg"></a>
<img src="https://img.shields.io/badge/os-linux-brightgreen">
<img src="https://img.shields.io/badge/os-mac-yellowgreen">
<img src="https://img.shields.io/badge/interface-terminal-blue">
<img src="https://img.shields.io/badge/player-mpv-red">
<br>
</p>

<h1 align="center">
phub-cli
</h1>

<h3 align="center">
A terminal-based video browser inspired by ani-cli.<br>
Browse, search, and stream directly from <a href="https://www.pornhub.com/">pornhub.com</a> — no browser required.
</h3>

<p align="center">
<b>Made with lust.</b><br>
</p>

---

## Showcase

```bash
phub-cli
```

## Features

- Browse categories using fzf
- Search videos by keyword
- Paginated results for large categories and searches
- Instant streaming via mpv
- Direct stream extraction using yt-dlp
- Download videos in multiple qualities (1080p, 720p, 480p, 360p)
- Open videos directly in your default browser
- ani-cli–style navigation flow
- Graceful handling of broken or unavailable videos
- Built-in auto-updater to silently check for and install new releases
- Clean terminal UI with interactive menus
- No browser required for playback
- No accounts, no tracking, no clutter


---

## Table of Contents


- [Installation](#installation)
- [Dependencies](#dependencies)
- [Terminal playback](#terminal-playback)
- [Usage](#usage)
- [Tips](#tips)
- [Fixing errors](#fixing-errors)
- [Technical Notes](#technical-notes)
- [Disclaimer](#disclaimer)

## Installation

From source (recommended)

```bash
git clone https://github.com/curtosis-org/phub-cli.git
cd phub-cli
chmod +x install.sh
sudo ./install.sh
```

After installation, run from anywhere:

```bash
phub-cli
```

## Dependencies

### System packages

| Tool | Why |
| --- | --- |
| bash | the CLI itself |
| mpv | playback (in-terminal or windowed) |
| fzf | interactive menus |
| yt-dlp | downloads, and a fallback stream resolver |
| curl | CDN checks |
| python3 | the scraping modules |

### Python packages

Listed in [`requirements.txt`](requirements.txt) — `requests` and
`beautifulsoup4`. Exact tested versions are in `requirements-lock.txt`.

`install.sh` handles them for you: if the system python already imports both it
uses that, otherwise it creates a private venv in
`/usr/local/share/phub-cli/venv`, installs `requirements.txt` into it, and
points the module shebangs there. Nothing is installed into the system python,
so there is no `externally-managed-environment` (PEP 668) error on macOS or
recent Debian/Ubuntu.

To set the venv up by hand:

```bash
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
```

### Arch Linux

```bash
sudo pacman -S mpv fzf yt-dlp curl python python-beautifulsoup4 python-requests
```

### Debian / Ubuntu

```bash
sudo apt install mpv fzf yt-dlp curl python3 python3-bs4 python3-requests
```

### Fedora

```bash
sudo dnf install mpv fzf yt-dlp curl python3 python3-beautifulsoup4 python3-requests
```

### macOS (Homebrew)

```bash
brew install mpv fzf yt-dlp curl python
```

Do not run `pip3 install` on Homebrew python — it is externally managed and
will refuse. Let `install.sh` build the venv instead.

Optional, for a real picture instead of coloured blocks:

```bash
brew install --cask kitty      # or: sudo pacman -S kitty / sudo apt install kitty
```

## Terminal playback

Video renders inside the terminal by default:

| Terminal | Output |
| --- | --- |
| Kitty (`TERM=xterm-kitty`) | `--vo=kitty`, the graphics protocol — sharp |
| everything else | `--vo=tct`, coloured half-blocks (256 colours outside truecolor terminals) |

Override with `PHUB_VO`:

```bash
PHUB_VO=window phub-cli    # a normal mpv window
PHUB_VO=tct phub-cli       # force blocks even in Kitty
PHUB_VO=kitty phub-cli     # force the kitty protocol
```

## Usage

```bash
phub-cli
```
You will be presented with:

- Browse categories

- Search videos

- Quit

Navigation is entirely keyboard-driven using fzf.

## Tips

Optional toggles:

```bash
# Enable blinking title on the home screen
PHUBCLI_BLINK=1 phub-cli

# Disable the custom fzf theme
PHUBCLI_FZF_THEME=0 phub-cli
```

## Fixing errors
If a video fails to play:

- It may be geo-blocked
- It may be removed
- It may require cookies/login

phub-cli will:
- detect fast failures 
- return you to the selection menu

allow retry or navigation without crashing

Ensure your dependencies are up to date:
```bash
yt-dlp -U
```

## Technical Notes

- Uses yt-dlp to resolve stream URLs before playback
- mpv is used only as a player, not as a scraper
- Input is explicitly read from /dev/tty to avoid fzf / mpv stdin conflicts
- No PhantomJS dependency
- No virtualenv required
- No downloads unless you modify the scripts yourself

## Supported Platforms

Tier 1 (tested)

- Linux (Arch, Debian, Fedora)
- macOS

Tier 2 (may work)

- WSL
- Termux (manual setup)

Windows, iOS, and consoles are not officially supported.

## Disclaimer
This project does not host, store, or distribute any media.
It only provides a terminal interface to publicly accessible content.

Use responsibly and in accordance with your local laws.








**Inspired by ani-cli. Built for terminals. Powered by curiosity and lust.**

# pcli_fixed
# pcli_fixed
