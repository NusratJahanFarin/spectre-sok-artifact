#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

/* ========================= Poly1305 ========================= */
typedef struct {
    uint32_t r[5];
    uint32_t h[5];
    uint32_t pad[4];
} poly1305_state;

static void poly1305_blocks(poly1305_state *st, const uint8_t *m, size_t bytes){
}
static void poly1305_finish(poly1305_state *st, uint8_t mac[16]){
}

static void poly1305_init(poly1305_state *st, const uint8_t key[32]) {
    st->r[0] = ((uint32_t)key[0] | ((uint32_t)key[1]<<8) | ((uint32_t)key[2]<<16) | ((uint32_t)(key[3]&0x0f)<<24));
    st->r[1] = ((uint32_t)(key[3]>>4) | ((uint32_t)key[4]<<4) | ((uint32_t)key[5]<<12) | ((uint32_t)(key[6]&0x03)<<20));
    st->r[2] = ((uint32_t)(key[6]>>2) | ((uint32_t)key[7]<<6) | ((uint32_t)key[8]<<14) | ((uint32_t)(key[9]&0x0f)<<22));
    st->r[3] = ((uint32_t)(key[9]>>4) | ((uint32_t)key[10]<<4) | ((uint32_t)key[11]<<12) | ((uint32_t)(key[12]&0x03)<<20));
    st->r[4] = ((uint32_t)(key[12]>>2) | ((uint32_t)key[13]<<6) | ((uint32_t)key[14]<<14) | ((uint32_t)(key[15]&0x0f)<<22));
    st->h[0] = st->h[1] = st->h[2] = st->h[3] = st->h[4] = 0;
    st->pad[0] = ((uint32_t)key[16] | ((uint32_t)key[17]<<8) | ((uint32_t)key[18]<<16) | ((uint32_t)key[19]<<24));
    st->pad[1] = ((uint32_t)key[20] | ((uint32_t)key[21]<<8) | ((uint32_t)key[22]<<16) | ((uint32_t)key[23]<<24));
    st->pad[2] = ((uint32_t)key[24] | ((uint32_t)key[25]<<8) | ((uint32_t)key[26]<<16) | ((uint32_t)key[27]<<24));
    st->pad[3] = ((uint32_t)key[28] | ((uint32_t)key[29]<<8) | ((uint32_t)key[30]<<16) | ((uint32_t)key[31]<<24));
}

static void crypto_onetimeauth_poly1305(uint8_t mac[16], const uint8_t *m, size_t mlen, const uint8_t key[32]) {
    poly1305_state st;
    poly1305_init(&st, key);
    poly1305_blocks(&st, m, mlen);
    poly1305_finish(&st, mac);
}

/* ========================= Salsa20/XSalsa20 ========================= */
typedef struct {
    uint32_t input[16];
} salsa20_state;

#define ROTL(a,b) (((a) << (b)) | ((a) >> (32-(b))))
#define QR(a,b,c,d) (b ^= ROTL(a+d,7), c ^= ROTL(b+a,9), d ^= ROTL(c+b,13), a ^= ROTL(d+c,18))

static void salsa20_core(uint32_t out[16], const uint32_t in[16]) {
    int i;
    uint32_t x[16];
    memcpy(x, in, sizeof(x));
    for (i = 0; i < 20; i += 2) {
        QR(x[0],x[4],x[8],x[12]);
        QR(x[5],x[9],x[13],x[1]);
        QR(x[10],x[14],x[2],x[6]);
        QR(x[15],x[3],x[7],x[11]);
        QR(x[0],x[1],x[2],x[3]);
        QR(x[5],x[6],x[7],x[4]);
        QR(x[10],x[11],x[8],x[9]);
        QR(x[15],x[12],x[13],x[14]);
    }
    for (i = 0; i < 16; i++) out[i] = x[i] + in[i];
}

static void xsalsa20_expand(uint32_t out[16], const uint8_t key[32], const uint8_t nonce[24]) {
    static const char sigma[16] = "expand 32-byte k";
    int i;
    out[0]  = ((uint32_t)sigma[0]) | ((uint32_t)sigma[1]<<8) | ((uint32_t)sigma[2]<<16) | ((uint32_t)sigma[3]<<24);
    out[5]  = ((uint32_t)sigma[4]) | ((uint32_t)sigma[5]<<8) | ((uint32_t)sigma[6]<<16) | ((uint32_t)sigma[7]<<24);
    out[10] = ((uint32_t)sigma[8]) | ((uint32_t)sigma[9]<<8) | ((uint32_t)sigma[10]<<16) | ((uint32_t)sigma[11]<<24);
    out[15] = ((uint32_t)sigma[12]) | ((uint32_t)sigma[13]<<8) | ((uint32_t)sigma[14]<<16) | ((uint32_t)sigma[15]<<24);
    for (i=0;i<4;i++) {
        out[1+i] = ((uint32_t)key[4*i]) | ((uint32_t)key[4*i+1]<<8) | ((uint32_t)key[4*i+2]<<16) | ((uint32_t)key[4*i+3]<<24);
        out[11+i] = ((uint32_t)key[16+4*i]) | ((uint32_t)key[16+4*i+1]<<8) | ((uint32_t)key[16+4*i+2]<<16) | ((uint32_t)key[16+4*i+3]<<24);
    }
    for (i=0;i<8;i++)
        out[6+i] = ((uint32_t)nonce[i]) | ((uint32_t)nonce[8+i]<<8) | ((uint32_t)nonce[16+i]<<16) | ((uint32_t)nonce[16+i]<<24);
}

static void salsa20_stream(uint8_t *c, const uint8_t *m, size_t mlen, const uint8_t key[32], const uint8_t nonce[24]) {
    uint32_t state[16], block[16];
    xsalsa20_expand(state, key, nonce);
    size_t i,j;
    uint8_t keystream[64];
    for(i=0;i<mlen;i+=64) {
        salsa20_core(block, state);
        for(j=0;j<64 && i+j<mlen;j++)
            c[i+j] = m[i+j] ^ ((block[j/4] >> (8*(j&3))) & 0xff);
        state[8]++;
        if(state[8]==0) state[9]++;
    }
}

/* ========================= crypto_secretbox ========================= */
int crypto_secretbox_xsalsa20poly1305(uint8_t *c, const uint8_t *m, unsigned long long mlen,
                                      const uint8_t *n, const uint8_t *k) {
    if(mlen<32) return -1;
    salsa20_stream(c, m, mlen, k, n);
    uint8_t poly_key[32];
    memcpy(poly_key, c, 32); // derive poly1305 key from first 32 bytes of keystream
    crypto_onetimeauth_poly1305(c + mlen, c, mlen, poly_key);
    return 0;
}

int crypto_secretbox(uint8_t *c, const uint8_t *m, unsigned long long mlen,
                     const uint8_t *n, const uint8_t *k) {
    return crypto_secretbox_xsalsa20poly1305(c, m, mlen, n, k);
}
