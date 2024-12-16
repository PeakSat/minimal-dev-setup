/*
 * main.c - Blinky for SAMV71 Xplained Ultra
 *
 * Created: 24 July 2024
 * Author : Grigoris Pavlakis <g.pavlakis@spacedot.gr>
 */

/*
 * Although SYS_Initialize() is declared for us in 'definitions.h',
 * this header will transitively include all the peripheral
 * libraries, which is a bad practice since it makes for
 * 'spooky-action-at-a-distance' wrt. missing errors.  
 *
 * Prefer directly including the peripheral headers you need. It's
 * more verbose but the gain in explicitness helps when debugging.
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
