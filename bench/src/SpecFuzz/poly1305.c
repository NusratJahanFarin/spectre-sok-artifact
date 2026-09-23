#include "libsodium-1.0.18/src/libsodium/include/sodium.h"
#include <string.h>
#include <stdio.h>

#define KEY_LEN crypto_onetimeauth_KEYBYTES
#define MSG_LEN 256
#define MAC_LEN crypto_onetimeauth_BYTES

unsigned char mac[MAC_LEN];        // public
unsigned char m[MSG_LEN];          // secret
unsigned long long mlen = MSG_LEN; // public
unsigned char k[KEY_LEN];          // secret

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("USAGE: %s <input_file>\n", argv[0]);
        exit(1);
    }

    FILE *f = fopen(argv[1], "r");
    if (!f) {
        fprintf(stderr, "Failed to open input file.");
        exit(1);
    }
    
    // Read user input into m
    mlen = fread(m, 1, MSG_LEN, f);  // read up to MSG_MAX bytes
    if (ferror(f) || mlen == 0) {
        fclose(f);
        fprintf(stderr, "Failed to read input file or file empty.\n");
        return 1;
    }
    fclose(f);

    crypto_onetimeauth_poly1305(mac, m, mlen, k);

    return 0;
}

