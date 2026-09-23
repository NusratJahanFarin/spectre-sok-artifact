# tools/

This directory holds the five Spectre-detection tools the benchmarks in
`bench/` are evaluated against. **None of the tool binaries/images are
committed to this repo** — several are multi-GB and/or have their own
licenses — only the exact build recipe or pinned release needed to
reproduce each one.

| Tool | Driven by | Obtained via | Dir |
|------|-----------|--------------|-----|
| SpecFuzz | `scripts/run_specfuzz.sh` | Docker (build locally) | (specfuzz/) |
| KleeSpectre | `scripts/run_kleespectre.sh` | Docker (build locally) | (kleespectre/) |
| BinSec/Haunted | `scripts/binsec/run_binsec.sh` | Prebuilt Docker image, Zenodo | (binsec/) |
| Pitchfork | `scripts/run_pitchfork.py` | pypy3 virtualenv | (pitchfork/) |
| lmtest | `scripts/run_lmtest.sh` | virtualenv | (lmtest/) |

