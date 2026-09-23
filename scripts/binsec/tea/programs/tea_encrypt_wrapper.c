#include <stdlib.h>
#include "tea.c"

unsigned long key[4];     // The secret
unsigned long data[2];    // The message to encrypt/decrypt
unsigned long out[2];     // The output buffer
// Everything is high

int main(int argc, char **argv) {
    if (argc != 3) {
        exit(1);
    }

    /* user-controlled input */
    data[0] = atoi(argv[1]);
    data[1] = 0;

    key[0] = atoi(argv[1]);
    key[1] = 0;
    key[2] = 0;
    key[3] = 0;

    encipher(data, out, key);
    return 0;
}
