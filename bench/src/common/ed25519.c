#include "libsodium/include/sodium.h"
#include <string.h>
#include <stdio.h>


unsigned char key[crypto_sign_ed25519_SECRETKEYBYTES] = {0};
unsigned char message[32] = {0};
unsigned char signed_message[sizeof(message) + crypto_sign_ed25519_BYTES];
unsigned long long signed_message_len;

int main() {
    crypto_sign_ed25519(signed_message, &signed_message_len, message, sizeof(message), key);
    return 0;
}

