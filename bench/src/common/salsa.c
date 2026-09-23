#include "libsodium/include/sodium.h"
#include <string.h>
#include <stdio.h>


#define SALSA_DATA_SIZE 64
#define SALSA_KEY_SIZE 32

char c[SALSA_DATA_SIZE] = {0};
char m[SALSA_DATA_SIZE] = {0};
char k[SALSA_KEY_SIZE] = {0};
unsigned char nonce[crypto_stream_salsa20_NONCEBYTES] = {0};

int main() {


    crypto_stream_salsa20_xor(c, m, SALSA_DATA_SIZE, nonce, k);
    

    return 0;
}

