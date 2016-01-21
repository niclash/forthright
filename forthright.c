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
static char forthData[FORTH_SIZE];

void main()
{
    c_stack_address = main;
    start( forthData, FORTH_SIZE, &system );
}