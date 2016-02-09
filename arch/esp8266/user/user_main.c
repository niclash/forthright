
#include "esp_common.h"
#include "freertos/task.h"
#include "forthright.h"

static char* WELCOME1 = "    Forthright ver ";
static char* WELCOME2 = "\n           by\n      Niclas Hedhman\n\n";

static xTaskHandle tasks[8];
static int primaryPort = 0;
static int debugPort = 0;

static void forthright_task( void* dummy )
{
    forthright();
}

void user_init(void)
{
    forthright_putChars( WELCOME1, strlen(WELCOME1) );
    forthright_putChar( '0' + FORTHRIGHT_VERSION_MAJOR );
    forthright_putChar( '.' );
    forthright_putChar( '0' + FORTHRIGHT_VERSION_MINOR );
    forthright_putChars( WELCOME2, strlen(WELCOME2) );
    uart_init_new();
    UART_SetPrintPort( debugPort );
    xTaskCreate( forthright_task, "forthright", 256, NULL, 2, &tasks[0] ); // create root FORTH interpreter
}

static int putCharsToSerial( int port, char* str, int length )
{
    int i=0;
    for( i = 0; i < length; i++ )
    {
        char ch = str[i];
        int result = uart_tx_one_char(port, ch);
        if( result < 0 )
        {
            return result;
        }
    }
    return i;
}

int forthright_putChar( char ch )
{
    return uart_tx_one_char( primaryPort, ch );
}

int forthright_putChars( char* str, int length )
{
    return putCharsToSerial( primaryPort, str, length );
}

/* This method will send the characters received to the
   secondary serial port, used for debugging Forthright itself.

   Forthright debugging is currently not implemented, but the Forth words
   DEBUG_ON and DEBUG_OFF will enable and disable the output from the Forth runtime, and
   the user program can use DEBUG word to output arbitrary string to the secondary serial port.

   If the port is given more characters than it can handle, it will start discarding output. It will
   NOT block.
*/
void forthright_debugOut( char* str, int length )
{
    putCharsToSerial( debugPort, str, length );
}

int forthright_printHex( int value )
{
    printf("%x\n", value);
    return value;
}

/*
 * This routine prints the Word definition.
 */
void forthright_printWord( void* pointer )
{
    char buf[32];
    void* nextWord = pointer;
    char length_flags = *(((char *) pointer) + 4 );
    int length = length_flags & 31;
    memcpy( buf, (((char *) pointer) + 5 ), length );
    buf[length] = '\0';
    printf( " -  %s\n", buf );
    os_delay_us(50000);
}

void forthright_printNL()
{
    uart_tx_one_char(debugPort, '\n');
    os_delay_us(50000);
}

void forthright_printEq()
{
    uart_tx_one_char(debugPort, '=');
}

void forthright_print0()
{
    uart_tx_one_char(debugPort, '0');
}

void forthright_print1()
{
    uart_tx_one_char(debugPort, '1');
}

void forthright_print2()
{
    uart_tx_one_char(debugPort, '2');
}

void forthright_print3()
{
    uart_tx_one_char(debugPort, '3');
}

void forthright_print4()
{
    uart_tx_one_char(debugPort, '4');
}

/* Reads characters from the primary serial port to the Forth Input Buffer.

   This is NOT a BLOCKING operation. If there are no characters from the serial port,
   this method will not return to the caller (typically from assembler).

   If this method is not called often enough to consume the characters from the
   serial port, characters will be dropped/lost.

   The method returns the number of characters that was written into the 'buffer'.
*/
int forthright_readChars( char* buffer, int bufsize )
{
    return uart_read_chars( buffer, bufsize-1 );
}

/* Division hardware is not present in the ESP8266 CPU, and the firmware library for it
 * is not documented (or I can't find it).
 *
 */
int forthright_divide( int a, int b )
{
    return a / b;
}

int forthright_modulo( int a, int b )
{
    return a / b;
}

