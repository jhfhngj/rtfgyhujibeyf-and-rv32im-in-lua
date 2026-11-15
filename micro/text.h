#ifndef TEXT_H
#define TEXT_H

// Compare two strings character by character
static inline int streq(const char *a, const char *b) {
    while (*a && *b && *a == *b) {
        a++;
        b++;
    }
    return *a == *b;
}

#endif // TEXT_H
