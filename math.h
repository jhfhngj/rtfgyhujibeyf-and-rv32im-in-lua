#ifndef MATH_H
#define MATH_H

#include <stdint.h>

typedef union {
    uint64_t u64;
    struct {
        uint32_t lo;
        uint32_t hi;
    } s;
} u64_parts_t;

uint64_t __ashldi3(uint64_t a, int b) {
    if (b == 0) return a;
    u64_parts_t in = { .u64 = a }, out;
    if (b >= 32) {
        out.s.lo = 0;
        out.s.hi = in.s.lo << (b - 32);
    } else {
        out.s.lo = in.s.lo << b;
        out.s.hi = (in.s.hi << b) | (in.s.lo >> (32 - b));
    }
    return out.u64;
}

uint64_t __lshrdi3(uint64_t a, int b) {
    if (b == 0) return a;
    u64_parts_t in = { .u64 = a }, out;
    if (b >= 32) {
        out.s.hi = 0;
        out.s.lo = in.s.hi >> (b - 32);
    } else {
        out.s.hi = in.s.hi >> b;
        out.s.lo = (in.s.lo >> b) | (in.s.hi << (32 - b));
    }
    return out.u64;
}

uint64_t __udivdi3(uint64_t n, uint64_t d) {
    if (d == 0) return 0xFFFFFFFFFFFFFFFFULL;
    uint64_t q = 0, r = 0;
    for (int i = 63; i >= 0; i--) {
        r = (r << 1) | ((n >> i) & 1ULL);
        if (r >= d) {
            r -= d;
            q |= (1ULL << i);
        }
    }
    return q;
}

#endif
