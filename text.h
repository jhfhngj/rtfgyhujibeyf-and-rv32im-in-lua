#ifndef TEXT_H
#define TEXT_H

#define UART_ADDR ((volatile char *)0x10000000)

static inline void putchar(char c) {
    *UART_ADDR = c;
}

static inline void puts(const char *s) {
    while (*s) {
        putchar(*s++);
    }
}

#define printf puts

static inline void flush(void) {
    for (int i = 0; i < 64; i++) {
        putchar('\1');
    }
}

static inline char getchar(void) {
    char c;
    while (!(c = *UART_ADDR)) {
    }
    return c;
}

// Compare two strings character by character
static inline int streq(const char *a, const char *b) {
    while (*a && *b && *a == *b) {
        a++;
        b++;
    }
    return *a == *b;
}

// Reads a line from UART into buf (up to max_len - 1 chars) and null-terminates it
static inline char *get_line(char *buf, int max_len) {
    int i = 0;
    while (1) {
        char c = getchar();

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
    return get_line(buf, 128);
}

#endif // TEXT_H
