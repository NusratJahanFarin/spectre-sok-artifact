# Pitchfork

Speculative symbolic execution on top of angr. Runs
as a plain Python tool inside a pypy3 virtualenv — no Docker.


## Setup

The repo ships its own `setup.sh` that does the whole thing correctly —
clones the patched angr fork, symlinks it over the pip-installed one,
creates the pypy3 venv, and installs `requirements.txt`:

```bash
cd tools/pitchfork
./setup.sh
```

which is a thin wrapper that clones upstream into `tools/pitchfork/pitchfork/`
and then runs *its* `setup.sh` from inside that checkout — equivalent to
doing this by hand:

```bash
git clone https://github.com/cdisselkoen/pitchfork
cd pitchfork
git clone https://github.com/cdisselkoen/angr.git -b more-hooks angr-git
ln -s angr-git/angr angr        # shadows any pip-installed angr
pypy3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
mkdir -p results
```

Requires `pypy3` on `PATH` first (`brew install pypy3` on Mac, or your
distro's pypy3 package) — Pitchfork is only tested against PyPy 7.0–7.1
(Python 3.6.1), though upstream says other interpreters should work.

Upstream's README also suggests doing a normal `pip install angr==8.19.4.5`
*before* any of this, purely to let pip pull in angr's non-Python system
dependencies (z3, pyvex native libs, etc.) — you never actually use that
angr install, since the symlink above shadows it, but it's a useful step
if `pip install -r requirements.txt` fails on missing native libraries.

## Run

`scripts/run_pitchfork.py` does `from pitchfork import angr, funcEntryState,
...` and `from abstractdata import ...` — those are top-level modules in
the pitchfork checkout itself (`pitchfork.py`, `abstractdata.py` at repo
root), not an installed package, so it needs that checkout on
`PYTHONPATH`. It also loads binaries via relative paths like
`bench/binaries/spectrev1_clang_O0`, so it must run from the artifact
root:

```bash
source tools/pitchfork/pitchfork/venv/bin/activate
cd <artifact-root>
PYTHONPATH=tools/pitchfork/pitchfork pypy3 scripts/run_pitchfork.py --auto
```

Results are appended to `results/pitchfork/pitchfork_results.csv` (via
`--auto`, all benchmarks) or `results/pitchfork/bench_analysis_results.csv`
(single `--test` runs).
