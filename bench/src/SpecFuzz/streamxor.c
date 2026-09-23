#include "sodium.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define KEY_LEN   crypto_stream_KEYBYTES     /* 32 */
#define NONCE_LEN crypto_stream_NONCEBYTES   /* 24 */
#define MSG_LEN   123

unsigned char key[KEY_LEN];
unsigned char nonce[NONCE_LEN];
unsigned char message[MSG_LEN];
unsigned char out[MSG_LEN];

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("USAGE: %s <input_file>\n", argv[0]);
        exit(1);
    }
    FILE *f = fopen(argv[1], "r");
    if (!f) {
        fprintf(stderr, "Failed to open input file.\n");
        exit(1);
    }

    size_t got_key   = fread(key, 1, KEY_LEN, f);
    size_t got_nonce = fread(nonce, 1, NONCE_LEN, f);
    size_t got_msg   = fread(message, 1, MSG_LEN, f);
    if (ferror(f)) {
        fclose(f);
        fprintf(stderr, "Failed to read input file.\n");
        return 1;
    }
    fclose(f);

    size_t total_needed = KEY_LEN + NONCE_LEN + MSG_LEN;
    if (got_key + got_nonce + got_msg < total_needed) {
        fprintf(stderr, "Input file too short (need %zu bytes).\n", total_needed);
        return 1;
    }

    crypto_stream_xor(out, message, MSG_LEN, nonce, key);
    return 0;
}
