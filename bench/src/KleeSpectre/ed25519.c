#include "sodium.h"
#include <string.h>
#include <stdio.h>
#include <klee/klee.h>


unsigned char key[crypto_sign_ed25519_SECRETKEYBYTES] = {0};
unsigned char message[32] = {0};
unsigned char signed_message[sizeof(message) + crypto_sign_ed25519_BYTES];
unsigned long long signed_message_len;

int main() {
    klee_make_symbolic(key, sizeof(key), "secret_key");
    klee_make_symbolic(message, sizeof(message), "secret_message");
    
    crypto_sign_ed25519(signed_message, &signed_message_len, message, sizeof(message), key);
    return 0;
}

