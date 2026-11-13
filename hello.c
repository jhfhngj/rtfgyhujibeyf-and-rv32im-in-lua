#define UART_ADDR ((volatile char *)0x10000000)

void putchar(char c) {
    *UART_ADDR = c;
}

void puts(const char *s) {
    while (*s) {
        putchar(*s++);
    }
}

char getchar(void) {
    char c;
    while (!(c = *UART_ADDR)) {
    }
    return c;
}

int main(void) {
    puts("Hello from RV32IM!\n");
    puts("This is a C program btw.\n");
    char* toput = "    Wow!    ";
    for(;;) {
        char c = getchar();
        putchar(c);
        puts(toput);
        if (c == 'q') {
            __asm__ volatile ("ebreak");
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
