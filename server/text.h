#ifndef TEXT_H
#define TEXT_H
#include "cfg.h"
#define UART_ADDR ((volatile char *)0x10000000)

static inline void putchar(char c) {
    *UART_ADDR = c;
}

static inline void puts(const char *s) {
    while (*s) {
        putchar(*s++);
    }
}

static inline void clear() {
    puts("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
}

#define printf puts

static inline void flush(void) {
    for (int i = 0; i < 64; i++) {
        putchar('\1');
    }
}

static inline char getchar(void) {
    return *UART_ADDR;
}

// Compare two strings character by character
static inline int streq(const char *a, const char *b) {
    while (*a && *b && *a == *b) {
        a++;
        b++;
    }
    return *a == *b;
}

static inline char *get_line(char *buf, int max_len) {
    uint64_t last_active = read_mtime();
    int i = 0;
    while (1) {
        char c = *UART_ADDR;
        if (c == 0) {
            if (ahaltenable) {
                if ((read_mtime() - last_active) >= ((uint64_t)ahalttime * MTIME_FREQ_HZ)) {
                    if (!customsleep) {
                        clear();
                        printf("MeaOS is now sleeping.\n");
                    } else {
                        clear();
                        printf(customsleeptxt);
                    }
                    __asm__ volatile ("ebreak");
                }
            }
            continue;
        }

        last_active = read_mtime();

        if (c == '\n' || c == '\r') {
            break;
        }

        if (c == 8 || c == 127) {
            if (i > 0) {
                i--;
            }
            continue;
        }

        if (i < max_len - 1) {
            buf[i++] = c;
        }
    }
    buf[i] = '\0';
    return buf;
}

static inline char *gets(char *buf) {
    return get_line(buf, bufsize);
}

static inline void print_uint(uint32_t n) {
    char buf[12];
    int i = 0;
    if (n == 0) {
        putchar('0');
        return;
    }
    while (n > 0) {
        buf[i++] = (char)('0' + (n % 10));
        n /= 10;
    }
    while (i > 0) {
        putchar(buf[--i]);
    }
}

#include <stddef.h>

static inline char *join(char *dst, size_t cap, const char *sep,
                             const char *const *items, size_t count) {
    if (dst == NULL || cap == 0) return NULL;

    size_t pos = 0;
    size_t max_write = cap - 1;

    for (size_t i = 0; i < count; i++) {
        if (i > 0 && sep != NULL) {
            for (const char *s = sep; *s != '\0'; s++) {
                if (pos >= max_write) goto done;
                dst[pos++] = *s;
            }
        }

        if (items[i] != NULL) {
            for (const char *p = items[i]; *p != '\0'; p++) {
                if (pos >= max_write) goto done;
                dst[pos++] = *p;
            }
        }
    }

done:
    dst[pos] = '\0';
    return dst;
}
static inline size_t lens(const char *s) {
    if (s == NULL) return 0; // Optional safety guard for bare-metal

    const char *p = s;
    while (*p != '\0') {
        p++;
    }
    return (size_t)(p - s);
}

#endif // TEXT_H
