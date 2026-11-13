#ifndef LUACTL_H
#define LUACTL_H
#include <stdint.h>

#define UART_ADDR ((volatile char *)0x10000000)
#define PINS_ADDR ((volatile uint8_t *)0x10000004)

static inline void uart_putc(char c) { *UART_ADDR = c; }
static inline void uart_puts(const char *s) { while (*s) uart_putc(*s++); }
static inline char uart_getc(void) { return *UART_ADDR; }

// Pin helpers: bit 0=A, 1=B, 2=C, 3=D
static inline void pins_write(uint8_t mask) { *PINS_ADDR = mask; }
static inline uint8_t pins_read(void) { return *PINS_ADDR; }
static inline void pin_set(uint8_t idx, int val) {
    uint8_t cur = *PINS_ADDR;
    *PINS_ADDR = val ? (cur | (1 << idx)) : (cur & ~(1 << idx));
}
#endif
