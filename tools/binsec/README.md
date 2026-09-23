# BinSec/Haunted

Relational symbolic execution Spectre detector at the binary level
(Daniel, Bardin, Rezk — "Hunting the Haunter", NDSS'21). Distributed by
the authors as a prebuilt Docker image only — there is no Dockerfile to
build from source, so this artifact just pins the exact release.

Paper / tool page: https://binsec.github.io/haunted/
Zenodo record: https://zenodo.org/records/4442337
DOI: 10.5281/zenodo.4442337

## Get the image

```bash
cd tools/binsec
./download.sh         
docker load -i binsec-haunted.tar
docker images | grep haunted   
```

## Run

`scripts/binsec/run_binsec.sh` `cd`s into each module directory
(`litmus-pht/`, `litmus-stl/`, `tea/`, `secretbox/`, ...) and runs
`python expes.py`, which in turn shells out to the `binsec` binary — so
run it from *inside* the container, with the artifact root bind-mounted:

```bash
docker run --rm -it -v "$(pwd)/../..":/artifact -w /artifact/scripts/binsec \
    <image-name-from-docker-images> bash
./run_binsec.sh
```

Run `scripts/binsec/collect_results.sh` after `run_binsec.sh` finishes —
it copies each of those into `results/binsec/<module>.csv`

