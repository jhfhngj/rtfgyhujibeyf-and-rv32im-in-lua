#ifndef IO_H
#define IO_H

#include <stdint.h>

#define DL_CHAN (*(volatile uint8_t *)0x10001000)
#define DL_DATA (*(volatile uint8_t *)0x10001001)
#define DL_CTRL (*(volatile uint8_t *)0x10001002)

// Send a message string on any Digilines channel
static inline void dl_send(const char *channel, const char *msg) {
    while (*channel) {
        DL_CHAN = (uint8_t)*channel++;
    }
    while (*msg) {
        DL_DATA = (uint8_t)*msg++;
    }
    DL_CTRL = 1; // Dispatch digiline_send() and clear TX buffers
}

// Returns number of unread bytes waiting in the Digilines RX buffer
static inline uint8_t dl_available(void) {
    return DL_CTRL;
}

// Pops and returns the next byte from Digilines RX (0 if empty)
static inline char dl_read(void) {
    return (char)DL_DATA;
}

// Clears the Digilines RX buffer
static inline void dl_clear(void) {
    DL_CTRL = 2;
}

static inline uint64_t read_mtime(void) {
    uint32_t hi, lo;
    do {
        hi = *CLINT_MTIME_HI;
        lo = *CLINT_MTIME_LO;
    } while (hi != *CLINT_MTIME_HI);
    return ((uint64_t)hi << 32) | lo;
}

#endif // IO_H
