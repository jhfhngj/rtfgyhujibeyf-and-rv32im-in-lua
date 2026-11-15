#include "cfg.h"

extern char _end; // Provided by link.ld at end of .bss

int main(void) {
    uint64_t last_active = read_mtime();

    for (;;) {
        if (dl_available() > 0) {
            last_active = read_mtime();
        } else if (ahaltenable) {
            if ((read_mtime() - last_active) >= ((uint64_t)ahalttime * MTIME_FREQ_HZ)) {
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
