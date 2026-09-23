# KleeSpectre

Symbolic-execution Spectre detector built on KLEE, with speculation
semantics + cache modelling (Wang, Chattopadhyay, Biswas, Mitra,
Roychoudhury — ACM TOSEM 2020).

Upstream: https://github.com/winter2020/kleespectre

## Build

```bash
cd tools/kleespectre
docker build -t kleespectre .
```

## Run

`scripts/run_kleespectre.sh` only needs `klee` on `PATH` (already true
in this image) and runs it against the pre-linked `.bc` bitcode files in
`bench/binaries/kleespectre/` with:

```
klee -check-div-zero=false -check-overshift=false --search=randomsp \
-enable-speculative -max-sew=200
```

From the artifact root, bind-mount the repo and run the script directly:

```bash
docker run --rm -it -v "$(pwd)":/artifact -w /artifact kleespectre \
    ./scripts/run_kleespectre.sh
```

The script passes KLEE's own `--output-dir=results/kleespectre/<bench>`
per benchmark (rather than letting KLEE fall back to its default
auto-numbered `klee-out-N/`, which is fragile to map back to benchmark
names). Check `results/kleespectre/<bench>/messages.txt` for the
`Spectre found: N` summary line. KleeSpectre
doesn't produce a CSV or other summary file; that log line is the
result.
