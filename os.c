#define UART_ADDR ((volatile char *)0x10000000)
#include "text.h"

int main(void) {
    puts("MeaOS 1.0\n");
    puts("Initializing input\n");

    char input[128]; // Real 128-byte stack buffer

    for (;;) {
        puts("MeaOS >\n"); // Or flush mem.tx in Lua read8 to keep it on one line
        gets(input);
        puts(input);
        puts("\n");

        if (streq(input, "help")) {
            puts("Commands:\nhelp: Opens this\nexit: Halts CPU\necho: Echo\n");
        } else if (streq(input, "exit")) {
            puts("Halting MeaOS...\n");
            __asm__ volatile ("ebreak");
        }
        else if (streq(input, "echo")) {
            puts("Text:\n");
gets(input);
     puts(input);
     puts(input);
        puts("\n");   
        } else if (input[0] != '\0') {
            puts("Unknown command: ");
            puts(input);
            putchar('\n');
        }
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
