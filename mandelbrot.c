#include <stdint.h>

#define UART_ADDR ((volatile char *)0x10000000)

void putchar(char c) {
    *UART_ADDR = c;
}

void puts(const char *s) {
    while (*s) {
        putchar(*s++);
    }
}

int main(void) {
    puts("Rendering RV32IM Mandelbrot...\n");

    const char *palette = " .:-=+*#%@";
    const int width = 48;
    const int height = 20;
    const int max_iter = 18;

    const int32_t x_min = -131072;
    const int32_t y_min = -72090;
    const int32_t dx = 4096;
    const int32_t dy = 7209;

    char line[50];
    line[width] = '\n';
    line[width + 1] = '\0';

    for (int py = 0; py < height; py++) {
        int32_t cy = y_min + py * dy;
        for (int px = 0; px < width; px++) {
            int32_t cx = x_min + px * dx;
            int32_t zx = 0;
            int32_t zy = 0;
            int iter = 0;

            while (iter < max_iter) {
                int32_t zx2 = (int32_t)(((int64_t)zx * zx) >> 16);
                int32_t zy2 = (int32_t)(((int64_t)zy * zy) >> 16);

                if (zx2 + zy2 > 262144) {
                    break;
                }

                int32_t zxy = (int32_t)(((int64_t)zx * zy) >> 15);
                zy = zxy + cy;
                zx = zx2 - zy2 + cx;
                iter++;
            }

            line[px] = (iter == max_iter) ? '@' : palette[iter % 10];
        }
        puts(line);
    }

    puts("Done!\n");
    __asm__ volatile ("ebreak");
    return 0;
}

__attribute__((naked, section(".text.start")))
void _start(void) {
    __asm__ volatile (
        "li sp, 0x7FF0\n"
        "jal main\n"
        "ebreak\n"
    );
}
