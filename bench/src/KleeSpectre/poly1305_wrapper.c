#include <stdint.h>
#include <string.h>
#include <stdio.h>


/* ----------------- Poly1305 constants ----------------- */
typedef struct {
    uint32_t r[5];
    uint32_t h[5];
    uint32_t pad[4];
    uint8_t leftover;
    uint8_t buffer[16];
    uint8_t finished;
} poly1305_state;

/* Load 4 bytes little-endian into uint32_t */
static uint32_t U8TO32_LE(const uint8_t *p) {
    return ((uint32_t)p[0]) | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

/* Store 4 bytes little-endian from uint32_t */
static void U32TO8_LE(uint8_t *p, uint32_t v) {
    p[0] = v & 0xff;
    p[1] = (v >> 8) & 0xff;
    p[2] = (v >> 16) & 0xff;
    p[3] = (v >> 24) & 0xff;
}

/* ----------------- Poly1305 initialization ----------------- */
void poly1305_init(poly1305_state *st, const uint8_t key[32]) {
    uint32_t t0, t1, t2, t3;

    /* r &= 0xffffffc0ffffffc0ffffffc0fffffff */
    t0 = U8TO32_LE(key + 0);
    t1 = U8TO32_LE(key + 4);
    t2 = U8TO32_LE(key + 8);
    t3 = U8TO32_LE(key + 12);

    st->r[0] = t0 & 0x3ffffff;
    st->r[1] = ((t0 >> 26) | (t1 << 6)) & 0x3ffff03;
    st->r[2] = ((t1 >> 20) | (t2 << 12)) & 0x3ffc0ff;
    st->r[3] = ((t2 >> 14) | (t3 << 18)) & 0x3f03fff;
    st->r[4] = (t3 >> 8) & 0x00fffff;

    st->h[0] = st->h[1] = st->h[2] = st->h[3] = st->h[4] = 0;

    /* save pad (s) */
    st->pad[0] = U8TO32_LE(key + 16);
    st->pad[1] = U8TO32_LE(key + 20);
    st->pad[2] = U8TO32_LE(key + 24);
    st->pad[3] = U8TO32_LE(key + 28);

    st->leftover = 0;
    st->finished = 0;
}

/* ----------------- Poly1305 block processing ----------------- */
void poly1305_blocks(poly1305_state *st, const uint8_t *m, size_t bytes) {
    uint32_t r0 = st->r[0], r1 = st->r[1], r2 = st->r[2], r3 = st->r[3], r4 = st->r[4];
    uint32_t h0 = st->h[0], h1 = st->h[1], h2 = st->h[2], h3 = st->h[3], h4 = st->h[4];

    while (bytes >= 16) {
        uint32_t t0 = U8TO32_LE(m + 0);
        uint32_t t1 = U8TO32_LE(m + 4);
        uint32_t t2 = U8TO32_LE(m + 8);
        uint32_t t3 = U8TO32_LE(m + 12);

        h0 += t0 & 0x3ffffff;
        h1 += ((t0 >> 26) | (t1 << 6)) & 0x3ffffff;
        h2 += ((t1 >> 20) | (t2 << 12)) & 0x3ffffff;
        h3 += ((t2 >> 14) | (t3 << 18)) & 0x3ffffff;
        h4 += (t3 >> 8) | (1 << 24);

        /* multiply: h *= r (mod 2^130-5) */
        uint64_t d0 = (uint64_t)h0 * r0 + (uint64_t)h1 * 5 * r4 + (uint64_t)h2 * 5 * r3 + (uint64_t)h3 * 5 * r2 + (uint64_t)h4 * 5 * r1;
        uint64_t d1 = (uint64_t)h0 * r1 + (uint64_t)h1 * r0 + (uint64_t)h2 * 5 * r4 + (uint64_t)h3 * 5 * r3 + (uint64_t)h4 * 5 * r2;
        uint64_t d2 = (uint64_t)h0 * r2 + (uint64_t)h1 * r1 + (uint64_t)h2 * r0 + (uint64_t)h3 * 5 * r4 + (uint64_t)h4 * 5 * r3;
        uint64_t d3 = (uint64_t)h0 * r3 + (uint64_t)h1 * r2 + (uint64_t)h2 * r1 + (uint64_t)h3 * r0 + (uint64_t)h4 * 5 * r4;
        uint64_t d4 = (uint64_t)h0 * r4 + (uint64_t)h1 * r3 + (uint64_t)h2 * r2 + (uint64_t)h3 * r1 + (uint64_t)h4 * r0;

        /* partial reduction */
        uint32_t c;
        c = d0 >> 26; h0 = d0 & 0x3ffffff; d1 += c;
        c = d1 >> 26; h1 = d1 & 0x3ffffff; d2 += c;
        c = d2 >> 26; h2 = d2 & 0x3ffffff; d3 += c;
        c = d3 >> 26; h3 = d3 & 0x3ffffff; d4 += c;
        c = d4 >> 26; h4 = d4 & 0x3ffffff; h0 += 5 * c;

        m += 16;
        bytes -= 16;
    }

    st->h[0] = h0; st->h[1] = h1; st->h[2] = h2; st->h[3] = h3; st->h[4] = h4;
}

/* ----------------- Poly1305 finalization ----------------- */
void poly1305_finish(poly1305_state *st, uint8_t mac[16]) {
    uint32_t h0 = st->h[0], h1 = st->h[1], h2 = st->h[2], h3 = st->h[3], h4 = st->h[4];

    /* combine and add pad */
    uint64_t f0 = h0 + ((uint64_t)st->pad[0]);
    uint64_t f1 = h1 + ((uint64_t)st->pad[1]);
    uint64_t f2 = h2 + ((uint64_t)st->pad[2]);
    uint64_t f3 = h3 + ((uint64_t)st->pad[3]);

    U32TO8_LE(mac + 0, (uint32_t)f0);
    U32TO8_LE(mac + 4, (uint32_t)f1);
    U32TO8_LE(mac + 8, (uint32_t)f2);
    U32TO8_LE(mac + 12, (uint32_t)f3);
}

/* ----------------- Poly1305 one-shot API ----------------- */
void crypto_onetimeauth_poly1305(uint8_t mac[16], const uint8_t *m, size_t mlen, const uint8_t key[32]) {
    poly1305_state st;
    poly1305_init(&st, key);
    poly1305_blocks(&st, m, mlen);
    poly1305_finish(&st, mac);
}

