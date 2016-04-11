

hex

( Number of GPIO pins )
16 constant gpios

( Hardware registers related to GPIO )
60000300 constant GPIO_OUT
60000304 constant GPIO_OUT_W1TS
60000308 constant GPIO_OUT_W1TC
6000030C constant GPIO_ENABLE
60000310 constant GPIO_ENABLE_W1TS
60000314 constant GPIO_ENABLE_W1TC
60000318 constant GPIO_IN
6000031C constant GPIO_STATUS
60000320 constant GPIO_STATUS_W1TS
60000324 constant GPIO_STATUS_W1TC

decimal

( Create a mask from the gpio pin number. )
: create-mask ( gpio# -- mask )
	15 and 1 swap lshift
;

( Flag is true if GPIO pin is high )
: gpio-pin@ 	( gpio# -- flag )
	create-mask
	GPIO_IN @		\ get input bits
	and				\ mask the pin requested
	0<>				\ convert to TRUE / FALSE
;

( Flag is true if GPIO is an output )
: gpio-out? 	( gpio# -- flag )
	create-mask
	GPIO_ENABLE @	\ get enable bits
	and				\ mask the pin requested
	0<>				\ convert to TRUE / FALSE
;

( Drives GPIO to value )
: gpio-pin! 	( bvalue gpio# -- )
    swap 0= if
	    gpio-clr
	else
	    gpio-set
	then
;

( Drives GPIO high )
: gpio-set 	( gpio# -- )
	create-mask
	GPIO_OUT_W1TS !		\ set the masked bit
;

( Drives GPIO low )
: gpio-clr 	( gpio# -- )
	create-mask
	GPIO_OUT_W1TC !		\ clear the masked bit
;

( Sets GPIO direction to output )
: gpio-dir-set 	( direction gpio# -- )
	swap 0= if
	    gpio-dir-in
	else
	    gpio-dir-out
	then
;

( Sets GPIO direction to output )
: gpio-dir-out 	( gpio# -- )
	create-mask
	GPIO_ENABLE_W1TS !
;

( Sets GPIO direction to input )
: gpio-dir-in 	( gpio# -- )
	create-mask
	GPIO_ENABLE_W1TC !
;


\ TODO Need to study the datasheet in detail for these functions
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

( Arduino-friendly names )

: INPUT false ;
: OUTPUT true ;

: LOW false ;
: HIGH true ;

( mode gpio# -- )
: pinMode gpio-dir-set ;

( bvalue gpio# -- )
: digitalWrite gpio-pin! ;

( gpio# -- bvalue )
: digitalRead gpio-pin@ ;
