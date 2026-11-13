#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#define configMTIME_BASE_ADDRESS        ( 0x0200BFF8UL )
#define configMTIMECMP_BASE_ADDRESS     ( 0x02004000UL )

#define configUSE_PREEMPTION                    1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 0
#define configUSE_TICKLESS_IDLE                 0
#define configCPU_CLOCK_HZ                      ( ( unsigned long ) 240 )
#define configTICK_RATE_HZ                      ( ( TickType_t ) 2 )
#define configMAX_PRIORITIES                    ( 4 )
#define configMINIMAL_STACK_SIZE                ( ( unsigned short ) 128 )
#define configTOTAL_HEAP_SIZE                   ( ( size_t ) ( 8 * 1024 ) )
#define configMAX_TASK_NAME_LEN                 ( 8 )
#define configUSE_16_BIT_TICKS                  0
#define configIDLE_SHOULD_YIELD                 1
#define configUSE_MUTEXES                       0
#define configUSE_RECURSIVE_MUTEXES             0
#define configUSE_COUNTING_SEMAPHORES           0
#define configQUEUE_REGISTRY_SIZE               0
#define configUSE_QUEUE_SETS                    0
#define configUSE_TIME_SLICING                  1
#define configUSE_IDLE_HOOK                     1
#define configUSE_TICK_HOOK                     0
#define configCHECK_FOR_STACK_OVERFLOW          0
#define configUSE_MALLOC_FAILED_HOOK            0
#define configUSE_TIMERS                        0

#define INCLUDE_vTaskDelay                      1
#define INCLUDE_vTaskDelete                     0
#define INCLUDE_vTaskSuspend                    0
#endif
