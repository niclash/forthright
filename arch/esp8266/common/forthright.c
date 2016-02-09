/** Forthright's bootstrapper to leverage the TCP/IP, Serial port and possibly other
* system resources that is provided by the ESP IoT SDK.
*
* This bootstrapper is kept to an absolute minimum for now.
*/

#include "forthright.h"

static system_t system;

static char data_stack[DATA_STACK_SIZE];
static char return_stack[RETURN_STACK_SIZE];
static char input_buffer[INPUT_BUFFER_SIZE];
static char data_segment[DATA_SEGMENT_SIZE];
static char word_buffer[MAX_WORD_SIZE];

void forthright()
{
    system.data_segment = data_segment;
    system.data_segment_size = DATA_SEGMENT_SIZE;

    system.data_stack = data_stack;
    system.data_stack_size = DATA_STACK_SIZE;

    system.return_stack = return_stack;
    system.return_stack_size = RETURN_STACK_SIZE;

    system.input_buffer = input_buffer;
    system.input_buffer_size = INPUT_BUFFER_SIZE;

    system.word_buffer = word_buffer;
    system.word_buffer_size = MAX_WORD_SIZE;

    forthright_start( &system );
}

