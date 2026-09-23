#include "libsodium/include/sodium.h"
#include <stdio.h>
#include <stdlib.h>

#define IN_SIZE 200


volatile uint8_t temp;
char out[crypto_hash_sha512_BYTES];
char in[IN_SIZE] = {0};


int main(int argc, char **argv) {
    if (argc != 2) { printf("USAGE: %s <input_file>\n", argv[0]); exit(1); }
    FILE *f = fopen(argv[1], "r");
    if (!f) { fprintf(stderr, "Failed to open input file.\n"); exit(1); }

    size_t got_in = fread(in, 1, IN_SIZE, f);
    fclose(f);

    if (got_in < IN_SIZE) {
        fprintf(stderr, "Input file too short (need %d bytes).\n", IN_SIZE);
        return 1;
    }

    crypto_hash_sha512((unsigned char*)out, (unsigned char*)in, IN_SIZE);
    return 0;
}
