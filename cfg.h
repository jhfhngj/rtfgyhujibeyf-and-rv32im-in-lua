#ifndef CFG_H
#define CFG_H

// cfg.h
// Configure your MeaOS
// Because I wanted to implement this
// I forgot why
#define bufsize 128
#define prompt "MeaOS >"
#define ahalttime 60 // seconds
#define ahaltenable 1 // 1 = on 0 = off
#define CLINT_MTIME_LO ((volatile uint32_t *)0x0200BFF8)
#define CLINT_MTIME_HI ((volatile uint32_t *)0x0200BFFC)
#define MTIME_FREQ_KHZ 10000u // 10 MHz = 10,000 ticks per ms
#define MTIME_FREQ_HZ  10000000ULL
#define TOTAL_RAM      32768u
#define customsleep 1 // 1 = on 0 = off, depends on ahaltenable
#define customsleeptxt "M e a O S\nM e a O S\nM e a O S\nM e a O S\nM e a O S\nM e a O S\n"
#include <stdint.h>

static inline uint64_t read_mtime(void) {
    uint32_t hi, lo;
    do {
        hi = *CLINT_MTIME_HI;
        lo = *CLINT_MTIME_LO;
    } while (hi != *CLINT_MTIME_HI);
    return ((uint64_t)hi << 32) | lo;
}

#endif // CFG_H
