/*
 * main.c - Blocking USART example for SAMV71 Xplained Ultra
 *
 * Created: 1 August 2024
 * Author : Andronikos Kostas <a.kostas@spacedot.gr>
 */


#include "definitions.h"

int main() {
    SYS_Initialize(NULL);

    char test[15] = "Hello World!\r\n";
    USART1_Write(&test, 15);

    while (true) {

    }
}