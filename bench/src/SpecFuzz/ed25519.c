#include <sodium.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PK_LEN   crypto_sign_PUBLICKEYBYTES   /* 32 */
#define SIG_LEN  crypto_sign_BYTES             /* 64 */
#define SM_MAX   256                           /* signature + message, attacker-controlled */

unsigned char pk[PK_LEN];          // public key -- fixed
unsigned char sm[SM_MAX];          // signed message (sig || msg) -- attacker-controlled
unsigned char m[SM_MAX];           // decoded message output buffer
unsigned long long smlen = 0;      // length actually read
unsigned long long mlen = 0;       // output: length of verified message

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("USAGE: %s <input_file>\n", argv[0]);
        exit(1);
    }
    FILE *f = fopen(argv[1], "r");
    if (!f) {
        fprintf(stderr, "Failed to open input file.\n");
        exit(1);
    }

    smlen = fread(sm, 1, SM_MAX, f);
    if (ferror(f) || smlen == 0) {
        fclose(f);
        fprintf(stderr, "Failed to read input file or file empty.\n");
        return 1;
    }
    fclose(f);
    
    if (smlen < SIG_LEN) {
        fprintf(stderr, "Input too short (need at least %d bytes for signature).\n", SIG_LEN);
        return 1;

    crypto_sign_ed25519(m, &mlen, sm, smlen, pk);
    return 0;
}
