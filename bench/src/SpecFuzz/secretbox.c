#include "libsodium/include/sodium.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define KEY_LEN    crypto_secretbox_KEYBYTES     /* 32 */
#define NONCE_LEN  crypto_secretbox_NONCEBYTES    /* 24 */
#define MAC_LEN    crypto_secretbox_MACBYTES      /* 16 */
#define CT_MAX     256

unsigned char ct[CT_MAX];                 /* attacker-controlled ciphertext+MAC */
unsigned char m[CT_MAX];                  /* decrypted output buffer */
unsigned char n[NONCE_LEN];               /* fixed nonce, doesn't need to vary */
unsigned char k[KEY_LEN];                 /* fixed key */

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

    size_t ct_len = fread(ct, 1, CT_MAX, f);
    fclose(f);

    if (ct_len < MAC_LEN) {
        fprintf(stderr, "Input too short (need at least %d bytes for MAC).\n", MAC_LEN);
        return 1;
    }

    crypto_secretbox_open(m, ct, ct_len, n, k);
    return 0;
}
