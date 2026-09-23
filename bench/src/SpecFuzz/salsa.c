#include <sodium.h>
#include <stdio.h>
#include <stdlib.h>

#define SALSA_DATA_SIZE 64
#define SALSA_KEY_SIZE 32

char c[SALSA_DATA_SIZE];
char m[SALSA_DATA_SIZE];
char k[SALSA_KEY_SIZE];
unsigned char nonce[crypto_stream_salsa20_NONCEBYTES];

int main(int argc, char **argv) {
    if (argc != 2) { printf("USAGE: %s <input_file>\n", argv[0]); exit(1); }
    FILE *f = fopen(argv[1], "r");
    if (!f) { fprintf(stderr, "Failed to open input file.\n"); exit(1); }

    size_t got_m     = fread(m, 1, SALSA_DATA_SIZE, f);
    size_t got_k     = fread(k, 1, SALSA_KEY_SIZE, f);
    size_t got_nonce = fread(nonce, 1, crypto_stream_salsa20_NONCEBYTES, f);
    fclose(f);

    size_t needed = SALSA_DATA_SIZE + SALSA_KEY_SIZE + crypto_stream_salsa20_NONCEBYTES;
    if (got_m + got_k + got_nonce < needed) {
        fprintf(stderr, "Input file too short (need %zu bytes).\n", needed);
        return 1;
    }

    crypto_stream_xsalsa20_xor(c, m, SALSA_DATA_SIZE, nonce, k);
    return 0;
}
