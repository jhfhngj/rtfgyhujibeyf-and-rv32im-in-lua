#ifndef WEIRDMATH_H
#define WEIRDMATH_H

#include <stddef.h>
#include <stdint.h>

// Maximum buffer size for intermediate grade-school scratchpads (handles up to 128-bit products)
#define PAPER_BUF_SIZE 128

typedef struct {
    uint32_t lo;
    uint32_t hi;
} u64_t;

// ============================================================================
// 1. CORE CONVERSION HELPERS
// ============================================================================

// Converts an unsigned 32-bit integer to a null-terminated string.
static inline char *utoa(uint32_t val, char *dst, size_t cap, int base) {
    if (dst == NULL || cap < 2 || base < 2 || base > 36) {
        if (dst != NULL && cap > 0) dst[0] = '\0';
        return NULL;
    }

    const char digits[] = "0123456789abcdefghijklmnopqrstuvwxyz";
    size_t i = 0;

    do {
        if (i >= cap - 1) {
            dst[0] = '\0';
            return NULL;
        }
        dst[i++] = digits[val % (uint32_t)base];
        val /= (uint32_t)base;
    } while (val > 0);

    dst[i] = '\0';

    size_t start = 0;
    size_t end = i - 1;
    while (start < end) {
        char tmp = dst[start];
        dst[start] = dst[end];
        dst[end] = tmp;
        start++;
        end--;
    }

    return dst;
}

// Converts a numeric string to an unsigned 32-bit integer.
static inline unsigned int atou(const char *str) {
    unsigned int result = 0;
    if (!str) return 0;

    while (*str == ' ' || *str == '\t' || *str == '\n' ||
           *str == '\r' || *str == '\v' || *str == '\f') {
        str++;
    }
    if (*str == '+') {
        str++;
    }
    while (*str >= '0' && *str <= '9') {
        unsigned int digit = (unsigned int)(*str - '0');
        result = (result * 10U) + digit;
        str++;
    }
    return result;
}

// ============================================================================
// 2. STRING SCRATCHPAD UTILITIES
// ============================================================================

static inline int paper_len(const char *s) {
    int len = 0;
    while (s[len] != '\0') len++;
    return len;
}

static inline void paper_copy(char *dst, const char *src) {
    int i = 0;
    while (src[i] != '\0') {
        dst[i] = src[i];
        i++;
    }
    dst[i] = '\0';
}

// Returns 1 if a >= b (as positive base-10 numeric strings), 0 otherwise
static inline int paper_gte(const char *a, const char *b) {
    int len_a = paper_len(a);
    int len_b = paper_len(b);
    if (len_a != len_b) return len_a > len_b;
    for (int i = 0; i < len_a; i++) {
        if (a[i] != b[i]) return a[i] > b[i];
    }
    return 1;
}

// ============================================================================
// 3. GRADE-SCHOOL PAPER ARITHMETIC ON STRINGS
// ============================================================================

// Grade-school addition (right-to-left columns with carry)
static inline void paper_add(const char *top, const char *bottom, char *out) {
    int i = paper_len(top) - 1;
    int j = paper_len(bottom) - 1;
    int k = 0;
    unsigned int carry = 0;
    char rev[PAPER_BUF_SIZE];

    while (i >= 0 || j >= 0 || carry > 0) {
        char d1[2] = { (i >= 0) ? top[i--] : '0', '\0' };
        char d2[2] = { (j >= 0) ? bottom[j--] : '0', '\0' };

        unsigned int col_sum = atou(d1) + atou(d2) + carry;

        char sum_str[8];
        utoa(col_sum, sum_str, sizeof(sum_str), 10);

        if (paper_len(sum_str) == 2) {
            rev[k++] = sum_str[1];
            char c_str[2] = { sum_str[0], '\0' };
            carry = atou(c_str);
        } else {
            rev[k++] = sum_str[0];
            carry = 0;
        }
    }

    for (int x = 0; x < k; x++) {
        out[x] = rev[k - 1 - x];
    }
    out[k] = '\0';
}

// Grade-school subtraction (assumes top >= bottom; returns "0" if top < bottom)
static inline void paper_sub(const char *top, const char *bottom, char *out) {
    if (!paper_gte(top, bottom)) {
        out[0] = '0';
        out[1] = '\0';
        return;
    }

    int i = paper_len(top) - 1;
    int j = paper_len(bottom) - 1;
    int k = 0;
    int borrow = 0;
    char rev[PAPER_BUF_SIZE];

    while (i >= 0) {
        char d1[2] = { top[i--], '\0' };
        char d2[2] = { (j >= 0) ? bottom[j--] : '0', '\0' };

        int top_val = (int)atou(d1) - borrow;
        int bot_val = (int)atou(d2);

        if (top_val < bot_val) {
            top_val += 10;
            borrow = 1;
        } else {
            borrow = 0;
        }

        char diff_str[8];
        utoa((uint32_t)(top_val - bot_val), diff_str, sizeof(diff_str), 10);
        rev[k++] = diff_str[0];
    }

    while (k > 1 && rev[k - 1] == '0') {
        k--;
    }

    for (int x = 0; x < k; x++) {
        out[x] = rev[k - 1 - x];
    }
    out[k] = '\0';
}

// Grade-school multiplication (partial products + zero padding + paper_add)
static inline void paper_mul(const char *top, const char *bottom, char *out) {
    char running_total[PAPER_BUF_SIZE] = "0";
    int len_bot = paper_len(bottom);
    int len_top = paper_len(top);

    for (int j = len_bot - 1; j >= 0; j--) {
        char b_str[2] = { bottom[j], '\0' };
        unsigned int b_digit = atou(b_str);

        char row_rev[PAPER_BUF_SIZE];
        int k = 0;

        int zeros = (len_bot - 1) - j;
        for (int z = 0; z < zeros; z++) {
            row_rev[k++] = '0';
        }

        unsigned int carry = 0;
        for (int i = len_top - 1; i >= 0; i--) {
            char t_str[2] = { top[i], '\0' };
            unsigned int prod = (atou(t_str) * b_digit) + carry;

            char prod_str[8];
            utoa(prod, prod_str, sizeof(prod_str), 10);

            if (paper_len(prod_str) == 2) {
                row_rev[k++] = prod_str[1];
                char c_str[2] = { prod_str[0], '\0' };
                carry = atou(c_str);
            } else {
                row_rev[k++] = prod_str[0];
                carry = 0;
            }
        }
        if (carry > 0) {
            char c_out[8];
            utoa(carry, c_out, sizeof(c_out), 10);
            row_rev[k++] = c_out[0];
        }

        while (k > 1 && row_rev[k - 1] == '0') {
            k--;
        }

        char row[PAPER_BUF_SIZE];
        for (int x = 0; x < k; x++) {
            row[x] = row_rev[k - 1 - x];
        }
        row[k] = '\0';

        char next_total[PAPER_BUF_SIZE];
        paper_add(running_total, row, next_total);
        paper_copy(running_total, next_total);
    }

    paper_copy(out, running_total);
}

// Grade-school long division (left-to-right bring-down + repeated paper_sub)
static inline void paper_div(const char *dividend, const char *divisor, char *quotient, char *remainder) {
    if (divisor[0] == '0' && divisor[1] == '\0') {
        quotient[0] = '0';
        quotient[1] = '\0';
        remainder[0] = '0';
        remainder[1] = '\0';
        return;
    }

    char current[PAPER_BUF_SIZE] = "0";
    int q_idx = 0;
    int started = 0;

    for (int i = 0; dividend[i] != '\0'; i++) {
        int cur_len = paper_len(current);
        if (cur_len == 1 && current[0] == '0') {
            current[0] = dividend[i];
            current[1] = '\0';
        } else {
            current[cur_len] = dividend[i];
            current[cur_len + 1] = '\0';
        }

        unsigned int count = 0;
        while (paper_gte(current, divisor)) {
            char next_cur[PAPER_BUF_SIZE];
            paper_sub(current, divisor, next_cur);
            paper_copy(current, next_cur);
            count++;
        }

        if (count > 0 || started) {
            char digit_str[8];
            utoa(count, digit_str, sizeof(digit_str), 10);
            quotient[q_idx++] = digit_str[0];
            started = 1;
        }
    }

    if (q_idx == 0) {
        quotient[q_idx++] = '0';
    }
    quotient[q_idx] = '\0';
    paper_copy(remainder, current);
}

// ============================================================================
// 4. U64_T <-> STRING CONVERSIONS & PUBLIC 64-BIT MATH WRAPPERS
// ============================================================================

// Converts a u64_t struct into a base-10 string via paper math
static inline char* u64_to_paper(u64_t val, char *out) {
    char hi_str[16];
    char lo_str[16];
    char shifted_hi[PAPER_BUF_SIZE];

    utoa(val.hi, hi_str, sizeof(hi_str), 10);
    utoa(val.lo, lo_str, sizeof(lo_str), 10);

    paper_mul(hi_str, "4294967296", shifted_hi);
    paper_add(shifted_hi, lo_str, out);
    return out;
}

// Parses a base-10 string back into a u64_t struct via string long division
// (Automatically wraps modulo 2^64 if the string exceeds UINT64_MAX)
static inline u64_t paper_to_u64(const char *num_str) {
    char hi_full[PAPER_BUF_SIZE];
    char lo_str[PAPER_BUF_SIZE];
    char ignored_overflow[PAPER_BUF_SIZE];
    char hi_wrapped[PAPER_BUF_SIZE];

    paper_div(num_str, "4294967296", hi_full, lo_str);
    paper_div(hi_full, "4294967296", ignored_overflow, hi_wrapped);

    u64_t result;
    result.hi = atou(hi_wrapped);
    result.lo = atou(lo_str);
    return result;
}

// Original u64topro64: adds two u64_t structs on paper and writes to res_buf
static inline char* u64topro64(u64_t a, u64_t b, char *res_buf) {
    char str_a[PAPER_BUF_SIZE];
    char str_b[PAPER_BUF_SIZE];

    u64_to_paper(a, str_a);
    u64_to_paper(b, str_b);

    paper_add(str_a, str_b, res_buf);
    return res_buf;
}

// Full 64-bit struct arithmetic wrappers powered by paper strings
static inline u64_t u64_add(u64_t a, u64_t b) {
    char str_res[PAPER_BUF_SIZE];
    u64topro64(a, b, str_res);
    return paper_to_u64(str_res);
}

static inline u64_t u64_sub(u64_t a, u64_t b) {
    char str_a[PAPER_BUF_SIZE], str_b[PAPER_BUF_SIZE], str_res[PAPER_BUF_SIZE];
    u64_to_paper(a, str_a);
    u64_to_paper(b, str_b);
    paper_sub(str_a, str_b, str_res);
    return paper_to_u64(str_res);
}

static inline u64_t u64_mul(u64_t a, u64_t b) {
char str_a[PAPER_BUF_SIZE], str_b[PAPER_BUF_SIZE], str_res[PAPER_BUF_SIZE];
u64_to_paper(a, str_a);
u64_to_paper(b, str_b);
paper_mul(str_a, str_b, str_res);
return paper_to_u64(str_res);
}
static inline u64_t u64_div(u64_t a, u64_t b) {
char str_a[PAPER_BUF_SIZE], str_b[PAPER_BUF_SIZE];
char str_quot[PAPER_BUF_SIZE], str_rem[PAPER_BUF_SIZE];
u64_to_paper(a, str_a);
u64_to_paper(b, str_b);
paper_div(str_a, str_b, str_quot, str_rem);
return paper_to_u64(str_quot);
}
#endif // WEIRDMATH_H