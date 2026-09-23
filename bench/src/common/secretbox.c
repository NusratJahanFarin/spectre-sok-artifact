#include <sodium.h>
#include <stdlib.h>
#include <string.h>
#define KEY_LEN crypto_secretbox_KEYBYTES                    /* 32 bytes */
#define MSG_LEN 256
#define NONCE_LEN crypto_secretbox_NONCEBYTES                /* 24 */
#define CIPHERTEXT_LEN (crypto_secretbox_MACBYTES + MSG_LEN)

unsigned char c[CIPHERTEXT_LEN];   // public
unsigned char m[MSG_LEN] = {0};    // secret
unsigned long long mlen = MSG_LEN; // public
unsigned char n[NONCE_LEN] = {0};  // public
unsigned char k[KEY_LEN] = {0x42};    // secret

int main() {
    crypto_secretbox(c, m, mlen, n, k); 


    return 0;
}
