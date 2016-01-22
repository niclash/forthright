/** Forthright's bootstrapper to leverage the TCP/IP, Serial port and possibly other
* system resources that is provided by the ESP IoT SDK.
*
* This bootstrapper is kept to an absolute minimum for now.
*/


typedef struct
{

	void* serialPortAddress;
} system_t;

extern void start( void*, int, system_t* );

static void* c_stack_address;
static void* c_return_address;
static system_t system;
static char data_segment[DATA_SEGMENT_SIZE];

void main()
{
    int abc = 676576534;
    start( data_segment, DATA_SEGMENT_SIZE, &system );
    int def = abc % 562736182;
}