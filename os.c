#define UART_ADDR ((volatile char *)0x10000000)
#include <stdint.h>
#include "text.h"
#include "math.h"
#include "cfg.h"
#include "io.h"

extern char _end; // Provided by link.ld at end of .bss

void run_sysinfo(void) {
    // 1. Read live stack pointer register
    uint32_t sp_val;
    __asm__ volatile ("mv %0, sp" : "=r"(sp_val));

    // 2. Probe endianness in live RAM
    volatile uint32_t probe = 0x11223344u;
    uint8_t first_byte = *(volatile uint8_t *)&probe;

    // 3. Measure live CPU speed using CLINT mtime
    uint64_t t0 = read_mtime();
    volatile uint32_t loops = 60;
    while (loops--) {
        __asm__ volatile ("nop");
    }
    uint64_t dt = read_mtime() - t0;
    // Each loop iteration is ~4 instructions (addi, bnez, nop, etc.)
    uint32_t est_hz = (dt > 0) ? (uint32_t)((240ULL * MTIME_FREQ_HZ) / dt) : 0;

    // 4. Calculate live RAM & Uptime
    uint32_t static_used = (uint32_t)(uintptr_t)&_end;
    uint32_t stack_used = 0x7FF0u - sp_val;
    uint32_t free_ram = (sp_val > static_used) ? (sp_val - static_used) : 0;
    uint32_t uptime_s = (uint32_t)(read_mtime() / MTIME_FREQ_HZ);

    puts("=== MeaOS Live Hardware Probe ===\n");
    puts("Arch:   RV");
    print_uint(sizeof(void *) * 8);
    puts("IM (");
    puts((first_byte == 0x44) ? "Little-Endian" : "Big-Endian");
    puts(")\n");

    puts("Speed:  ~");
    print_uint(est_hz);
    puts(" Hz (measured)\n");

    puts("SP:     ");
    print_uint(sp_val);
    puts(" B\n");

    puts("RAM:    ");
    print_uint(static_used + stack_used);
    puts(" / ");
    print_uint(TOTAL_RAM);
    puts(" B used (");
    print_uint(free_ram);
    puts(" B free)\n");

    puts("Uptime: ");
    print_uint(uptime_s);
    puts(" s\n");
}

void run_bench(void) {
    puts("Benchmarking RV32IM (primes < 100)...\n");
    uint64_t start = read_mtime();
    volatile uint32_t limit = 100;
    volatile uint32_t count = 0;

    for (uint32_t n = 2; n < limit; n++) {
        int prime = 1;
        for (uint32_t d = 2; d * d <= n; d++) {
            if (n % d == 0) {
                prime = 0;
                break;
            }
        }
        if (prime) count++;
    }

    uint32_t elapsed_ms = (uint32_t)((read_mtime() - start) / MTIME_FREQ_KHZ);
    puts("Found ");
    print_uint(count);
    puts(" primes in ");
    print_uint(elapsed_ms);
    puts(" ms!\n");
}

int main(void) {
    puts("MeaOS\n");
    puts("Initializing input\n");

    char input[bufsize];

    for (;;) {
        puts(prompt);
        puts("\n");
        gets(input);
        puts(input);
        puts("\n");

        if (streq(input, "help")) {
            puts("Commands:\nhelp: Opens this\nsysinfo: Live hardware stats\nbench: Run benchmark\ntime: Running time\nexit: Halts CPU\necho: Echo\ndlsend: Send digiline\ndlrecv: Read digiline\n");
} else if (streq(input, "sysinfo")) {
            run_sysinfo();
        } else if (streq(input, "bench")) {
            run_bench();
        } else if (streq(input, "time")) {
            uint32_t sec = (uint32_t)(read_mtime() / MTIME_FREQ_HZ);
            puts("Uptime: ");
            print_uint(sec);
            puts(" s\n");
        } else if (streq(input, "exit")) {
            puts("Halting MeaOS...\n");
            __asm__ volatile ("ebreak");
        } else if (streq(input, "echo")) {
            puts("Text:\n");
            gets(input);
            puts(input);
            puts("\n");        } else if (streq(input, "dlsend")) {
            char chan[32];
            puts("Channel:\n");
            get_line(chan,sizeof(chan));
            puts("Message:\n");
            gets(input);
            dl_send(chan, input);
            puts("Sent!\n");
        } else if (streq(input, "dlrecv")) {
            if (!dl_available()) {
                puts("No messages.\n");
            } else {
                while (dl_available()) {
                    putchar(dl_read());
                }
            }

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
