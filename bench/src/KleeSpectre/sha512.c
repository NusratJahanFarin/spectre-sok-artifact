#include "sodium.h"
#include <string.h>
#include <stdio.h>
#include <klee/klee.h>

#define crypto_hash_sha512_BYTES 64

char out[crypto_hash_sha512_BYTES];
char in[32] = {0};

int main() {
    klee_make_symbolic(&in, sizeof(in), "in");
    crypto_hash_sha512(out, in, sizeof(in));
    return 0;
}

