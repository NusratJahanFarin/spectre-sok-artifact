#include "libsodium/include/sodium.h"
#include <stdlib.h>
#include <string.h>
#define KEY_LEN crypto_secretbox_KEYBYTES                    /* 32 bytes */
#define MSG_LEN 256
#define NONCE_LEN crypto_secretbox_NONCEBYTES                /* 24 */
#define CIPHERTEXT_LEN (crypto_secretbox_MACBYTES + MSG_LEN)

unsigned char c[CIPHERTEXT_LEN];   // public
unsigned char m[MSG_LEN];    // secret
unsigned long long mlen = MSG_LEN; // public
unsigned char n[NONCE_LEN];  // public
unsigned char k[KEY_LEN];    // secret


int main(int argc, char **argv) {
    if (argc != 2) {
        printf("USAGE: %s <message>\n", argv[0]);
        return 1;
    }

    /* Initialize libsodium */
    if (sodium_init() < 0) {
        return 1;
    }

    /* Fixed secret key */
    memset(k, 0x42, sizeof k);

    /* Fixed nonce */
    memset(n, 0x00, sizeof n);

    /* Read message from user */
    mlen = strlen(argv[1]);
    if (mlen > MSG_LEN)
        mlen = MSG_LEN;

    memcpy(m, argv[1], mlen);

    /* Run encryption */
    crypto_secretbox(c, m, mlen, n, k);

    return 0;
}
