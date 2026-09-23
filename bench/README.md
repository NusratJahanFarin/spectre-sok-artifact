# bench/

Benchmark sources and compiled binaries shared across all five tools.

```
bench/
├── src/
│   ├── common/         .c sources for binsec/haunted, pitchfork and LMTest
│   ├── SpecFuzz/       SpecFuzz specific variants (harness changes
│   │                   needed for SpecFuzz's patched-LLVM + honggfuzz flow)
│   └── KleeSpectre/    KleeSpectre specific variants (KLEE-friendly
│                        wrappers, e.g. *_wrapper.c symbolic entry points)
└── binaries/           compiled targets, built by src/common/build.sh
     ├── kleespectre/   compiled targets built by src/KleeSpectre/build.sh  
```

## src/

- common — the canonical, tool agnostic C sources: the Spectre v1
  (`spectrev1.c`, `spectrev1_masked.c`) and Spectre v4 (`spectrev4.c`)
  litmus tests, `tea.c` (+ encrypt wrappers), and the libsodium
  primitives (`secretbox`, `poly1305`, `salsa`, `ed25519`, `sha512`,
  `streamxor`). binsec/haunted, Pitchfork and LMTest build directly from
  these. `build.sh` is the script that produced everything under
  `bench/binaries/`.
- SpecFuzz and KleeSpectre — per-tool copies of the same benchmarks, modified only where that tool's build/instrumentation requires it. Where a tool doesn't need a modified copy, it builds from common/ instead.

## binaries/

All binaries are produced by `src/common/build.sh`, which:
- checks for `clang`, `gcc`, and a prebuilt libsodium (32- and 64-bit,
  expected at `src/common/libsodium32/lib/libsodium.a` and
  `libsodium64/lib/libsodium.a`
- compiles 32-bit targets (`*_32`) with
  `-O0 -m32 -march=i386 -static -g -fno-stack-protector` for
  binsec/haunted (also symlinked into `scripts/binsec/<module>/programs/`);
- compiles the plain 64-bit targets with
  `-O0 -m64 -static -g -fno-stack-protector -fno-pie -fno-pic`.

Regenerating everything: run `src/common/build.sh` from the repo root
(it resolves paths relative to itself, so it can be invoked from
anywhere). It requires the 32- and 64-bit libsodium builds to already
be in place at `src/common/libsodium32/lib/libsodium.a` and
`src/common/libsodium64/lib/libsodium.a`.
