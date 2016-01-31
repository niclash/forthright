
#include "esp_common.h"
#include "forthright.h"

static char* WELCOME1 = "    Forthright ver ";
static char* WELCOME2 = "\n           by\n      Niclas Hedhman\n\n";

void user_init(void)
{
    forthright_putChars( WELCOME1, strlen(WELCOME1) );
    forthright_putChar( '0' + FORTHRIGHT_VERSION_MAJOR );
    forthright_putChar( '.' );
    forthright_putChar( '0' + FORTHRIGHT_VERSION_MINOR );
    forthright_putChars( WELCOME2, strlen(WELCOME2) );
    forthright_setup();
}

/* Read characters into the buffer, maximum bufsize characters.
 *
 * Returns the number of characters actually read.
 */

static int putCharToSerial( int port, char ch )
{
    os_putc(ch);
    return 1;
}

static int putCharsToSerial( int port, char* str, int length )
{
    int i=0;
    for( i = 0; i < length; i++ )
    {
        char ch = str[i];
        int result = putCharToSerial( port, ch );
        if( result < 0 )
        {
            return result;
        }
    }
    return i;
}

int forthright_putChar( char ch )
{
    return putCharToSerial( 1, ch );
}

int forthright_putChars( char* str, int length )
{
    int addr = (int) str;
    for( addr = 0; addr < length; addr++ )
    {
        os_putc(str[addr]);
    }
    os_delay_us(50000);
    return addr;
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
    putCharsToSerial( 2, str, length );
}

void forthright_printHex( int value )
{
    printf("%x\n", value);
    os_delay_us(50000);
}

/* This routine prints the Word definition.
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
    printf("\n");
    os_delay_us(50000);
}

void forthright_printEq()
{
    printf("=");
    os_delay_us(50000);
}

void forthright_print0()
{
    printf("0");
    os_delay_us(5000);
}

void forthright_print1()
{
    printf("1");
    os_delay_us(5000);
}

void forthright_print2()
{
    printf("2");
    os_delay_us(5000);
}

void forthright_print3()
{
    printf("3");
    os_delay_us(5000);
}

void forthright_print4()
{
    printf("4");
    os_delay_us(5000);
}

/* Reads characters from the primary serial port to the Forth Input Buffer.

   This is a BLOCKING operation. If there are no characters from the serial port, this method will not return
   to the caller (typically from assembler).

   If this method is not called often enough to consume the characters from the
   serial port, characters will be dropped/lost.

   The method returns the number of characters that was written into the 'buffer'.
*/

// Testing reading chars before implementing serial port.
const char* test = "48 2 + EMIT \n";

int forthright_readChars( char* buffer, int bufsize )
{
    printf( "readChars()   -->  " );
    char ch;
    int i=0;
    while( (ch = test[i]) != 0 )
    {
        buffer[i++] = ch;
    }
    buffer[i] = '\0';
    os_delay_us(50000);
    printf( "%s   <ok>\n", buffer);
    return i;
}

