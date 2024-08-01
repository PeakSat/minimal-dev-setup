/*
 * main.c - Blinky for SAMV71 Xplained Ultra
 *
 * Created: 24 July 2024
 * Author : Grigoris Pavlakis <g.pavlakis@spacedot.gr>
 */

/*
 * IWYU (include what you use) is best practice!
 * Here, the peripheral headers are transitively included by
 */

#include "pio/plib_pio.h"
#include "systick/plib_systick.h"

void SYS_Initialize ( void* data );

int main(void)
{
    SYS_Initialize(NULL);
    SYSTICK_TimerStart();

    while (1)
    {
        SYSTICK_DelayMs(1000);
        PIO_PinClear(PIO_PIN_PA23);
        SYSTICK_DelayMs(1000);
        PIO_PinSet(PIO_PIN_PA23);
    }
}
