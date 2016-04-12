/*
 *  Copyright 2016 Niclas Hedhman, All rights reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include "esp_common.h"
#include "freertos/task.h"
#include "forthright.h"
#include "tcp_shell.h"

static xTaskHandle tasks[8];
static int primaryPort = 0;

#ifdef DEBUG
static int debugPort = 0;
#else
static int debugPort = 1;
#endif

static void ICACHE_FLASH_ATTR forthright_task( void* dummy ) {
    forthright();
}

void ICACHE_FLASH_ATTR user_init(void) {
    wifi_init();
    uart_init_new();
    tcp_shell_init();
    UART_SetPrintPort( debugPort );
    xTaskCreate( forthright_task, "forthright", 256, NULL, 2, &tasks[0] ); // create root FORTH interpreter
}

LOCAL int ICACHE_FLASH_ATTR serial_put_chars( int port, char* str, int length ) {
    int i=0;
    for( i = 0; i < length; i++ ) {
        char ch = str[i];
        int result = uart_tx_one_char(port, ch);
        if( result < 0 ) {
            return result;
        }
    }
    return i;
}

void ICACHE_FLASH_ATTR forthright_echo_char( char ch ) {
    if( tcp_shell_is_connected() ) {
        if( ch == '\n' ) {
            tcp_shell_put_chars( " <ok>\n", 6 );
        }
    }
    else {
        uart_tx_one_char( primaryPort, ch );
    }
}

void ICACHE_FLASH_ATTR forthright_putChar( char ch ) {
    if( tcp_shell_is_connected() ) {
        tcp_shell_put_char(ch);
    }
    else {
        uart_tx_one_char( primaryPort, ch );
    }
}

void ICACHE_FLASH_ATTR forthright_putChars( char* str, int length ) {
    if( tcp_shell_is_connected() ) {
        tcp_shell_put_chars(str, length);
    }
    else {
        serial_put_chars( primaryPort, str, length );
    }
}

/* This method will send the characters received to the
   secondary serial port, used for debugging Forthright itself.

   Forthright debugging is currently not implemented, but the Forth words
   DEBUG_ON and DEBUG_OFF will enable and disable the output from the Forth runtime, and
   the user program can use DEBUG word to output arbitrary string to the secondary serial port.

   If the port is given more characters than it can handle, it will start discarding output. It will
   NOT block.
*/
void ICACHE_FLASH_ATTR forthright_debugOut( char* str, int length ) {
    serial_put_chars( debugPort, str, length );
}

/* Reads characters from the primary serial port to the Forth Input Buffer.

   This is NOT a BLOCKING operation. If there are no characters from the serial port,
   this method will not return to the caller (typically from assembler).

   If this method is not called often enough to consume the characters from the
   serial port, characters will be dropped/lost.

   The method returns the number of characters that was written into the 'buffer'.
*/
int ICACHE_FLASH_ATTR forthright_readChars( char* buffer, int bufsize ) {
    int bytesRead;
    if( tcp_shell_is_connected() ) {
        bytesRead = tcp_shell_read_chars(buffer, bufsize-1);
    }
    else {
        bytesRead = uart_read_chars( buffer, bufsize-1 );
    }
    if( bytesRead == 0 ) {
        taskYIELD();
    }
    return bytesRead;
}

/* Division hardware is not present in the ESP8266 CPU, and the firmware library for it
 * is not documented (or I can't find it).
 *
 */
int ICACHE_FLASH_ATTR forthright_divide( int a, int b ) {
    return a / b;
}

int ICACHE_FLASH_ATTR forthright_modulo( int a, int b ) {
    return a % b;
}
