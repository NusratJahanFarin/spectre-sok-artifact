#include "poly1305_wrapper.c"
#include <string.h>
#include <stdio.h>

#define crypto_onetimeauth_BYTES 16
#define crypto_onetimeauth_KEYBYTES 32

#define MAC_LEN crypto_onetimeauth_BYTES
#define KEY_LEN crypto_onetimeauth_KEYBYTES

#define KEY_LEN crypto_onetimeauth_KEYBYTES
#define MSG_LEN 256
#define MAC_LEN crypto_onetimeauth_BYTES

unsigned char mac[MAC_LEN];        // public
unsigned char m[MSG_LEN];          // secret
unsigned long long mlen = MSG_LEN; // public
unsigned char k[KEY_LEN];          // secret

int main() {
    klee_make_symbolic(m, sizeof(m), "secret_message");
    klee_make_symbolic(k, sizeof(k), "secret_key");
    crypto_onetimeauth_poly1305(mac, m, mlen, k);

    return 0;
}

