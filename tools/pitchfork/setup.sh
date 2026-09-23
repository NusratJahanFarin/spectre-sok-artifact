#!/bin/bash
# Clones cdisselkoen/pitchfork and runs ITS OWN setup.sh, which does the
# real work: clones the patched angr fork (cdisselkoen/angr, branch
# more-hooks), symlinks it in as `angr` (shadowing any pip-installed
# angr), creates a pypy3 venv, and installs requirements.txt.
# Safe to re-run: skips the clone if it's already there; upstream's own
# setup.sh re-clones angr-git each time, so re-running this will refresh
# that fork too.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v pypy3 >/dev/null 2>&1; then
    echo "[!] pypy3 not found on PATH. Install it first (e.g. 'brew install pypy3'" >&2
    echo "    or your distro's pypy3 package), then re-run this script." >&2
    exit 1
fi

if [ ! -d pitchfork ]; then
    echo "[*] Cloning cdisselkoen/pitchfork..."
    git clone https://github.com/cdisselkoen/pitchfork
else
    echo "[=] pitchfork already cloned, skipping clone."
fi

cd pitchfork
echo "[*] Running upstream's own setup.sh (clones angr fork, creates venv, installs requirements)..."
./setup.sh

echo "[✓] Pitchfork environment ready."
echo "    Activate with: source $SCRIPT_DIR/pitchfork/venv/bin/activate"
echo "    Run with:      PYTHONPATH=$SCRIPT_DIR/pitchfork pypy3 scripts/run_pitchfork.py --auto"
echo "    (run that last command from the artifact root)"
