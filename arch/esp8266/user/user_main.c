
#include "esp_common.h"
#include "freertos/task.h"
#include "forthright.h"

static xTaskHandle tasks[8];
static int primaryPort = 0;

#ifdef DEBUG
static int debugPort = 0;
#else
static int debugPort = 1;
#endif

static void forthright_task( void* dummy )
{
    forthright();
}

void user_init(void)
{
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

int forthright_printHex0( int value )
{
    char buf[12];
    sprintf(buf, "%X ", value);
    forthright_putChars( buf, strlen(buf));
    return value;
}

int printDec( int value )
{
    char buf[12];
    sprintf(buf, "%d ", value);
    forthright_putChars( buf, strlen(buf));
    return value;
}

int forthright_printHex1( int value )
{
    char buf[12];
    sprintf(buf, "%X ", value);
    forthright_debugOut( buf, strlen(buf));
    return value;
}

static void printWord( void* pointer, int all )
{
    char buf[32];
    void* nextWord = *((void**)pointer);
    if( all )
        forthright_printHex0( (int) nextWord );

    char length_flags = *(((char *) pointer) + 4 );
    int length = length_flags & 31;
    forthright_putChars( ((char * ) pointer)+5, length);
}

/*
 * This routine prints the Word definition.
 */
void forthright_printWord0( void* pointer )
{
    printWord(pointer, TRUE);
}


static int findAndPrint( void* latest, void* toFind )
{
    void* current = latest;
    while( current )
    {
        if( current < toFind )
        {
            printWord( current, FALSE );
            forthright_putChar( ' ' );
            return 0;
        }
        current = *((void**) current);
    }
    return -1;
}

static void printEntry(void* start, void* end, void* docol, void* latest )
{
    forthright_printWord0( start );
    start = (void*) (((char*) start) + 4);
    char immediate = (*(((char *) start))) & 0x80;
    char length = (*(((char *) start))) & 0x1F;
    start = (void*) ((((int) start) + length + 4) & ~3);

    forthright_putChar( ' ' );
    forthright_putChar( ':' );
    forthright_putChar( ' ' );
    while( start < end )
    {
        void* defWord = *((void**)start);
        if( defWord == docol )
        {
            forthright_putChars( "DOCOL ", 6 );
            if( immediate )
                forthright_putChars( "IMMEDIATE ", 10 );
        }
        else if( (int) defWord > 0xFFFF0000 )
        {
            printDec( (int) defWord );
        }
        else if( (int) defWord > 0xFFFF0000 )
        {
            printDec( (int) defWord );
        }
        else if( (int) defWord > 0x40000000 )
        {
            forthright_putChars( "<ASM:", 5 );
            forthright_printHex0( (int) defWord );
            forthright_putChar( '>' );
            break;
        }
        else
        {
            if( findAndPrint(latest, defWord) )
            {
                forthright_printHex0( (int) defWord );
            }
        }
        start = (void*) (((char*) start) + 4);
    }
    forthright_putChar( '\n' );
    forthright_putChar( '\n' );

}

void forthright_printDictionary( void* dp, void* latest, void* docol )
{
    void* previous = dp;
    void* current = latest;
    while( current )
    {
        printEntry( current, previous, docol, latest );
        previous = current;
        current = *((void**) current);
    }
}

/*
 * This routine prints the Word definition.
 */
void forthright_printWord1( void* pointer )
{
    char buf[32];
    void* nextWord = pointer;
    char length_flags = *(((char *) pointer) + 4 );
    int length = length_flags & 31;
    forthright_debugOut( "  - ", 4 );
    forthright_debugOut( ((char * ) pointer)+5, length);
    forthright_debugOut( "\n", 1 );
}

void forthright_printNL0()
{
    uart_tx_one_char(primaryPort, '\n');
}

void forthright_printNL1()
{
    uart_tx_one_char(debugPort, '\n');
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
    return a % b;
}

