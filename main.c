#include "FreeRTOS.h"
#include "task.h"
#include "luactl.h"

void vApplicationIdleHook(void) {
    __asm__ volatile ("wfi"); // Yield remaining Lua slice when idle!
}

void vBlinkTask(void *pvParameters) {
    uint8_t state = 0;
    for (;;) {
        state ^= 1;
        pin_set(0, state); // Toggle Mesecons Pin A
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

void vShellTask(void *pvParameters) {
    uart_puts("FreeRTOS RV32IM Ready!\n");
    for (;;) {
        char c = uart_getc();
        if (c) {
            uart_putc(c);
        } else {
            vTaskDelay(1);
        }
    }
}

int main(void) {
    xTaskCreate(vBlinkTask, "Blink", 128, NULL, 1, NULL);
    xTaskCreate(vShellTask, "Shell", 192, NULL, 2, NULL);
    vTaskStartScheduler();
    for (;;);
}
