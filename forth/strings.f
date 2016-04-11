
( This library was originally taken from https://bernd-paysan.de/httpd-en.html

  We need some string functions, it doesn't work without. The following string library stores strings in ordinary
  variables, which then contain a pointer to a counted string stored allocated from the heap. Instead of a count
  byte, there's a whole count cell, sufficient for all normal use. The string library originates from bigFORTH and
  I've ported it to Gforth (ANS Forth). But now we consider the details of the functions. First we need two words
  bigFORTH already provides:
)


( delete deletes the first \( n \) bytes from a buffer and fills the rest at the end with blanks. )

: delete   ( addr u n -- )
    over min >r  r@ - ( left over )  dup 0>
    IF
        2dup swap dup  r@ +  -rot swap move
    THEN
    + r> bl fill
;


( insert inserts as string at the front of a buffer. The remaining bytes are moved on. )
: insert   ( string length buffer size -- )
    rot over min >r  r@ - ( left over )
    over dup r@ +  rot move   r> move
;


( To avoid exhausting our memory management, there are only certain string sizes; $padding takes care of rounding
  up to multiplies of four cells.
)
: $padding ( n -- n' )
    [ 6 cells ] Literal + [ -4 cells ] Literal and
;

( $! stores a string at an address, If there was a string there already, that string will be lost. )
: $! ( addr1 u addr2 -- )
    dup @ IF
        dup @ free throw
    THEN
    over $padding allocate throw over ! @
    over >r rot over cell+ r> move 2dup ! + cell+ bl swap c!
;

( $@ returns the stored string. )
: $@ ( addr1 -- addr2 u )  @ dup cell+ swap @ ;


( $@len returns just the length of a string. )
: $@len ( addr -- u )  @ @ ;


( $!len changes the length of a string. Therefore we must change the memory area and adjust address and count
  cell as well.
)
: $!len ( u addr -- )
    over $padding over @ swap resize throw over ! @ !
;

( $del deletes \( u \) bytes from a string with offset \( off \). )
: $del ( addr off u -- )   >r >r dup $@ r> /string r@ delete
  dup $@len r> -- swap $!len
;


( $ins inserts a string at offset \( off \). )
: $ins ( addr1 u addr2 off -- ) >r
    2dup dup $@len rot + swap $!len  $@ 1+ r> /string insert
;


( $+! appends a string to another. )
: $+! ( addr1 u addr2 -- ) dup $@len $ins ;


( $off releases a string. )
: $off ( addr -- )  dup @ free throw off ;


( $split divides a string into two, with one char as separator (e.g. '? for arguments) )
: $split ( addr u char -- addr1 u1 addr2 u2 )
    >r 2dup r> scan dup >r
    dup IF
        1 /string
    THEN
    2swap r> - 2swap
;


( $iter takes a string apart piece for piece, also with a character as separator.
  For each part a passed token will be called. With this you can take apart arguments -- separated
  with '& -- at ease.
)
: $iter ( .. $addr char xt -- .. ) { char xt }
    $@ BEGIN dup  WHILE
        char $split >r >r xt execute r> r>
    REPEAT
    2drop
;

