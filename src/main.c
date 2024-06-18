/*
 * $projectname$.c
 *
 * Created: $date$
 * Author : $user$
 */ 


#include "sam.h"
#include "definitions.h"

int main(void)
{
    SYS_Initialize(NULL);
    SYSTICK_TimerStart();

    /* Replace with your application code */
    while (1) 
    {
        PIO_PinSet(PIO_PIN_PA23);
        SYSTICK_DelayMs(1000);
        PIO_PinClear(PIO_PIN_PA23);
        SYSTICK_DelayMs(1000);
    }
}
