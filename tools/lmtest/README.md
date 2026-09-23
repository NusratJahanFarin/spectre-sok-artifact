# lmtest

LMTEST — a leakage-model testing framework for cryptographic
implementations, built on the LMSPEC DSL and on top of Microsoft's
Revizor codebase (Barthe, Böhme, Cauligi, Chuengsatiansup, Genkin,
Guarnieri, Mateos Romero, Schwabe, Wu, Yarom — CCS'24, Distinguished
Paper).

Upstream: https://github.com/hw-sw-contracts/leakage-model-testing
Paper: https://arxiv.org/abs/2402.00641

## Setup

```bash
cd tools/lmtest
./setup.sh
```

Once those are on `PATH`, build the target libraries LMTEST tests
against:

```bash
cd tools/lmtest/leakage-model-testing/targets
./build.sh
```

Sanity-check the install:

```bash
cd tools/lmtest/leakage-model-testing
source ../venv/bin/activate
./run.sh -h
./run.sh -l          # should list the built libraries/functions
```

## Run

`scripts/run_lmtest.sh` calls `./run.sh` with a relative path, so it
needs to be invoked with the LMTEST checkout as the working directory:

```bash
cd tools/lmtest/leakage-model-testing
source ../venv/bin/activate
../../../scripts/run_lmtest.sh
```

