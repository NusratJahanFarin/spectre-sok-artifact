#include <stdlib.h>
#include "tea.c"

unsigned long key[4];     // The secret
unsigned long data[2];    // The message to encrypt/decrypt
unsigned long out[2];     // The output buffer


int main(int argc) {

    /* user-controlled input */
    data[0] = argc;
    data[1] = argc;
    encipher(data, out, key);
    return 0;
}
