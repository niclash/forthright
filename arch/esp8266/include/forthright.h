
//   FSTATE          Is the interpreter executing code (0) or compiling a word (non-zero)?
//   LATEST          Points to the latest (most recently defined) word in the dictionary.
//   DP              Points to the next free byte of memory.  When compiling, compiled words go here.
//   S0              Stores the address of the top of the parameter stack.
//   BASE            The current base for printing and reading numbers.

#define MAX_WORD_SIZE 32

typedef struct
{
    void* data_segment;  		// offset 0
    int data_segment_size;		// offset 4

    void* data_stack;			// offset 8
    int data_stack_size;;		// offset 12

    void* return_stack;;		// offset 16
    int return_stack_size;;		// offset 20

    void* input_buffer;;		// offset 24
    int input_buffer_size;;		// offset 28

    void* word_buffer;;			// offset 32
    int word_buffer_size;;		// offset 36

    void* word_buffer_ptr;;		// offset 40
    int word_buffer_counter;;		// offset 44

    // System variables.
    int state;;				// offset 48
    void* latest;			// offset 52
    void* dp;				// offset 56
    void* s0;				// offset 60
    int base;				// offset 64

    void* currkey;			// offset 68
    void* bufftop;			// offset 72
    int interpret_is_lit;		// offset 76
    int initializing;			// offset 80

} system_t;

extern void forthright();

extern int forthright_divide( int a, int b );

extern int forthright_modulo( int a, int b );

extern void forthright_start( system_t* );
// Testing reading chars before implementing serial port.

/* Reads characters from the primary serial port to the Forth Input Buffer.

   This is a BLOCKING operation. If there are no characters from the serial port, this method will not return
   to the caller (typically from assembler).

   If this method is not called often enough to consume the characters from the
   serial port, characters will be dropped/lost.

   The method returns the number of characters that was written into the 'buffer'.
*/
extern int forthright_readChars( char* buffer, int bufsize );

/* Read characters into the buffer, maximum bufsize characters.
 *
 * Returns the number of characters actually read.
 */

extern int forthright_putChar( char ch );

/* Outputs the characters in str argument. The character array MUST be a null terminated.
 */
extern int forthright_putChars( char* str, int length );

/* This method will send the characters received to the
   secondary serial port, used for debugging Forthright itself.

   Forthright debugging is currently not implemented, but the Forth words
   DEBUG_ON and DEBUG_OFF will enable and disable the output from the Forth runtime, and
   the user program can use DEBUG word to output arbitrary string to the secondary serial port.

   If the port is given more characters than it can handle, it will start discarding output. It will
   NOT block.
*/
extern void forthright_debugOut( char* str, int length  );

extern int forthright_printHex( int value );

extern void forthright_printWord( void* pointer );

extern void forthright_printNL();
extern void forthright_print0();
extern void forthright_print1();
extern void forthright_print2();
extern void forthright_print3();
extern void forthright_print4();
