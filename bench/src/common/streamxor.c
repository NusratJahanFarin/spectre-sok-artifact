#include "libsodium/include/sodium.h"
#include <string.h>
#include <stdio.h>

#define crypto_stream_KEYBYTES 32
#define crypto_stream_NONCEBYTES 24

char key[crypto_stream_KEYBYTES] = {0};
char nonce[crypto_stream_NONCEBYTES] = {0};
char message[123] = {0};
char out[sizeof(message)] = {0};

int main() {
    crypto_stream_xor(out, message, sizeof(message), nonce, key);
    return 0;
}

