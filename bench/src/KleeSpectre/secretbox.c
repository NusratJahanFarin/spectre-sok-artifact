#include "secretbox_wrapper.c"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>


#define crypto_secretbox_KEYBYTES 32
#define crypto_secretbox_NONCEBYTES 24
#define crypto_secretbox_MACBYTES 16

#define KEY_LEN crypto_secretbox_KEYBYTES                    /* 32 bytes */
#define MSG_LEN 256
#define NONCE_LEN crypto_secretbox_NONCEBYTES                /* 24 */
#define CIPHERTEXT_LEN (crypto_secretbox_MACBYTES + MSG_LEN)

unsigned char c[CIPHERTEXT_LEN];   // public
unsigned char m[MSG_LEN];    // secret
unsigned long long mlen = MSG_LEN; // public
unsigned char n[NONCE_LEN];  // public
unsigned char k[KEY_LEN];    // secret

int main() {
    klee_make_symbolic(m, sizeof(m), "secret_message");
    klee_make_symbolic(k, sizeof(k), "secret_key");
    crypto_secretbox(c, m, mlen, n, k);

    return 0;
}
