/** Forthright's bootstrapper to leverage the TCP/IP, Serial port and possibly other
* system resources that is provided by the ESP IoT SDK.
*
* This bootstrapper is kept to an absolute minimum for now.
*/

typedef struct
{
    void* data_segment;
    int data_segment_size;

    void* data_stack;
    int data_stack_size;

    void* return_stack;
    int return_stack_size;

    void* input_buffer;
    int input_buffer_size;

    void* word_buffer;
    int word_buffer_size;

    void* word_buffer_ptr;
    int word_buffer_counter;
} system_t;

extern void start( system_t* );

static void* c_stack_address;
static void* c_return_address;
static system_t system;

static char data_stack[DATA_STACK_SIZE];
static char return_stack[RETURN_STACK_SIZE];
static char input_buffer[INPUT_BUFFER_SIZE];
static char data_segment[DATA_SEGMENT_SIZE];

void setup()
{
    system.data_segment = data_segment;
    system.data_segment_size = DATA_SEGMENT_SIZE;

    system.data_stack = data_stack;
    system.data_stack_size = DATA_STACK_SIZE;

    system.return_stack = return_stack;
    system.return_stack_size = RETURN_STACK_SIZE;

    system.input_buffer = input_buffer;
    system.input_buffer_size = INPUT_BUFFER_SIZE;

    forthright_start( &system );
}

void loop()
{
}

// Testing reading chars before implementing serial port.
const char* test = "3 4 5 * + .";

/* Read characters into the buffer, maximum bufsize characters.
 *
 * Returns the number of characters actually read.
 */

int putChar( char ch )
{
    return 1;
}

int putChars( char* str, int length )
{
    int i=0;
    while( i < length )
    {
        int result = putChar( str[i++] );
        if( result < 0 )
        {
            return result;
        }
    }
    return length;
}

/* Reads characters from the primary serial port to the Forth Input Buffer.

   This is a BLOCKING operation. If there are no characters from the serial port, this method will not return
   to the caller (typically from assembler).

   If this method is not called often enough to consume the characters from the
   serial port, characters will be dropped/lost.

   The method returns the number of characters that was written into the 'buffer'.
*/
int readChars( char* buffer, int bufsize )
{
    putChar('o');
    char ch;
    int i=0;
    while( (ch = test[i]) != 0 )
    {
        buffer[i++] = ch;
    }
    return i;
}

/* This method will send the characters received to the
   secondary serial port, used for debugging Forthright itself.

   Forthright debugging is currently not implemented, but the Forth words
   DEBUG_ON and DEBUG_OFF will enable and disable the output from the Forth runtime, and
   the user program can use DEBUG word to output arbitrary string to the secondary serial port.

   If the port is given more characters than it can handle, it will start discarding output. It will
   NOT block.
*/
void debugOut( char* str, int length )
{

}
