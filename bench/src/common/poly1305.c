#include "libsodium/include/sodium.h"
// #include <sodium.h>
#include <string.h>
#include <stdio.h>

#define KEY_LEN crypto_onetimeauth_KEYBYTES
#define MSG_LEN 256
#define MAC_LEN crypto_onetimeauth_BYTES

unsigned char mac[MAC_LEN];        // public
unsigned char m[MSG_LEN] = {0};          // secret
unsigned long long mlen = MSG_LEN; // public
unsigned char k[KEY_LEN] = {0x42};          // secret

int main() {
    crypto_onetimeauth_poly1305(mac, m, mlen, k);

    return 0;
}

