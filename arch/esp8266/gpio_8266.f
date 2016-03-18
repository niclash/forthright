

HEX

( Number of GPIO pins )
16 CONSTANT gpios

( Hardware registers related to GPIO )
60000300 CONSTANT GPIO_OUT
60000304 CONSTANT GPIO_OUT_W1TS
60000308 CONSTANT GPIO_OUT_W1TC
6000030C CONSTANT GPIO_ENABLE
60000310 CONSTANT GPIO_ENABLE_W1TS
60000314 CONSTANT GPIO_ENABLE_W1TC
60000318 CONSTANT GPIO_IN
6000031C CONSTANT GPIO_STATUS
60000320 CONSTANT GPIO_STATUS_W1TS
60000324 CONSTANT GPIO_STATUS_W1TC

DECIMAL

( Create a mask from the gpio pin number. )
: CREATE-MASK ( gpio# -- mask )
	1 SWAP LSHIFT
;

( Flag is true if GPIO pin is high )
: gpio-pin@ 	( gpio# -- flag )
	CREATE-MASK
	GPIO_IN @		\ get input bits
	AND			\ mask the pin requested
	0<>			\ convert to TRUE / FALSE
;

( Flag is true if GPIO is an output )
: gpio-out? 	( gpio# -- flag )
	CREATE-MASK
	GPIO_ENABLE @		\ get enable bits
	AND			\ mask the pin requested
	0<>			\ convert to TRUE / FALSE
;

( Drives GPIO high )
: gpio-set 	( gpio# -- )
	CREATE-MASK
	GPIO_OUT_W1TS !		\ set the masked bit
;

( Drives GPIO low )
: gpio-clr 	( gpio# -- )
	CREATE-MASK
	GPIO_OUT_W1TC !		\ clear the masked bit
;

( Flag is true if rising edge detected )
: gpio-rise@ 	( gpio# -- flag )
;

( Flag is true if falling edge detected )
: gpio-fall@ 	( gpio# -- flag )
;

( Flag is true if edge detected )
: gpio-edge@ 	( gpio# -- flag )
;

( Clears GPIO edge detector )
: gpio-clr-edge 	( gpio# -- )
;

( Sets GPIO direction to output )
: gpio-dir-out 	( gpio# -- )
;

( Sets GPIO direction to input )
: gpio-dir-in 	( gpio# -- )
;

( Enables rising edge detection )
: gpio-set-rer 	( gpio# -- )
;

( Disables rising edge detection )
: gpio-clr-rer 	( gpio# -- )
;

( Enables falling edge detection )
: gpio-set-fer 	( gpio# -- )
;

( Disables falling edge detection )
: gpio-clr-fer 	( gpio# -- )
;
