#ifndef CFG_H
#define CFG_H
// cfg.h
// Configure your MeaOS Server
// Because I wanted to implement this
// I forgot why again

#define bufsize 128
#define ahalttime 60 // seconds
#define ahaltenable 1 // 1 = on 0 = off
#define CLINT_MTIME_LO ((volatile uint32_t *)0x0200BFF8)
#define CLINT_MTIME_HI ((volatile uint32_t *)0x0200BFFC)
#define MTIME_FREQ_KHZ 10000u // 10 MHz = 10,000 ticks per ms
#define MTIME_FREQ_HZ  10000000ULL
#define TOTAL_RAM      32768u
#define customsleep 1 // 1 = on 0 = off, depends on ahaltenable
#define torun function // Don't change this
#define customsleeptxt "M e a O S Server\nM e a O S Server\nM e a O S Server\nM e a O S Server\nM e a O S Server\nM e a O S Server\n"
#include <stdint.h> // Just in case

/*
If your function() needs to import some things
Put them below this
Such as #include "text.h"
*/

#include "io.h"

void function() { // If you want, you can use I/O besides Digilines, for example text I/O.
    static char rx_buf[bufsize];
    static int idx = 0;

    while (dl_available() > 0) {
        char c = dl_read();
        if (c == '\n' || c == '\r' || c == '\0') {
            if (idx > 0) {
                rx_buf[idx] = '\0';
                dl_send("pc", rx_buf);
                idx = 0;
            }
        } else if (idx < bufsize - 1) {
            rx_buf[idx++] = c;
        }
    }
}

#endif // CFG_H
