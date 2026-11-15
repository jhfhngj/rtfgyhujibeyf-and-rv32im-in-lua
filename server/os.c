#define UART_ADDR ((volatile char *)0x10000000)
#include "text.h"
#include "cfg.h"

extern char _end; // Provided by link.ld at end of .bss

int main(void) {
    puts("MeaOS Server\n");
    uint64_t last_active = read_mtime();

    for (;;) {
        if (dl_available() > 0) {
            last_active = read_mtime();
        } else if (ahaltenable) {
            if ((read_mtime() - last_active) >= ((uint64_t)ahalttime * MTIME_FREQ_HZ)) {
                clear();
                if (!customsleep) {
                    printf("MeaOS is now sleeping.\n");
                } else {
                    printf(customsleeptxt);
                }
                __asm__ volatile ("ebreak");
            }
        }

        torun();
    }
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
