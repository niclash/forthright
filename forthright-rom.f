\ : '\n' 10 ;
\ : bl 32 ;
\ : cr '\n' emit ;
\ : space bl emit ;
\ : negate 0 swap - ;
\ : true  -1 ;
\ : false 0 ;
\ : not 0= ;
\ : literal immediate ['] lit , , ;
\ : here dp @ ;
\ : ':' [ char : ] literal ;
\ : ';' [ char ; ] literal ;
\ : '(' [ char ( ] literal ;
\ : ')' [ char ) ] literal ;
: '"' [ char " ] literal ;
: 'A' [ char A ] literal ;
: '0' [ char 0 ] literal ;
: '-' [ char - ] literal ;
: '.' [ char . ] literal ;
\ : [compile] immediate word (find) >cfa , ;
\ : recurse immediate latest @ >cfa , ;
: if immediate ['] 0branch , here 0 , ;
\ : then immediate dup here swap - swap ! ;
: else immediate ['] branch , here 0 , swap dup here swap - swap ! ;
\ : begin immediate here ;
: until immediate ['] 0branch , here - , ;
: again immediate ['] branch , here - , ;
: while immediate ['] 0branch , here swap 0 , ;
: repeat immediate ['] branch , here - , dup here swap - swap ! ;
: unless immediate ['] not , [compile] if ;
: ( immediate
	1
	begin
		key
		dup '(' = if
			drop
			1+
		else
			')' = if
				1-
			then
		then
	dup 0= until
	drop
;
\ : nip swap drop ;
\ : tuck swap over ;
\ : pick 1+ 4 * dsp@ + @ ;
: spaces
	begin
		dup 0>
	while
		space
		1-
	repeat
	drop
;
\ : decimal 10 base ! ;
\ : hex 16 base ! ;
: u.
	base @ u/mod
	?dup if
		recurse
	then
	dup 10 < if
		'0'
	else
		10 -
		'A'
	then
	+
	emit
;

: .s
	dsp@
	0 s0 @ + 4-
	begin
		over over <=
	while
		dup @ u.
		space
		4-
	repeat
	drop drop
;

: uwidth
	base @ /
	?dup if
		recurse 1+
	else
		1
	then
;

: u.r swap dup uwidth rot swap - spaces u. ;

: .r
	swap
	dup 0< if
		negate
		1
		swap
		rot
		1-
	else
		0
		swap
		rot
	then
	swap dup uwidth rot swap - spaces swap
	if
		'-' emit
	then
	u.
;
: . 0 .r space ;
: u. u. space ;
: ? @ . ;
: within
	-rot over <= if
		> if
			true
		else
			false
		then
	else
		2drop
		false
	then
;
: depth s0 @ dsp@ - 4- 4 / ;
: aligned 3 + 3 invert and ;
: align here aligned dp ! ;
: c, here c! 1 dp +! ;
: s" immediate
	state @ if
		['] litstring ,
		here
		0 ,
		begin
			key
			dup '"' <>
		while
			c,
		repeat
		drop
		dup
		here swap -
		4-
		swap !
		align
	else
		here
		begin
			key
			dup '"' <>
		while
			over c!
			1+
		repeat
		drop
		here -
		here
		swap
	then
;

: ." immediate
	state @ if
		[compile] s"
		['] tell ,
	else

		begin
			key
			dup '"' = if
				drop
				exit
			then
			emit
		again
	then
;

: constant word header, docol , ['] lit , , ['] exit , ;
: allot dp +! ;
: cells 4 * ;
: variable word header,	dodoes , 0 , 1 cells allot ;
: create word header, dodoes , 0 , ;
: does> r> latest @ >dfa ! ;
: value word header, docol , ['] lit , , ['] exit , ;
: to immediate
	word (find) >dfa 4+
	state @ if
		['] lit , , ['] ! ,
	else
		!
	then
;

: +to immediate
	word (find) >dfa 4+
	state @ if
		['] lit , , ['] +! ,
	else
		+!
	then
;

: id.
	4+ dup c@ f_lenmask and
	begin
		dup 0>
	while
		swap 1+
		dup c@
		emit
		swap 1-
	repeat
	2drop
;

: ?hidden 4+ c@ f_hidden and ;
: ?immediate 4+	c@ f_immed and ;

: words
	latest @
	begin
		?dup
	while
		dup ?hidden not if
			dup id.
			space
		then
		@
	repeat
	cr
;

: forget word (find) dup @ latest ! dp ! ;

: dump
	base @ -rot
	hex

	begin
		?dup
	while
		over 8 u.r
		space
		2dup
		1- 15 and 1+
		begin
			?dup
		while
			swap
			dup c@
			2 .r space
			1+ swap 1-
		repeat
		drop
		2dup 1- 15 and 1+
		begin
			?dup
		while
			swap
			dup c@
			dup 32 128 within if
				emit
			else
				drop '.' emit
			then
			1+ swap 1-
		repeat
		drop
		cr

		dup 1- 15 and 1+
		tuck
		-
		>r + r>
	repeat

	drop
	base !
;

: case immediate
	0
;

: of immediate
	['] over ,
	['] = ,
	[compile] if
	['] drop ,
;

: endof immediate [compile] else ;

: endcase immediate
	['] drop ,
	begin
		?dup
	while
		[compile] then
	repeat
;

: exception-marker rdrop 0 ;
: catch dsp@ 4+ >r ['] exception-marker 4+ >r execute ;
: throw
	?dup if
		rsp@
		begin
			dup r0 4- <
		while
			dup @
			['] exception-marker 4+ = if
				4+
				rsp!
				dup dup dup
				r>
				4-
				swap over
				!
				dsp! exit
			then
			4+
		repeat
		drop

		case
		0 1- of
			." aborted" cr
		endof
			." uncaught throw "
			dup . cr
		endcase
		quit
	then
;

: abort 0 1- throw ;
: [char] char ['] lit , , ; immediate
: 2over 3 pick 3 pick ;
: cell+ 1 cells + ;
: chars ;
: char+ 1 chars + ;
: 2! swap over ! cell+ ! ;
: 2@ dup cell+ @ swap @ ;
: move cmove ;
: 2>r ['] swap , ['] >r , ['] >r , ; immediate
: 2r> ['] r> , ['] r> , ['] swap , ; immediate
: 2r@ 2r> 2dup 2>r ;
: abs dup 0< if negate then ;

create leave-sp 32 cells allot
leave-sp leave-sp !

: leave
	['] unloop ,
	['] branch ,
	leave-sp @ leave-sp - 31 cells >
	if abort then
	1 cells leave-sp +!
	here leave-sp @ !
	0 ,
	; immediate

: resolve-leaves
	begin
		leave-sp @ @ over >
		leave-sp @ leave-sp >  and
	while
		here leave-sp @ @ - leave-sp @ @ !
		1 cells negate leave-sp +!
	repeat
	drop
	;

: do ['] (do) , here 0 ; immediate

: ?do
	['] 2dup ,
	['] <> ,
	['] 0branch ,
	0 ,
	['] (do) ,
	here 1
	; immediate


: resolve-do
	if
		dup here - ,
		dup 2 cells - here over - swap !
	else
		dup here - ,
	then ;

: loop
	['] (loop) ,
	resolve-do
	resolve-leaves
	; immediate

: +loop
	['] (+loop) ,
	resolve-do
	resolve-leaves
	; immediate

: cfa>
	latest @
	begin
		?dup
	while
		2dup swap
		< if
			nip
			exit
		then
		@
	repeat
	drop
	0
;

: see
	word (find)
	here
	latest @
	begin
		2 pick
		over
		<>
	while
		nip
		dup @
	repeat

	drop
	swap

	':' emit space dup id. space
	dup ?immediate if ." immediate " then
	>dfa
	begin
		2dup >
	while
		dup @

		case
		['] lit of
			4 + dup @
			.
		endof
		['] litstring of
			[ char s ] literal emit '"' emit space
			4 + dup @
			swap 4 + swap
			2dup tell
			'"' emit space
			+ aligned
			4 -
		endof
		['] 0branch of
			." 0branch ( "
			4 + dup @
			.
			." ) "
		endof
		['] branch of
			." branch ( "
			4 + dup @
			.
			." ) "
		endof
		['] (loop) of
			." (loop) ( "
			4 + dup @
			.
			." ) "
		endof
		['] (+loop) of
			." (+loop) ( "
			4 + dup @
			.
			." ) "
		endof
		['] ['] of
			." ['] "
			4 + dup @
			cfa>
			id. space
		endof
		['] exit of
			2dup
			4 +
			<> if
				." exit "
			then
		endof
			dup
			cfa>
			id. space
		endcase

		4 +
	repeat

	';' emit cr

	2drop
;

: :noname 0 0 header, here docol , ] ;
: ' word (find) >cfa ;
: print-stack-trace
	rsp@
	begin
		dup r0 4- <
	while
		dup @
		case
		['] exception-marker 4+ of
			." catch ( dsp="
			4+ dup @ u.
			." ) "
		endof
			dup
			cfa>
			?dup if
				2dup
				id.
				[ char + ] literal emit
				swap >dfa 4+ - .
			then
		endcase
		4+
	repeat
	drop
	cr
;

: z" immediate
	state @ if
		['] litstring ,
		here
		0 ,
		begin
			key
			dup '"' <>
		while
			here c!
			1 dp +!
		repeat
		0 here c!
		1 dp +!
		drop
		dup
		here swap -
		4-
		swap !
		align
		['] drop ,
	else
		here
		begin
			key
			dup '"' <>
		while
			over c!
			1+
		repeat
		drop
		0 swap c!
		here
	then
;

: strlen
	dup
	begin
		dup c@ 0<>
	while
		1+
	repeat

	swap -
;
: cstring swap over here swap cmove here + 0 swap c! here ;
: bye ;
: unused data-segment-size here data-segment-start - - 4 / ;
: welcome
	cr
	6 spaces ." Forthright ver 1.0" cr
	." Copyright 2016, Niclas Hedhman" cr
	5 spaces ." All rights reserved." cr cr
	unused . ." cells remaining" cr
	." <ok>" cr
;
welcome
hide welcome
init-done
true echo
