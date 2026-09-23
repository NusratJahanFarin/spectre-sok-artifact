#include "libsodium/include/sodium.h"
#include <stdlib.h>
#include <string.h>

#define KEY_LEN crypto_onetimeauth_KEYBYTES       /* 32 bytes */
#define MSG_LEN 256
#define MAC_LEN crypto_onetimeauth_BYTES          /* 16 bytes */

unsigned char mac[MAC_LEN];       // public
unsigned char m[MSG_LEN];   // secret
unsigned long long mlen = MSG_LEN; // public
unsigned char k[KEY_LEN];   // secret


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

    /* Read message from user */
    mlen = strlen(argv[1]);
    if (mlen > MSG_LEN)
        mlen = MSG_LEN;

    memcpy(m, argv[1], mlen);

    /* Compute Poly1305 MAC */
    crypto_onetimeauth_poly1305(mac, m, mlen, k);

    return 0;
}
