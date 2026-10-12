#!/usr/bin/env bash

# Require root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./install.sh)"
  exit 1
fi

PREFIX="/usr/local"
BIN="$PREFIX/bin"
SHARE="$PREFIX/share/phub-cli"

echo "▶ Installing phub-cli"

#dependency checks
deps=(bash mpv fzf yt-dlp python3)
for d in "${deps[@]}"; do
  if ! command -v "$d" >/dev/null; then
    echo "❌ Missing dependency: $d"
    exit 1
  fi
done

# python dependency check (bs4 + requests); fall back to a private venv
PYBIN="python3"
if ! python3 -c "import bs4, requests" >/dev/null 2>&1; then
  echo "▶ Python deps missing system-wide, creating private venv in $SHARE/venv"
  mkdir -p "$SHARE"
  if [ ! -x "$SHARE/venv/bin/python3" ]; then
    python3 -m venv "$SHARE/venv" || { echo "❌ Could not create venv"; exit 1; }
  fi
  "$SHARE/venv/bin/pip" install --quiet --upgrade pip >/dev/null 2>&1
  if [ -f requirements.txt ]; then
    pip_target=(-r requirements.txt)
  else
    pip_target=(beautifulsoup4 requests)
  fi
  if ! "$SHARE/venv/bin/pip" install --quiet "${pip_target[@]}"; then
    echo "❌ Could not install python dependencies (beautifulsoup4, requests)"
    echo "   Arch: sudo pacman -S python-beautifulsoup4 python-requests"
    echo "   Debian/Ubuntu: sudo apt install python3-bs4 python3-requests"
    exit 1
  fi
  PYBIN="$SHARE/venv/bin/python3"
fi

# --- Install files ---
echo "▶ Creating directories"
mkdir -p "$BIN"
mkdir -p "$SHARE"

echo "▶ Copying modules"
rm -rf "$SHARE/modules"
cp -r modules "$SHARE/"

echo "▶ Installing binary"
cp phub-cli "$BIN/phub-cli"

echo "▶ Patching module path"
#sed -i "s|^DIR=.*|DIR=\"$SHARE\"|" "$BIN/phub-cli"
if sed --version >/dev/null 2>&1; then
  # GNU sed
  sed -i "s|^DIR=.*|DIR=\"$SHARE\"|" "$BIN/phub-cli"
else
  # BSD sed (macOS)
  sed -i '' "s|^DIR=.*|DIR=\"$SHARE\"|" "$BIN/phub-cli"
fi

echo "▶ Setting permissions"
chmod +x "$BIN/phub-cli"
chmod +x "$SHARE/modules/"*.sh
chmod +x "$SHARE/modules/"*.py

echo "▶ Pointing python modules at $PYBIN"
for f in "$SHARE/modules/"*.py; do
  if sed --version >/dev/null 2>&1; then
    sed -i "1s|^#!.*|#!$PYBIN|" "$f"
  else
    sed -i '' "1s|^#!.*|#!$PYBIN|" "$f"
  fi
done

# Save version hash for update checks
echo "▶ Saving version info"
if command -v git >/dev/null && [ -d ".git" ]; then
    git rev-parse HEAD > "$SHARE/.version"
else
    echo "unknown" > "$SHARE/.version"
fi

echo
echo "✅ phub-cli installed successfully"
echo "▶ Run it with: phub-cli"
