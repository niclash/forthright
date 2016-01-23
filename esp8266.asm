/* This is a port of JonesForth, by Richard W.M. Jones
   <rich@annexia.org> http://annexia.org/forth
   who placed the work in the public domain in 2009.

   The port is to the ESP-8266 CPU.
*/
	.include "esp8266.ainc"

/*
	INTRODUCTION ----------------------------------------------------------------------

	FORTH is one of those alien languages which most working programmers regard in the same
	way as Haskell, LISP, and so on.  Something so strange that they'd rather any thoughts
	of it just go away so they can get on with writing this paying code.  But that's wrong
	and if you care at all about programming then you should at least understand all these
	languages, even if you will never use them.

	LISP is the ultimate high-level language, and features from LISP are being added every
	decade to the more common languages.  But FORTH is in some ways the ultimate in low level
	programming.  Out of the box it lacks features like dynamic memory management and even
	strings.  In fact, at its primitive level it lacks even basic concepts like IF-statements
	and loops.

	Why then would you want to learn FORTH?  There are several very good reasons.  First
	and foremost, FORTH is minimal.  You really can write a complete FORTH in, say, 2000
	lines of code.  I don't just mean a FORTH program, I mean a complete FORTH operating
	system, environment and language.  You could boot such a FORTH on a bare PC and it would
	come up with a prompt where you could start doing useful work.  The FORTH you have here
	isn't minimal and uses a Linux process as its 'base PC' (both for the purposes of making
	it a good tutorial). It's possible to completely understand the system.  Who can say they
	completely understand how Linux works, or gcc?

	Secondly FORTH has a peculiar bootstrapping property.  By that I mean that after writing
	a little bit of assembly to talk to the hardware and implement a few primitives, all the
	rest of the language and compiler is written in FORTH itself.  Remember I said before
	that FORTH lacked IF-statements and loops?  Well of course it doesn't really because
	such a lanuage would be useless, but my point was rather that IF-statements and loops are
	written in FORTH itself.

	Now of course this is common in other languages as well, and in those languages we call
	them 'libraries'.  For example in C, 'printf' is a library function written in C.  But
	in FORTH this goes way beyond mere libraries.  Can you imagine writing C's 'if' in C?
	And that brings me to my third reason: If you can write 'if' in FORTH, then why restrict
	yourself to the usual if/while/for/switch constructs?  You want a construct that iterates
	over every other element in a list of numbers?  You can add it to the language.  What
	about an operator which pulls in variables directly from a configuration file and makes
	them available as FORTH variables?  Or how about adding Makefile-like dependencies to
	the language?  No problem in FORTH.  How about modifying the FORTH compiler to allow
	complex inlining strategies -- simple.  This concept isn't common in programming languages,
	but it has a name (in fact two names): "macros" (by which I mean LISP-style macros, not
	the lame C preprocessor) and "domain specific languages" (DSLs).

	This tutorial isn't about learning FORTH as the language.  I'll point you to some references
	you should read if you're not familiar with using FORTH.  This tutorial is about how to
	write FORTH.  In fact, until you understand how FORTH is written, you'll have only a very
	superficial understanding of how to use it.

	So if you're not familiar with FORTH or want to refresh your memory here are some online
	references to read:

	http://en.wikipedia.org/wiki/Forth_%28programming_language%29

	http://galileo.phys.virginia.edu/classes/551.jvn.fall01/primer.htm

	http://wiki.laptop.org/go/Forth_Lessons

	http://www.albany.net/~hello/simple.htm

	Here is another "Why FORTH?" essay: http://www.jwdt.com/~paysan/why-forth.html

	Discussion and criticism of this FORTH here: http://lambda-the-ultimate.org/node/2452

	ACKNOWLEDGEMENTS ----------------------------------------------------------------------

	This code draws heavily on the design of LINA FORTH (http://home.hccnet.nl/a.w.m.van.der.horst/lina.html)
	by Albert van der Horst.  Any similarities in the code are probably not accidental.

	Some parts of this FORTH are also based on this IOCCC entry from 1992:
	http://ftp.funet.fi/pub/doc/IOCCC/1992/buzzard.2.design.
	I was very proud when Sean Barrett, the original author of the IOCCC entry, commented in the LtU thread
	http://lambda-the-ultimate.org/node/2452#comment-36818 about this FORTH.

	And finally I'd like to acknowledge the (possibly forgotten?) authors of ARTIC FORTH because their
	original program which I still have on original cassette tape kept nagging away at me all these years.
	http://en.wikipedia.org/wiki/Artic_Software

	PUBLIC DOMAIN ----------------------------------------------------------------------

	I, the copyright holder of this work, hereby release it into the public domain. This applies worldwide.

	In case this is not legally possible, I grant any entity the right to use this work for any purpose,
	without any conditions, unless such conditions are required by law.

	SETTING UP ----------------------------------------------------------------------

	Let's get a few housekeeping things out of the way.  Firstly because I need to draw lots of
	ASCII-art diagrams to explain concepts, the best way to look at this is using a window which
	uses a fixed width font and is at least this wide:

 <------------------------------------------------------------------------------------------------------------------------>

	Secondly make sure TABS are set to 8 characters.  The following should be a vertical
	line.  If not, sort out your tabs.

		|
	        |
	    	|

	Thirdly I assume that your screen is at least 50 characters high.

	ASSEMBLING ----------------------------------------------------------------------

	If you want to actually run this FORTH, rather than just read it, you will need Linux on an
	i386.  Linux because instead of programming directly to the hardware on a bare PC which I
	could have done, I went for a simpler tutorial by assuming that the 'hardware' is a Linux
	process with a few basic system calls (read, write and exit and that's about all).  i386
	is needed because I had to write the assembly for a processor, and i386 is by far the most
	common.  (Of course when I say 'i386', any 32- or 64-bit x86 processor will do.  I'm compiling
	this on a 64 bit AMD Opteron).

	Again, to assemble this you will need gcc and gas (the GNU assembler).  The commands to
	assemble and run the code (save this file as 'jonesforth.S') are:

	gcc -m32 -nostdlib -static -Wl,-Ttext,0 -Wl,--build-id=none -o jonesforth jonesforth.S
	cat jonesforth.f - | ./jonesforth

	If you want to run your own FORTH programs you can do:

	cat jonesforth.f myprog.f | ./jonesforth

	If you want to load your own FORTH code and then continue reading user commands, you can do:

	cat jonesforth.f myfunctions.f - | ./jonesforth

	ASSEMBLER ----------------------------------------------------------------------

	(You can just skip to the next section -- you don't need to be able to read assembler to
	follow this tutorial).

	However if you do want to read the assembly code here are a few notes about gas (the GNU assembler):

	(1) Register names are prefixed with '%', so %eax is the 32 bit i386 accumulator.  The registers
	    available on i386 are: %eax, %ebx, %ecx, %edx, %esi, %edi, %ebp and %esp, and most of them
	    have special purposes.

	(2) Add, mov, etc. take arguments in the form SRC,DEST.  So mov %eax,%ecx moves %eax -> %ecx

	(3) Constants are prefixed with '$', and you mustn't forget it!  If you forget it then it
	    causes a read from memory instead, so:
	    mov $2,%eax		moves number 2 into %eax
	    mov 2,%eax		reads the 32 bit word from address 2 into %eax (ie. most likely a mistake)

	(4) gas has a funky syntax for local labels, where '1f' (etc.) means label '1:' "forwards"
	    and '1b' (etc.) means label '1:' "backwards".  Notice that these labels might be mistaken
	    for hex numbers (eg. you might confuse 1b with $0x1b).

	(5) 'ja' is "jump if above", 'jb' for "jump if below", 'je' "jump if equal" etc.

	(6) gas has a reasonably nice .macro syntax, and I use them a lot to make the code shorter and
	    less repetitive.

	For more help reading the assembler, do "info gas" at the Linux prompt.

	Now the tutorial starts in earnest.


	ESP-8266 NOTES;
	The ESP-8266 has 16 general-purpose registers, a0 to a-15. Most opcodes take one, two or even three
	registers as argument(s).

	In this implementation of Forth, the i386 registers are mapped to ESO-8266 registers in the following
	way (mostly to simplify porting effort);

	+--------------+-----------------------------------------------------+
	| ESP-8266 Reg | Usage                                               |
	+--------------+-----------------------------------------------------+
	|  a8          | Work register                                       |
	|  a9          | Work register                                       |
	|  a10         | Work register                                       |
	|  a11         | Work register                                       |
	|  a12         | System Environment pointer                          |
	|  a13         | Forth Return Stack pointer                          |
	|  a14         | Forth Instruction pointer                           |
	|  a15         | Forth Data Stack pointer                            |
	+--------------+-----------------------------------------------------+

	THE DICTIONARY ----------------------------------------------------------------------

	In FORTH as you will know, functions are called "words", and just as in other languages they
	have a name and a definition.  Here are two FORTH words:

	: DOUBLE DUP + ;		\ name is "DOUBLE", definition is "DUP +"
	: QUADRUPLE DOUBLE DOUBLE ;	\ name is "QUADRUPLE", definition is "DOUBLE DOUBLE"

	Words, both built-in ones and ones which the programmer defines later, are stored in a dictionary
	which is just a linked list of dictionary entries.

	<--- DICTIONARY ENTRY (HEADER) ----------------------->
	+------------------------+--------+---------- - - - - +----------- - - - -
	| LINK POINTER           | LENGTH/| NAME	      | DEFINITION
	|			 | FLAGS  |     	      |
	+--- (4 bytes) ----------+- byte -+- n bytes  - - - - +----------- - - - -

	I'll come to the definition of the word later.  For now just look at the header.  The first
	4 bytes are the link pointer.  This points back to the previous word in the dictionary, or, for
	the first word in the dictionary it is just a NULL pointer.  Then comes a length/flags byte.
	The length of the word can be up to 31 characters (5 bits used) and the top three bits are used
	for various flags which I'll come to later.  This is followed by the name itself, and in this
	implementation the name is rounded up to a multiple of 4 bytes by padding it with zero bytes.
	That's just to ensure that the definition starts on a 32 bit boundary.

	A FORTH variable called LATEST contains a pointer to the most recently defined word, in
	other words, the head of this linked list.

	DOUBLE and QUADRUPLE might look like this:

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------- - - - -
	| LINK    | 6 | D | O | U | B | L | E | 0 | (definition ...)
	+---------+---+---+---+---+---+---+---+---+------------- - - - -
           ^       len                         padding
	   |
	+--|------+---+---+---+---+---+---+---+---+---+---+---+---+------------- - - - -
	| LINK    | 9 | Q | U | A | D | R | U | P | L | E | 0 | 0 | (definition ...)
	+---------+---+---+---+---+---+---+---+---+---+---+---+---+------------- - - - -
           ^       len                                     padding
           |
           |
	  LATEST

	You should be able to see from this how you might implement functions to find a word in
	the dictionary (just walk along the dictionary entries starting at LATEST and matching
	the names until you either find a match or hit the NULL pointer at the end of the dictionary);
	and add a word to the dictionary (create a new definition, set its LINK to LATEST, and set
	LATEST to point to the new word).  We'll see precisely these functions implemented in
	assembly code later on.

	One interesting consequence of using a linked list is that you can redefine words, and
	a newer definition of a word overrides an older one.  This is an important concept in
	FORTH because it means that any word (even "built-in" or "standard" words) can be
	overridden with a new definition, either to enhance it, to make it faster or even to
	disable it.  However because of the way that FORTH words get compiled, which you'll
	understand below, words defined using the old definition of a word continue to use
	the old definition.  Only words defined after the new definition use the new definition.

	DIRECT THREADED CODE ----------------------------------------------------------------------

	Now we'll get to the really crucial bit in understanding FORTH, so go and get a cup of tea
	or coffee and settle down.  It's fair to say that if you don't understand this section, then you
	won't "get" how FORTH works, and that would be a failure on my part for not explaining it well.
	So if after reading this section a few times you don't understand it, please email me
	(rich@annexia.org).

	Let's talk first about what "threaded code" means.  Imagine a peculiar version of C where
	you are only allowed to call functions without arguments.  (Don't worry for now that such a
	language would be completely useless!)  So in our peculiar C, code would look like this:

	f ()
	{
	  a ();
	  b ();
	  c ();
	}

	and so on.  How would a function, say 'f' above, be compiled by a standard C compiler?
	Probably into assembly code like this.  On the right hand side I've written the actual
	i386 machine code.

	f:
	  CALL a			E8 08 00 00 00
	  CALL b			E8 1C 00 00 00
	  CALL c			E8 2C 00 00 00
	  ; ignore the return from the function for now

	"E8" is the x86 machine code to "CALL" a function.  In the first 20 years of computing
	memory was hideously expensive and we might have worried about the wasted space being used
	by the repeated "E8" bytes.  We can save 20% in code size (and therefore, in expensive memory)
	by compressing this into just:

	08 00 00 00		Just the function addresses, without
	1C 00 00 00		the CALL prefix.
	2C 00 00 00

	On a 16-bit machine like the ones which originally ran FORTH the savings are even greater - 33%.

	[Historical note: If the execution model that FORTH uses looks strange from the following
	paragraphs, then it was motivated entirely by the need to save memory on early computers.
	This code compression isn't so important now when our machines have more memory in their L1
	caches than those early computers had in total, but the execution model still has some
	useful properties].

	Of course this code won't run directly on the CPU any more.  Instead we need to write an
	interpreter which takes each set of bytes and calls it.

	On an i386 machine it turns out that we can write this interpreter rather easily, in just
	two assembly instructions which turn into just 3 bytes of machine code.  Let's store the
	pointer to the next word to execute in the %esi register:

		08 00 00 00	<- We're executing this one now.  %esi is the _next_ one to execute.
	%esi -> 1C 00 00 00
		2C 00 00 00

	The all-important i386 instruction is called LODSL (or in Intel manuals, LODSW).  It does
	two things.  Firstly it reads the memory at %esi into the accumulator (%eax).  Secondly it
	increments %esi by 4 bytes.  So after LODSL, the situation now looks like this:

		08 00 00 00	<- We're still executing this one
		1C 00 00 00	<- %eax now contains this address (0x0000001C)
	%esi -> 2C 00 00 00

	Now we just need to jump to the address in %eax.  This is again just a single x86 instruction
	written JMP *(%eax).  And after doing the jump, the situation looks like:

		08 00 00 00
		1C 00 00 00	<- Now we're executing this subroutine.
	%esi -> 2C 00 00 00

	To make this work, each subroutine is followed by the two instructions 'LODSL; JMP *(%eax)'
	which literally make the jump to the next subroutine.

	And that brings us to our first piece of actual code!  Well, it's a macro.
*/

/* NEXT macro. */
	.macro NEXT

	l32i a8, a14, 0
	addi a14, a14, 4
	l32i a8, a8, 0
	jx a8

// Original Code
//	lodsl
//	jmp *(%eax)
	.endm

/*	The macro is called NEXT.  That's a FORTH-ism.  It expands to those two instructions.

	Every FORTH primitive that we write has to be ended by NEXT.  Think of it kind of like
	a return.

	The above describes what is known as direct threaded code.

	To sum up: We compress our function calls down to a list of addresses and use a somewhat
	magical macro to act as a "jump to next function in the list".  We also use one register (%esi)
	to act as a kind of instruction pointer, pointing to the next function in the list.

	I'll just give you a hint of what is to come by saying that a FORTH definition such as:

	: QUADRUPLE DOUBLE DOUBLE ;

	actually compiles (almost, not precisely but we'll see why in a moment) to a list of
	function addresses for DOUBLE, DOUBLE and a special function called EXIT to finish off.

	At this point, REALLY EAGLE-EYED ASSEMBLY EXPERTS are saying "JONES, YOU'VE MADE A MISTAKE!".

	I lied about JMP *(%eax).  

	INDIRECT THREADED CODE ----------------------------------------------------------------------

	It turns out that direct threaded code is interesting but only if you want to just execute
	a list of functions written in assembly language.  So QUADRUPLE would work only if DOUBLE
	was an assembly language function.  In the direct threaded code, QUADRUPLE would look like:

		+------------------+
		| addr of DOUBLE  --------------------> (assembly code to do the double)
		+------------------+                    NEXT
	%esi ->	| addr of DOUBLE   |
		+------------------+

	We can add an extra indirection to allow us to run both words written in assembly language
	(primitives written for speed) and words written in FORTH themselves as lists of addresses.

	The extra indirection is the reason for the brackets in JMP *(%eax).

	Let's have a look at how QUADRUPLE and DOUBLE really look in FORTH:

	        : QUADRUPLE DOUBLE DOUBLE ;

		+------------------+
		| codeword         |		   : DOUBLE DUP + ;
		+------------------+
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
		| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP   --------------> +------------------+
		| addr of EXIT	   |		   +------------------+            | codeword      -------+
		+------------------+	   %esi -> | addr of +     --------+	   +------------------+   |
						   +------------------+	   |	   | assembly to    <-----+
						   | addr of EXIT     |    |       | implement DUP    |
						   +------------------+	   |	   |	..	      |
									   |	   |    ..            |
									   |	   | NEXT             |
									   |	   +------------------+
									   |
									   +-----> +------------------+
										   | codeword      -------+
										   +------------------+   |
										   | assembly to   <------+
										   | implement +      |
										   | 	..            |
										   | 	..            |
										   | NEXT      	      |
										   +------------------+

	This is the part where you may need an extra cup of tea/coffee/favourite caffeinated
	beverage.  What has changed is that I've added an extra pointer to the beginning of
	the definitions.  In FORTH this is sometimes called the "codeword".  The codeword is
	a pointer to the interpreter to run the function.  For primitives written in
	assembly language, the "interpreter" just points to the actual assembly code itself.
	They don't need interpreting, they just run.

	In words written in FORTH (like QUADRUPLE and DOUBLE), the codeword points to an interpreter
	function.

	I'll show you the interpreter function shortly, but let's recall our indirect
	JMP *(%eax) with the "extra" brackets.  Take the case where we're executing DOUBLE
	as shown, and DUP has been called.  Note that %esi is pointing to the address of +

	The assembly code for DUP eventually does a NEXT.  That:

	(1) reads the address of + into %eax		%eax points to the codeword of +
	(2) increments %esi by 4
	(3) jumps to the indirect %eax			jumps to the address in the codeword of +,
							ie. the assembly code to implement +

		+------------------+
		| codeword         |
		+------------------+
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
		| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP   --------------> +------------------+
		| addr of EXIT	   |		   +------------------+            | codeword      -------+
		+------------------+	   	   | addr of +     --------+	   +------------------+   |
						   +------------------+	   |	   | assembly to    <-----+
					   %esi -> | addr of EXIT     |    |       | implement DUP    |
						   +------------------+	   |	   |	..	      |
									   |	   |    ..            |
									   |	   | NEXT             |
									   |	   +------------------+
									   |
									   +-----> +------------------+
										   | codeword      -------+
										   +------------------+   |
									now we're  | assembly to    <-----+
									executing  | implement +      |
									this	   | 	..            |
									function   | 	..            |
										   | NEXT      	      |
										   +------------------+

	So I hope that I've convinced you that NEXT does roughly what you'd expect.  This is
	indirect threaded code.

	I've glossed over four things.  I wonder if you can guess without reading on what they are?

	.
	.
	.

	My list of four things are: (1) What does "EXIT" do?  (2) which is related to (1) is how do
	you call into a function, ie. how does %esi start off pointing at part of QUADRUPLE, but
	then point at part of DOUBLE.  (3) What goes in the codeword for the words which are written
	in FORTH?  (4) How do you compile a function which does anything except call other functions
	ie. a function which contains a number like : DOUBLE 2 * ; ?

	THE INTERPRETER AND RETURN STACK ------------------------------------------------------------

	Going at these in no particular order, let's talk about issues (3) and (2), the interpreter
	and the return stack.

	Words which are defined in FORTH need a codeword which points to a little bit of code to
	give them a "helping hand" in life.  They don't need much, but they do need what is known
	as an "interpreter", although it doesn't really "interpret" in the same way that, say,
	Java bytecode used to be interpreted (ie. slowly).  This interpreter just sets up a few
	machine registers so that the word can then execute at full speed using the indirect
	threaded model above.

	One of the things that needs to happen when QUADRUPLE calls DOUBLE is that we save the old
	%esi ("instruction pointer") and create a new one pointing to the first word in DOUBLE.
	Because we will need to restore the old %esi at the end of DOUBLE (this is, after all, like
	a function call), we will need a stack to store these "return addresses" (old values of %esi).

	As you will have seen in the background documentation, FORTH has two stacks, an ordinary
	stack for parameters, and a return stack which is a bit more mysterious.  But our return
	stack is just the stack I talked about in the previous paragraph, used to save %esi when
	calling from a FORTH word into another FORTH word.

	In this FORTH, we are using the normal stack pointer (%esp) for the parameter stack.
	We will use the i386's "other" stack pointer (%ebp, usually called the "frame pointer")
	for our return stack.

	I've got two macros which just wrap up the details of using %ebp for the return stack.
	You use them as for example "PUSHRSP %eax" (push %eax on the return stack) or "POPRSP %ebx"
	(pop top of return stack into %ebx).
*/

/* Macros to deal with the return stack. */
	.macro PUSHRSP reg
	addi a13, a13, -4	// push reg on to return stack
	s32i \reg, a13, 0
	.endm

	.macro POPRSP reg
	addi a13, a13, 4
	l32i \reg, a13, 0	// pop top of return stack to reg
	.endm

	.macro PUSH2RSP reg1,reg2
	addi a13, a13, -8	// push reg on to return stack
	s32i \reg1, a13, 4
	s32i \reg2, a13, 0
	.endm

	.macro POP2RSP reg1, reg2
	l32i \reg2, a13, 0	// pop top of return stack to reg
	l32i \reg1, a13, 4	// pop top of return stack to reg
	addi a13, a13, 8	// restore stack pointer
	.endm

/* Macros to deal with the data stack. */
	.macro PUSHDATASTACK reg
	addi a15, a15, -4	// push reg on to data stack
	s32i \reg, a15, 0
	.endm

	.macro POPDATASTACK reg
	l32i \reg, a15, 0	// pop top of data stack to reg
	addi a15, a15, 4
	.endm

	.macro READTOSX reg
	s32i \reg, a15, 0
	.endm

	.macro WRITETOSX reg
	s32i \reg, a15, 0
	.endm

	.macro READTOSY reg
	s32i \reg, a15, 0
	.endm

	.macro WRITETOSY reg
	s32i \reg, a15, 0
	.endm

	.macro READTOSZ reg
	s32i \reg, a15, 0
	.endm

	.macro WRITETOSZ reg
	s32i \reg, a15, 0
	.endm

	.macro READTOST reg
	s32i \reg, a15, 0
	.endm

	.macro WRITETOST reg
	s32i \reg, a15, 0
	.endm

/*
	And with that we can now talk about the interpreter.

	In FORTH the interpreter function is often called DOCOL (I think it means "DO COLON" because
	all FORTH definitions start with a colon, as in : DOUBLE DUP + ;

	The "interpreter" (it's not really "interpreting") just needs to push the old %esi on the
	stack and set %esi to the first word in the definition.  Remember that we jumped to the
	function using JMP *(%eax)?  Well a consequence of that is that conveniently %eax contains
	the address of this codeword, so just by adding 4 to it we get the address of the first
	data word.  Finally after setting up %esi, it just does NEXT which causes that first word
	to run.
*/

/* DOCOL - the interpreter! */
	.text
	.align 4

DOCOL:
	PUSHRSP a14		// push Instruction Pointer on to the return stack
	addi a14, a14, 4	// Instruction Pointer (IP) points to codeword, so make IP point to first data word
	NEXT

// Original i386 Code
// DOCOL:
//	PUSHRSP %esi		// push %esi on to the return stack
//	addl $4,%eax		// %eax points to codeword, so make
//	movl %eax,%esi		// %esi point to first data word
//	NEXT

/*
	Just to make this absolutely clear, let's see how DOCOL works when jumping from QUADRUPLE
	into DOUBLE:

		QUADRUPLE:
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE:
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+       %eax -> | addr of DOCOL    |
	%esi ->	| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+               | etc.             |

	First, the call to DOUBLE calls DOCOL (the codeword of DOUBLE).  DOCOL does this:  It
	pushes the old %esi on the return stack.  %eax points to the codeword of DOUBLE, so we
	just add 4 on to it to get our new %esi:

		QUADRUPLE:
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE:
		| addr of DOUBLE  ---------------> +------------------+
top of return	+------------------+       %eax -> | addr of DOCOL    |
stack points ->	| addr of DOUBLE   |	   + 4 =   +------------------+
		+------------------+	   %esi -> | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+               | etc.             |

	Then we do NEXT, and because of the magic of threaded code that increments %esi again
	and calls DUP.

	Well, it seems to work.

	One minor point here.  Because DOCOL is the first bit of assembly actually to be defined
	in this file (the others were just macros), and because I usually compile this code with the
	text segment starting at address 0, DOCOL has address 0.  So if you are disassembling the
	code and see a word with a codeword of 0, you will immediately know that the word is
	written in FORTH (it's not an assembler primitive) and so uses DOCOL as the interpreter.

	STARTING UP ----------------------------------------------------------------------

	Now let's get down to nuts and bolts.  When we start the program we need to set up
	a few things like the return stack.  But as soon as we can, we want to jump into FORTH
	code (albeit much of the "early" FORTH code will still need to be written as
	assembly language primitives).

	This is what the set up code does.  Does a tiny bit of house-keeping, sets up the
	separate return stack (NB: Linux gives us the ordinary parameter stack already), then
	immediately jumps to a FORTH word called QUIT.  Despite its name, QUIT doesn't quit
	anything.  It resets some internal state and starts reading and interpreting commands.
	(The reason it is called QUIT is because you can call QUIT from your own FORTH code
	to "quit" your program and go back to interpreting).
*/

/* Assembler entry point. */
	.text
	.global forthright_start
	.align 4
/* 	Entry point from C bootstrap.

	The signature of the entry point seen from C looks like;

		void start( void* dataSegment, int dataSegmentSize, int returnStackSize, system_t* systemResources );

	And the C compiler will place the arguments into the a2..a4 registers as follows;

		a2	dataSegment pointer
		a3	dataSegmentSize
		a4	returnStackSize
		a5	systemResources pointter
*/
forthright_start:
	call0 initialize

	.literal .COLDSTART, cold_start
	l32r a14, .COLDSTART		// Initialise interpreter.
	NEXT				// Run interpreter!

	.section .rodata
cold_start:				// High-level code without a codeword.
	.int QUIT


// Original i386 Code
//_start:
//	cld
//	mov %esp,var_S0		// Save the initial data stack pointer in FORTH variable S0.
//	mov $return_stack_top,%ebp // Initialise the return stack.
//	call set_up_data_segment

//	mov $cold_start,%esi	// Initialise interpreter.
//	NEXT			// Run interpreter!
//
//	.section .rodata
// cold_start:			// High-level code without a codeword.
//	.int QUIT

/*
	BUILT-IN WORDS ----------------------------------------------------------------------

	Remember our dictionary entries (headers)?  Let's bring those together with the codeword
	and data words to see how : DOUBLE DUP + ; really looks in memory.

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+--|---------+------------+------------+
           ^       len                         pad  codeword      |
	   |							  V
	  LINK in next word				points to codeword of DUP
	
	Initially we can't just write ": DOUBLE DUP + ;" (ie. that literal string) here because we
	don't yet have anything to read the string, break it up at spaces, parse each word, etc. etc.
	So instead we will have to define built-in words using the GNU assembler data constructors
	(like .int, .byte, .string, .ascii and so on -- look them up in the gas info page if you are
	unsure of them).

	The long way would be:

	.int <link to previous word>
	.byte 6			// len
	.ascii "DOUBLE"		// string
	.byte 0			// padding
DOUBLE: .int DOCOL		// codeword
	.int DUP		// pointer to codeword of DUP
	.int PLUS		// pointer to codeword of +
	.int EXIT		// pointer to codeword of EXIT

	That's going to get quite tedious rather quickly, so here I define an assembler macro
	so that I can just write:

	defword "DOUBLE",6,,DOUBLE
	.align 4
	.int DUP,PLUS,EXIT

	and I'll get exactly the same effect.

	Don't worry too much about the exact implementation details of this macro - it's complicated!
*/

/* Flags - these are discussed later. */
	.set F_IMMED,0x80
	.set F_HIDDEN,0x20
	.set F_LENMASK,0x1f	// length mask

	// Store the chain of links.
	.set link,0

	.macro defword name, namelen, flags=0, label
	.section .rodata
	.align 4
	.globl name_\label
name_\label :
	.int link		// link
	.set link,name_\label
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.align 4		// padding to next 4 byte boundary
	.globl \label
\label :
	.int DOCOL		// codeword - the interpreter
	// list of word pointers follow
	.endm

/*
	Similarly I want a way to write words written in assembly language.  There will quite a few
	of these to start with because, well, everything has to start in assembly before there's
	enough "infrastructure" to be able to start writing FORTH words, but also I want to define
	some common FORTH words in assembly language for speed, even though I could write them in FORTH.

	This is what DUP looks like in memory:

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+------------+
	| LINK    | 3 | D | U | P | code_DUP ---------------------> points to the assembly
	+---------+---+---+---+---+------------+		    code used to write DUP,
           ^       len              codeword			    which ends with NEXT.
	   |
	  LINK in next word

	Again, for brevity in writing the header I'm going to write an assembler macro called defcode.
	As with defword above, don't worry about the complicated details of the macro.
*/

	.macro defcode name, namelen, flags=0, label
	.section .rodata
	.align 4
	.globl name_\label
name_\label :
	.int link		// link
	.set link,name_\label
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.align 4		// padding to next 4 byte boundary
	.globl \label
\label :
	.int code_\label	// codeword
	.text
	//.align 4
	.globl code_\label
code_\label :			// assembler code follows
	.endm

/*
	Now some easy FORTH primitives.  These are written in assembly for speed.  If you understand
	i386 assembly language then it is worth reading these.  However if you don't understand assembly
	you can skip the details.
*/

	defcode "DROP",4,,DROP
	addi a15,a15,4		// drop top of stack
	NEXT

	defcode "SWAP",4,,SWAP
	READTOSX a8
	READTOSY a9
	WRITETOSX a9
	WRITETOSY a8
	NEXT

	defcode "DUP",3,,DUP
	READTOSX a8
	PUSHDATASTACK a8
	NEXT

	defcode "OVER",4,,OVER
	READTOSY a8
	PUSHDATASTACK a8
	NEXT

	defcode "ROT",3,,ROT
	READTOSX a8
	READTOSY a9
	READTOSZ a10
	WRITETOSZ a9
	WRITETOSY a8
	WRITETOSX a10
	NEXT

	defcode "-ROT",4,,NROT
	READTOSX a8
	READTOSY a9
	READTOSZ a10
	WRITETOSZ a8
	WRITETOSY a10
	WRITETOSX a9
	NEXT

	defcode "2DROP",5,,TWODROP // drop top two elements of stack
	addi a15,a15,8		// drop 2 entries of top of stack
	NEXT

	defcode "2DUP",4,,TWODUP // duplicate top two elements of stack
	READTOSX a8
	READTOSX a9
	PUSHDATASTACK a9
	PUSHDATASTACK a8
	NEXT

	defcode "2SWAP",5,,TWOSWAP // swap top two pairs of elements of stack
	READTOSX a8
	READTOSY a9
	READTOSZ a10
	READTOST a11
	WRITETOSX a10
	WRITETOSY a11
	WRITETOSZ a8
	WRITETOST a9
	NEXT

	defcode "?DUP",4,,QDUP	// duplicate top of stack if non-zero
	READTOSX a8
	beqz a8, L1
	PUSHDATASTACK a8
L1:	NEXT

	defcode "1+",2,,INCR
	READTOSX a8
	addi a8, a8, 1		// add 1
	WRITETOSX a8
	NEXT

	defcode "1-",2,,DECR
	READTOSX a8
	addi a8, a8, -1		// add -1
	WRITETOSX a8
	NEXT

	defcode "4+",2,,INCR4
	READTOSX a8
	addi a8, a8, 4		// add 4
	WRITETOSX a8
	NEXT

	defcode "4-",2,,DECR4
	READTOSX a8
	addi a8, a8, -4		// add -4
	WRITETOSX a8
	NEXT

	defcode "+",1,,ADD
	POPDATASTACK a8
	READTOSX a9
	add a8, a8, a9		// Add
	WRITETOSX a8
	NEXT

	defcode "-",1,,SUB
	POPDATASTACK a8
	READTOSX a9
	sub a8, a8, a9		// Subtract
	WRITETOSX a8
	NEXT

	defcode "*",1,,MUL
	POPDATASTACK a8
	READTOSX a9
	mull a8, a8, a9		// Multiply
	WRITETOSX a8
	NEXT

/*
	In this FORTH, only /MOD and U/MOD is primitive.  Later we will define the /, MOD and other words in
	terms of the primitives /MOD and U/MOD.  The design of the i386 assembly instructions idiv and div which
	leave both quotient and remainder makes this the obvious choice.
*/

/* Taking these two WORDS out, as they are not as neatly implemented on ESP8266 as they are for i386.
   Will later see what is depending on these, and move those WORDS into the native space instead.

	defcode "/MOD",4,,DIVMOD
	pop %ebx
	pop %eax
	cdq
	idivl %ebx
	push %edx		// push remainder
	push %eax		// push quotient
	NEXT

	defcode "U/MOD",5,,UDIVMOD
	xor %edx, %edx
	pop %ebx
	pop %eax
	divl %ebx
	push %edx	// push remainder
	push %eax	// push quotient
	NEXT
*/

/*
	Lots of comparison operations like =, <, >, etc..

	ANS FORTH says that the comparison words should return all (binary) 1's for
	TRUE and all 0's for FALSE.  This is a bit of a strange convention for C
	programmers ...
	Anyway, -1 meaning TRUE and 0 meaning FALSE.
*/

	defcode "=",1,,EQU	// top two words are equal?
	POPDATASTACK a8
	READTOSX a9
        movi a10,0		// Set a10 to FALSE
	bne a8, a9, L2		// If Not Equal, branch
	movi a10, -1		// Set a10 to TRUE
L2:	WRITETOSX a10
	NEXT

	defcode "<>",2,,NEQU	// top two words are not equal?
	POPDATASTACK a8
	READTOSX a9
	movi a10,0		// Set a10 to FALSE
	beq a8,a9, L3		// If Equal, branch
	movi a10, -1		// Set a10 to TRUE
L3:	WRITETOSX a10
	NEXT

	defcode "<",1,,LT
	POPDATASTACK a8
	READTOSX a9
	movi a10, 0		// Set a10 to FALSE
	bge a9, a8, L4		// If a9 >= a8, branch
	movi a10, -1		// Set a10 to TRUE
L4:	WRITETOSX a10
	NEXT

	defcode ">",1,,GT
	POPDATASTACK a8
	READTOSX a9
	movi a10, 0		// Set a10 to FALSE
	bge a8, a9, L5		// If a8 >= a9, branch
	movi a10, -1		// Set a10 to TRUE
L5:	WRITETOSX a10
	NEXT

	defcode "<=",2,,LE
	POPDATASTACK a8
	READTOSX a9
	addi a15,a15,4		// Remove one entry from stack
	movi a10, 0		// Set a10 to FALSE
	blt a8, a9, L6		// If a8 < a9, branch
	movi a10, -1		// Set a10 to TRUE
L6:	WRITETOSX a10
	NEXT

	defcode ">=",2,,GE
	POPDATASTACK a8
	READTOSX a9
	movi a10, 0		// Set a10 to FALSE
	blt a9, a8, L7		// If a9 < a8 , branch
	movi a10, -1		// Set a10 to TRUE
L7:	WRITETOSX a10
	NEXT

	defcode "0=",2,,ZEQU	// top of stack equals 0?
	READTOSX a8
	movi a9, -1		// Set result to TRUE
	beqz a8, L8		// Test if TOS was 0, jump if so,
	movi a9, 0		// Set result to FALSE
L8:	WRITETOSX a9
	NEXT

	defcode "0<>",3,,ZNEQU	// top of stack not 0?
	READTOSX a8
	movi a9, -1		// Set result to TRUE
	bnez a8, L9		// Test if TOS was NOT 0, jump if so,
	movi a9, 0		// Set result to FALSE
L9:	WRITETOSX a9
	NEXT

	defcode "0<",2,,ZLT	// comparisons with 0
	READTOSX a8
	movi a9, 0		// Set result to FALSE
	bge a8, a9, L10		// Test if TOS >= 0, jump if so,
	movi a9, -1		// Set result to TRUE
L10:	WRITETOSX a9
	NEXT

	defcode "0>",2,,ZGT
	READTOSX a8
	movi a9, 0		// Set result to FALSE
	bge a9, a8, L11		// Test if 0 >= TOS, jump if so,
	movi a9, -1		// Set result to TRUE
L11:	WRITETOSX a9
	NEXT

	defcode "0<=",3,,ZLE
	READTOSX a8
	movi a9, 0		// Set result to FALSE
	blt a9, a8, L12		// Test if 0 < TOS, jump if so,
	movi a9, -1		// Set result to TRUE
L12:	WRITETOSX a9
	NEXT

	defcode "0>=",3,,ZGE
	READTOSX a8
	movi a9, 0		// Set result to FALSE
	blt a8, a9, L13		// Test if TOS < 0, jump if so,
	movi a9, -1		// Set result to TRUE
L13:	WRITETOSX a9
	NEXT

	defcode "AND",3,,AND	// bitwise AND
	POPDATASTACK a8
	READTOSX a9
	and a8, a8, a9		// And
	WRITETOSX a8
	NEXT

	defcode "OR",2,,OR	// bitwise OR
	POPDATASTACK a8
	READTOSX a9
	or a8, a8, a9		// Or
	WRITETOSX a8
	NEXT

	defcode "XOR",3,,XOR	// bitwise XOR
	POPDATASTACK a8
	READTOSX a9
	xor a8, a8, a9		// Xor
	WRITETOSX a8
	NEXT

	defcode "INVERT",6,,INVERT // this is the FORTH bitwise "NOT" function (cf. NEGATE and NOT)
	READTOSX a8
	movi a9, 0		// load a9 with zero
	addi a9, a9, -1		// a9 is now all zero
	xor a8, a8, a9		// Negate all bits
	WRITETOSX a8
	NEXT

/*
	RETURNING FROM FORTH WORDS ----------------------------------------------------------------------

	Time to talk about what happens when we EXIT a function.  In this diagram QUADRUPLE has called
	DOUBLE, and DOUBLE is about to exit (look at where %esi is pointing):

		QUADRUPLE
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
		| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+	   	   | addr of +        |
						   +------------------+
					   %esi -> | addr of EXIT     |
						   +------------------+

	What happens when the + function does NEXT?  Well, the following code is executed.
*/

	defcode "EXIT",4,,EXIT
	POPRSP a14		// pop return stack into %esi
	NEXT

/*
	EXIT gets the old %esi which we saved from before on the return stack, and puts it in %esi.
	So after this (but just before NEXT) we get:

		QUADRUPLE
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
	%esi ->	| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+	   	   | addr of +        |
						   +------------------+
						   | addr of EXIT     |
						   +------------------+

	And NEXT just completes the job by, well, in this case just by calling DOUBLE again :-)

	LITERALS ----------------------------------------------------------------------

	The final point I "glossed over" before was how to deal with functions that do anything
	apart from calling other functions.  For example, suppose that DOUBLE was defined like this:

	: DOUBLE 2 * ;

	It does the same thing, but how do we compile it since it contains the literal 2?  One way
	would be to have a function called "2" (which you'd have to write in assembler), but you'd need
	a function for every single literal that you wanted to use.

	FORTH solves this by compiling the function using a special word called LIT:

	+---------------------------+-------+-------+-------+-------+-------+
	| (usual header of DOUBLE)  | DOCOL | LIT   | 2     | *     | EXIT  |
	+---------------------------+-------+-------+-------+-------+-------+

	LIT is executed in the normal way, but what it does next is definitely not normal.  It
	looks at %esi (which now points to the number 2), grabs it, pushes it on the stack, then
	manipulates %esi in order to skip the number as if it had never been there.

	What's neat is that the whole grab/manipulate can be done using a single byte single
	i386 instruction, our old friend LODSL.  Rather than me drawing more ASCII-art diagrams,
	see if you can find out how LIT works:
*/

	defcode "LIT",3,,LIT
	l32i a8, a14, 0		// Get next command
	PUSHDATASTACK a8

// Original i386 Code
//	// %esi points to the next command, but in this case it points to the next
//	// literal 32 bit integer.  Get that literal into %eax and increment %esi.
//	// On x86, it's a convenient single byte instruction!  (cf. NEXT macro)
//	lodsl
//	push %eax		// push the literal number on to stack
	NEXT

/*
	MEMORY ----------------------------------------------------------------------

	As important point about FORTH is that it gives you direct access to the lowest levels
	of the machine.  Manipulating memory directly is done frequently in FORTH, and these are
	the primitive words for doing it.
*/

	defcode "!",1,,STORE
	POPDATASTACK a8		// address to store at
	POPDATASTACK a9		// data to store there
	s32i a9, a8, 0		// store it
	NEXT

	defcode "@",1,,FETCH
	POPDATASTACK a8		// address to fetch
	l32i a9, a8, 0		// fetch it
	PUSHDATASTACK a9	// push value onto stack
	NEXT

	defcode "+!",2,,ADDSTORE
	POPDATASTACK a8		// address
	POPDATASTACK a9		// the amount to add
	l32i a10, a8, 0		// fetch it
	add a10, a10, a9	// add
	s32i a10, a8, 0		// store it back
	NEXT

	defcode "-!",2,,SUBSTORE
	POPDATASTACK a8		// address
	POPDATASTACK a9		// the amount to subtract
	l32i a10, a8, 0		// fetch it
	sub a10, a10, a9	// subtract
	s32i a10, a8, 0		// store it back
	NEXT

/*
	! and @ (STORE and FETCH) store 32-bit words.  It's also useful to be able to read and write bytes
	so we also define standard words C@ and C!.
	Byte-oriented operations only work on architectures which permit them (i386 is one of those).
 */

	defcode "C!",2,,STOREBYTE
	POPDATASTACK a8		// address to store at
	POPDATASTACK a9		// data to store there
	s8i a9, a8, 0		// store it
	NEXT

	defcode "C@",2,,FETCHBYTE
	POPDATASTACK a8		// address to fetch
	l8ui a9, a8, 0		// fetch it
	PUSHDATASTACK a9	// push value onto stack
	NEXT

/* C@C! is a useful byte copy primitive. */
	defcode "C@C!",4,,CCOPY
	READTOSX a8		// read destination address
	READTOSY a9		// read source address
	l8ui a10, a9, 0		// fetch
	s8i a10, a8, 0		// store
	addi a8, a8, 1		// inc dest address
	addi a9, a8, 1		// inc source address
	WRITETOSX a8		// write destination address
	WRITETOSY a9		// write source address
	NEXT

/* and CMOVE is a block copy operation. */
	defcode "CMOVE",5,,CMOVE
	POPDATASTACK a8		// length
	POPDATASTACK a9		// destination address
	POPDATASTACK a10	// source address
L14:	l8ui a11,a10,0		// fetch a byte
	s8i a11,a9,0		// store the byte
	addi a8, a8, -1		// decrement
	bnez a8, L14		// loop
	NEXT

/*
	BUILT-IN VARIABLES ----------------------------------------------------------------------

	These are some built-in variables and related standard FORTH words.  Of these, the only one that we
	have discussed so far was LATEST, which points to the last (most recently defined) word in the
	FORTH dictionary.  LATEST is also a FORTH word which pushes the address of LATEST (the variable)
	on to the stack, so you can read or write it using @ and ! operators.  For example, to print
	the current value of LATEST (and this can apply to any FORTH variable) you would do:

	LATEST @ . CR

	To make defining variables shorter, I'm using a macro called defvar, similar to defword and
	defcode above.  (In fact the defvar macro uses defcode to do the dictionary header).
*/

	.macro defvar name, namelen, flags=0, label, initial=0
	defcode \name,\namelen,\flags,\label
	l32r a8, var_\name
	PUSHDATASTACK a8
	NEXT
	.data
	.align 4
var_\name :
	.literal .ADDR_\name, var_\name
	.int \initial
	.endm

/*
	The built-in variables are:

	STATE		Is the interpreter executing code (0) or compiling a word (non-zero)?
	LATEST		Points to the latest (most recently defined) word in the dictionary.
	DP		Points to the next free byte of memory.  When compiling, compiled words go here.
	S0		Stores the address of the top of the parameter stack.
	BASE		The current base for printing and reading numbers.

*/
	defvar "STATE",5,,STATE
	defvar "DP",2,,DP
	defvar "LATEST",6,,LATEST,name_EXECUTE // EXECUTE must be last in built-in dictionary
	defvar "S0",2,,SZ
	defvar "BASE",4,,BASE,10

/*
	BUILT-IN CONSTANTS ----------------------------------------------------------------------

	It's also useful to expose a few constants to FORTH.  When the word is executed it pushes a
	constant value on the stack.

	The built-in constants are:

	VERSION		Is the current version of this FORTH.
	R0		The address of the top of the return stack.
	DOCOL		Pointer to DOCOL.
	F_IMMED		The IMMEDIATE flag's actual value.
	F_HIDDEN	The HIDDEN flag's actual value.
	F_LENMASK	The length mask in the flags/len byte.

	SYS_*		and the numeric codes of various Linux syscalls (from <asm/unistd.h>)
*/

	.macro defconst name, namelen, flags=0, label, value
	defcode \name,\namelen,\flags,\label
	movi a8, \value
	PUSHDATASTACK a8
	NEXT
	.endm

	defconst "VERSION",7,,VERSION,FORTHRIGHT_VERSION
	defconst "DOCOL",5,,__DOCOL,DOCOL
	defconst "F_IMMED",7,,__F_IMMED,F_IMMED
	defconst "F_HIDDEN",8,,__F_HIDDEN,F_HIDDEN
	defconst "F_LENMASK",9,,__F_LENMASK,F_LENMASK

/* No system support
	defconst "SYS_EXIT",8,,SYS_EXIT,__NR_exit
	defconst "SYS_OPEN",8,,SYS_OPEN,__NR_open
	defconst "SYS_CLOSE",9,,SYS_CLOSE,__NR_close
	defconst "SYS_READ",8,,SYS_READ,__NR_read
	defconst "SYS_WRITE",9,,SYS_WRITE,__NR_write
	defconst "SYS_CREAT",9,,SYS_CREAT,__NR_creat
	defconst "SYS_BRK",7,,SYS_BRK,__NR_brk

	defconst "O_RDONLY",8,,__O_RDONLY,0
	defconst "O_WRONLY",8,,__O_WRONLY,1
	defconst "O_RDWR",6,,__O_RDWR,2
	defconst "O_CREAT",7,,__O_CREAT,0100
	defconst "O_EXCL",6,,__O_EXCL,0200
	defconst "O_TRUNC",7,,__O_TRUNC,01000
	defconst "O_APPEND",8,,__O_APPEND,02000
	defconst "O_NONBLOCK",10,,__O_NONBLOCK,04000
*/

/*
	RETURN STACK ----------------------------------------------------------------------

	These words allow you to access the return stack.  Recall that the register %ebp always points to
	the top of the return stack.
*/
	defcode "R0",2,,RZ
	addi a8, a12, system_t_return_stack_size	// add offset to system_t pointer to get the location of top
	 						// of the return stack
	PUSHDATASTACK a8
	NEXT

	defcode ">R",2,,TOR
	POPDATASTACK a8		// pop parameter stack into a8
	PUSHRSP a8		// push it on to the return stack
	NEXT

	defcode "R>",2,,FROMR
	POPRSP a8		// pop return stack on to a8
	PUSHDATASTACK a8	// and push on to parameter stack
	NEXT

	defcode "RSP@",4,,RSPFETCH
	PUSHDATASTACK a13
	NEXT

	defcode "RSP!",4,,RSPSTORE
	POPDATASTACK a13
	NEXT

	defcode "RDROP",5,,RDROP
	addi a13, a13, 4		// pop return stack and throw away
	NEXT

/*
	PARAMETER (DATA) STACK ----------------------------------------------------------------------

	These functions allow you to manipulate the parameter stack.  Recall that Linux sets up the parameter
	stack for us, and it is accessed through %esp.
*/

	defcode "DSP@",4,,DSPFETCH
	PUSHDATASTACK a15
	NEXT

	defcode "DSP!",4,,DSPSTORE
	POPDATASTACK a15
	NEXT

/*
	INPUT AND OUTPUT ----------------------------------------------------------------------

	These are our first really meaty/complicated FORTH primitives.  I have chosen to write them in
	assembler, but surprisingly in "real" FORTH implementations these are often written in terms
	of more fundamental FORTH primitives.  I chose to avoid that because I think that just obscures
	the implementation.  After all, you may not understand assembler but you can just think of it
	as an opaque block of code that does what it says.

	Let's discuss input first.

	The FORTH word KEY reads the next byte from stdin (and pushes it on the parameter stack).
	So if KEY is called and someone hits the space key, then the number 32 (ASCII code of space)
	is pushed on the stack.

	In FORTH there is no distinction between reading code and reading input.  We might be reading
	and compiling code, we might be reading words to execute, we might be asking for the user
	to type their name -- ultimately it all comes in through KEY.

	The implementation of KEY uses an input buffer of a certain size (defined at the end of this
	file).  It calls the Linux read(2) system call to fill this buffer and tracks its position
	in the buffer using a couple of variables, and if it runs out of input buffer then it refills
	it automatically.  The other thing that KEY does is if it detects that stdin has closed, it
	exits the program, which is why when you hit ^D the FORTH system cleanly exits.

     buffer			      bufftop
	|				 |
	V				 V
	+-------------------------------+--------------------------------------+
	| INPUT READ FROM STDIN ....... | unused part of the buffer            |
	+-------------------------------+--------------------------------------+
	                  ^
			  |
		       currkey (next character to read)

	<---------------------- BUFFER_SIZE (4096 bytes) ---------------------->
*/

	DECL_VAR currkey,4,4		// Pointer to next key in buffer
	DECL_VAR bufftop,4,4		// Pointer to next key in buffer

	.text
	defcode "KEY",3,,KEY
	call0 _KEY
	PUSHDATASTACK a2		// push return value on stack
	NEXT
_KEY:
	READ_VAR a8, currkey
	READ_VAR a9, bufftop
	bge a8, a9, L15
	l8ui a2, a8, 0			// get next key from input buffer
	addi a8, a8, 1		// increment currkey
	WRITE_VAR a8, a9, currkey	// save currkey
	ret

L15:	// Out of input; use read(2) to fetch more input from C routine readChar().
	l32i a2, a12, system_t_input_buffer
	l32i a3, a12, system_t_input_buffer_size

	// Here we are already one subroutine down, so we need to save the return address on the stack.
	addi sp, sp, -4			// adjust stack pointer
	s32i a0, sp, 4			// save return address
	call0 readChars			// call C readChars()
	l32i a0, sp, 4			// get the saved return address
	addi sp, sp, 4			// restore stack pointer

	movi a10, 0			// Set
	blt a2, a10, EXIT_TO_C		// If an error is returned, abort and exit Forth
	add a9, a2, a8			// compute bufftop
	WRITE_VAR a9, a8, bufftop	// save bufftop
	j _KEY

EXIT_TO_C:	// Error or end of input: exit the program.
	READ_VAR a0, c_return_address
	READ_VAR a1, c_stack_address
	ret


/*
	By contrast, output is much simpler.  The FORTH word EMIT writes out a single byte to stdout.
	This implementation just uses the write system call.  No attempt is made to buffer output, but
	it would be a good exercise to add it.
*/

	defcode "EMIT",4,,EMIT
	POPDATASTACK a2
	call0 _EMIT
	NEXT
_EMIT:
	// a2 is already containing the value to pass to C

	SAFE_CALL putChar		// call C putChar()
	movi a10, 0			// Set
	blt a2, a10, EXIT_TO_C		// If an error is returned, abort and exit Forth
	ret

/*
	Back to input, WORD is a FORTH word which reads the next full word of input.

	What it does in detail is that it first skips any blanks (spaces, tabs, newlines and so on).
	Then it calls KEY to read characters into an internal buffer until it hits a blank.  Then it
	calculates the length of the word it read and returns the address and the length as
	two words on the stack (with the length at the top of stack).

	Notice that WORD has a single internal buffer which it overwrites each time (rather like
	a static C string).  Also notice that WORD's internal buffer is just 32 bytes long and
	there is NO checking for overflow.  31 bytes happens to be the maximum length of a
	FORTH word that we support, and that is what WORD is used for: to read FORTH words when
	we are compiling and executing code.  The returned strings are not NUL-terminated.

	Start address+length is the normal way to represent strings in FORTH (not ending in an
	ASCII NUL character as in C), and so FORTH strings can contain any character including NULs
	and can be any length.

	WORD is not suitable for just reading strings (eg. user input) because of all the above
	peculiarities and limitations.

	Note that when executing, you'll see:
	WORD FOO
	which puts "FOO" and length 3 on the stack, but when compiling:
	: BAR WORD FOO ;
	is an error (or at least it doesn't do what you might expect).  Later we'll talk about compiling
	and immediate mode, and you'll understand why.
*/

	defcode "WORD",4,,WORD
	call0 _WORD
	PUSHDATASTACK a2		// push base address
	PUSHDATASTACK a3		// push length
	NEXT

_WORD:
	/* Search for first non-blank character.  Also skip \ comments. */
L16:
	SAFE_CALL _KEY			// get next key, returned in %eax
	movi a8, '\\'			// start of a comment?
	beq a2, a8, L18			// if so, skip the comment
	movi a8, ' '+1			// end of word?
	blt a2, a8, L16			// if so, keep looking

	/* Search for the end of the word, storing chars as we go. */
	ENV a8, system_t_word_buffer			// pointer to return buffer
	PUT_ENV a8, system_t_word_buffer_ptr		// set up the pointer
	ENV a9, system_t_word_buffer_size		// ensure no overrun of buffer
	PUT_ENV a9, system_t_word_buffer_counter	// set up the pointer
L17:
	s32i a2, a8, 0					// add character to return buffer
	addi a8, a8, 1
	PUT_ENV a8, system_t_word_buffer_ptr
	addi a9, a9, -1
	PUT_ENV a9, system_t_word_buffer_counter
	SAFE_CALL _KEY					// get next key, returned in %al
	ENV a8, system_t_word_buffer_ptr
	ENV a9, system_t_word_buffer_counter
	beqz a9, L19					// Ran out of word buffer space, abort and return result.
	movi a10, ' '+1					// is whitespace?
	bge a2, a10, L17				// if not, keep looping

L19:	/* Return the word pointer in a2 and length in a3. */
	ENV a2, system_t_word_buffer			// Word base address
	ENV a3, system_t_word_buffer_ptr
	sub a3, a2, a3					// Subtract the pointers to get the length.
	ret

	/* Code to skip \ comments to end of the current line. */
L18:
	SAFE_CALL _KEY
	movi a8, '\n'					// end of line yet?
	bne a2, a8, L18
	j L16

/*
	As well as reading in words we'll need to read in numbers and for that we are using a function
	called NUMBER.  This parses a numeric string such as one returned by WORD and pushes the
	number on the parameter stack.

	The function uses the variable BASE as the base (radix) for conversion, so for example if
	BASE is 2 then we expect a binary number.  Normally BASE is 10.

	If the word starts with a '-' character then the returned value is negative.

	If the string can't be parsed as a number (or contains characters outside the current BASE)
	then we need to return an error indication.  So NUMBER actually returns two items on the stack.
	At the top of stack we return the number of unconverted characters (ie. if 0 then all characters
	were converted, so there is no error).  Second from top of stack is the parsed number or a
	partial value if there was an error.
*/
	defcode "NUMBER",6,,NUMBER
	POPDATASTACK a3			// length of string
	POPDATASTACK a2			// start address of string
	call0 _NUMBER
	PUSHDATASTACK a2		// parsed number
	PUSHDATASTACK a3		// number of unparsed characters (0 = no error)
	NEXT

/* Parses a string to a integer number

   Inarguments
      a2 : address of string
      a3 : length of string

   Return values
      a2 : the parsed number
      a3 : unparsed characters. Should be 0 for success.
*/
_NUMBER:
	movi a8, 0
	movi a9, 0

	beqz a3, L25		// trying to parse a zero-length string is an error, but will return 0.

	READ_VAR a11, BASE	// get BASE into a11

	// Check if first character is '-'.
	l8ui a10, a2, 0		// a10 = first character in string
	addi a2, a2, 1		// inc char pointer
	PUSHDATASTACK a8	// push 0 on stack
	movi a7, '-'		// negative number?
	bne a10, a7, L21
	POPDATASTACK a8
	PUSHDATASTACK a7	// push <> 0 on stack, indicating negative
	addi a3, a3, -1		// decrement character counter
	bnez a3, L20

	POPDATASTACK a8		// error: string is only '-'., clean up stack
	movi a3, 1		// return an error
	movi a2, 0		// return value 0
	ret

	// Loop reading digits.
L20:	mull a8, a8, a11	// %eax *= BASE
	l8ui a10, a2, 0		// a10 = next character in string
	addi a2, a2, 1		// inc char pointer

	// Convert 0-9, A-Z to a number 0-35.
L21:
	movi a7, '0'
	sub a10, a10, a7	// < '0'?
	bltz a10, L23
	movi a7, 10
	blt a10, a7, L22	// <= '9'?
	addi a10, a10, -17	// < 'A'? (17 is 'A'-'0')
	bltz a10, L23
	addi a10, a10, 10	// A=10, B=11, C=12....

L22:	bge a10, a11, L23	// >= BASE?

	// OK, so add it to %eax and loop.
	add a8, a8, a10
	addi a3, a3, -1		// decrement character counter
	bnez a3, L20

	// Negate the result if first character was '-' (saved on the stack).
L23:	POPDATASTACK a10
	beqz a10, L24
	neg a8, a8

L24:	mov a2, a8
	ret

L25:	movi a2, 0
	movi a3, 0
	ret

/*
	DICTIONARY LOOK UPS ----------------------------------------------------------------------

	We're building up to our prelude on how FORTH code is compiled, but first we need yet more infrastructure.

	The FORTH word (FIND) takes a string (a word as parsed by WORD -- see above) and looks it up in the
	dictionary.  What it actually returns is the address of the dictionary header, if it finds it, or 0 if it
	didn't.

	This word is call (FIND) but not simply FIND because FIND is a standard ANS Forth word which does a little
	more than (FIND).

	So if DOUBLE is defined in the dictionary, then WORD DOUBLE (FIND) returns the following pointer:

    pointer to this
	|
	|
	V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+

	See also >CFA and >DFA.

	(FIND) doesn't find dictionary entries which are flagged as HIDDEN.  See below for why.
*/

	defcode "(FIND)",6,,PAREN_FIND
	POPDATASTACK a3				// a3 = length
	POPDATASTACK a2				// a2 = address
	call0 _FIND
	PUSHDATASTACK a2			// a2 = address of dictionary entry (or NULL)
	NEXT

_FIND:
	// Now we start searching backwards through the dictionary for this word.
	READ_VAR a11, LATEST			// LATEST points to name header of the latest word in the dictionary
L26:	beqz a11, L28				// NULL pointer?  (end of the linked list)

	// Compare the length expected and the length of the word.
	// Note that if the F_HIDDEN flag is set on the word, then by a bit of trickery
	// this won't pick the word (the length will appear to be wrong).
	l8ui a8, a11, 4				// a8 = flags+length field
	movi a6, F_HIDDEN | F_LENMASK		// trickery to use F_HIDDEN included in length.
	and a8, a8, a6				// a8 = name length
	bne a8, a3, L27				// Length (i.e. hidden must also be false) is the same?

	// Compare the strings in detail.
	mov a6, a2				// a6 = pointer to word searched
	mov a7, a3				// a7 = characters to compare
	mov a10, a11				// pointer to current record
L29:
	l8ui a8, a10, 5				// read char in current record
	l8ui a9, a6, 0				// read char we are looking for
	addi a10, a10, 1			// inc pointer in current record
	addi a6, a6, 1				// inc pointer in Word
	bne a8, a9, L27				// Not the same.
	addi a7, a7, -1				// dec char counter
	bnez a7, L29				// loop all characters

	// The strings are the same - return the header pointer in a2
	mov a2,a11
	ret

L27:	l32i a11, a11, 0			// Move back through the link field to the previous word
	j L26					// .. and loop.

L28:	// Not found.
	xor a2, a2, a2				// Return zero to indicate not found.
	ret

/*
	(FIND) returns the dictionary pointer, but when compiling we need the codeword pointer (recall
	that FORTH definitions are compiled into lists of codeword pointers).  The standard FORTH
	word >CFA turns a dictionary pointer into a codeword pointer.

	The example below shows the result of:

		WORD DOUBLE (FIND) >CFA

	(FIND) returns a pointer to this
	|				>CFA converts it to a pointer to this
	|					   |
	V					   V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
						   codeword

	Notes:

	Because names vary in length, this isn't just a simple increment.

	In this FORTH you cannot easily turn a codeword pointer back into a dictionary entry pointer, but
	that is not true in most FORTH implementations where they store a back pointer in the definition
	(with an obvious memory/complexity cost).  The reason they do this is that it is useful to be
	able to go backwards (codeword -> dictionary entry) in order to decompile FORTH definitions
	quickly.

	What does CFA stand for?  My best guess is "Code Field Address".
*/

	defcode ">CFA",4,,TCFA
	POPDATASTACK a2
	call0 _TCFA
	PUSHDATASTACK a2
	NEXT
/* Gets the Codeword pointer of a Dictionary Pointer
     Inarguments
        a2 : pointer to Dictionary entry

     Return values
        a2 : pointer to Codeword
*/
_TCFA:
	l8ui a8, a2, 5		// Read length+flags
	movi a9, F_LENMASK	// trickery to use F_HIDDEN included in length.
	and a8, a8, a9		// mask length
	add a9, a2, a8		// move beyond the word
	addi a9, a9, 3		// pad 3 bytes
	movi a8, ~3		// mask last two bits for 4-byte alignment
	and a2, a9, a8		// a2 pointing to 'codeword'
	ret

/*
	Related to >CFA is >DFA which takes a dictionary entry address as returned by (FIND) and
	returns a pointer to the first data field.

	(FIND) returns a pointer to this
	|				>CFA converts it to a pointer to this
	|					   |
	|					   |	>DFA converts it to a pointer to this
	|					   |		 |
	V					   V		 V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
						   codeword

	(Note to those following the source of FIG-FORTH / ciforth: My >DFA definition is
	different from theirs, because they have an extra indirection).

	You can see that >DFA is easily defined in FORTH just by adding 4 to the result of >CFA.
*/

	defword ">DFA",4,,TDFA
	.int TCFA		// >CFA		(get code field address)
	.int INCR4		// 4+		(add 4 to it to get to next word)
	.int EXIT		// EXIT		(return from FORTH word)

/*
	COMPILING ----------------------------------------------------------------------

	Now we'll talk about how FORTH compiles words.  Recall that a word definition looks like this:

		: DOUBLE DUP + ;

	and we have to turn this into:

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+--|---------+------------+------------+
           ^       len                         pad  codeword      |
	   |							  V
	  LATEST points here				points to codeword of DUP

	There are several problems to solve.  Where to put the new word?  How do we read words?  How
	do we define the words : (COLON) and ; (SEMICOLON)?

	FORTH solves this rather elegantly and as you might expect in a very low-level way which
	allows you to change how the compiler works on your own code.

	FORTH has an INTERPRET function (a true interpreter this time, not DOCOL) which runs in a
	loop, reading words (using WORD), looking them up (using (FIND)), turning them into codeword
	pointers (using >CFA) and deciding what to do with them.

	What it does depends on the mode of the interpreter (in variable STATE).

	When STATE is zero, the interpreter just runs each word as it looks them up.  This is known as
	immediate mode.

	The interesting stuff happens when STATE is non-zero -- compiling mode.  In this mode the
	interpreter appends the codeword pointer to user memory (the DP variable points to the next
	free byte of user memory -- see DATA SEGMENT section below).

	So you may be able to see how we could define : (COLON).  The general plan is:

	(1) Use WORD to read the name of the function being defined.

	(2) Construct the dictionary entry -- just the header part -- in user memory:

    pointer to previous word (from LATEST)			+-- Afterwards, DP points here, where
	   ^							|   the interpreter will start appending
	   |							V   codewords.
	+--|------+---+---+---+---+---+---+---+---+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      |
	+---------+---+---+---+---+---+---+---+---+------------+
                   len                         pad  codeword

	(3) Set LATEST to point to the newly defined word, ...

	(4) .. and most importantly leave DP pointing just after the new codeword.  This is where
	    the interpreter will append codewords.

	(5) Set STATE to 1.  This goes into compile mode so the interpreter starts appending codewords to
	    our partially-formed header.

	After : has run, our input is here:

	: DOUBLE DUP + ;
	         ^
		 |
		Next byte returned by KEY will be the 'D' character of DUP

	so the interpreter (now it's in compile mode, so I guess it's really the compiler) reads "DUP",
	looks it up in the dictionary, gets its codeword pointer, and appends it:

									     +-- DP updated to point here.
									     |
									     V
	+---------+---+---+---+---+---+---+---+---+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        |
	+---------+---+---+---+---+---+---+---+---+------------+------------+
                   len                         pad  codeword

	Next we read +, get the codeword pointer, and append it:

											  +-- DP updated to point here.
											  |
											  V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+
                   len                         pad  codeword

	The issue is what happens next.  Obviously what we _don't_ want to happen is that we
	read ";" and compile it and go on compiling everything afterwards.

	At this point, FORTH uses a trick.  Remember the length byte in the dictionary definition
	isn't just a plain length byte, but can also contain flags.  One flag is called the
	IMMEDIATE flag (F_IMMED in this code).  If a word in the dictionary is flagged as
	IMMEDIATE then the interpreter runs it immediately _even if it's in compile mode_.

	This is how the word ; (SEMICOLON) works -- as a word flagged in the dictionary as IMMEDIATE.

	And all it does is append the codeword for EXIT on to the current definition and switch
	back to immediate mode (set STATE back to 0).  Shortly we'll see the actual definition
	of ; and we'll see that it's really a very simple definition, declared IMMEDIATE.

	After the interpreter reads ; and executes it 'immediately', we get this:

	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
                   len                         pad  codeword					       ^
												       |
												      DP
	STATE is set to 0.

	And that's it, job done, our new definition is compiled, and we're back in immediate mode
	just reading and executing words, perhaps including a call to test our new word DOUBLE.

	The only last wrinkle in this is that while our word was being compiled, it was in a
	half-finished state.  We certainly wouldn't want DOUBLE to be called somehow during
	this time.  There are several ways to stop this from happening, but in FORTH what we
	do is flag the word with the HIDDEN flag (F_HIDDEN in this code) just while it is
	being compiled.  This prevents (FIND) from finding it, and thus in theory stops any
	chance of it being called.

	The above explains how compiling, : (COLON) and ; (SEMICOLON) works and in a moment I'm
	going to define them.  The : (COLON) function can be made a little bit more general by writing
	it in two parts.  The first part, called HEADER, (HEADER_COMMA), makes just the header:

						   +-- Afterwards, DP points here.
						   |
						   V
	+---------+---+---+---+---+---+---+---+---+
	| LINK    | 6 | D | O | U | B | L | E | 0 |
	+---------+---+---+---+---+---+---+---+---+
                   len                         pad

	and the second part, the actual definition of : (COLON), calls HEADER, (HEADER_COMMA) and appends the
	DOCOL codeword, so leaving:

								+-- Afterwards, DP points here.
								|
								V
	+---------+---+---+---+---+---+---+---+---+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      |
	+---------+---+---+---+---+---+---+---+---+------------+
                   len                         pad  codeword

	HEADER, (HEADER_COMMA) is a FORTH word and the advantage of this split is that we can reuse it to
	create other types of words (not just ones which contain code, but words which contain variables,
	constants and other data).
*/

	defcode "HEADER,",7,,HEADER_COMMA

	// Get the name length and address.
	POPDATASTACK a9			// a9 = length
	POPDATASTACK a10		// a10 = address of name

	// Link pointer.
	READ_VAR a11, DP	// a11 is the address of the header, i.e. the top of memory available.
	READ_VAR a8, LATEST	// Get link pointer
	s32i a8, a11, 0		// and store it in the header.

	// Length byte and the word itself.
	s8i a9, a11, 4		// Store the length/flags byte.
L30:
	l8ui a7, a10, 0		// read name character
	s8i a7, a11, 5		// store in header
	addi a10, a10, 1	// inc name source
	addi a11, a11, 1	// inc name dest
	addi a9, a9, -1		// dec character counter
	bnez a9, L30		// loop all characters
	addi a11, a11, 3	// add padding bytes
	movi a10, ~3		// mask away last 2 bits
	and a11, a11, a10	// last 2 bits removed
	// a11 now points at 'codeword'
	READ_VAR a8, DP		// previous datasegment pointer is where the new header was added.
	WRITE_VAR a8, a9, LATEST  // update the LATEST location.
	WRITE_VAR a11, a9, DP	// update new datasegment pointer
	NEXT

/*
	Because I want to define : (COLON) in FORTH, not assembler, we need a few more FORTH words
	to use.

	The first is , (COMMA) which is a standard FORTH word which appends a 32 bit integer to the user
	memory pointed to by DP, and adds 4 to DP.  So the action of , (COMMA) is:

							previous value of DP
								 |
								 V
	+---------+---+---+---+---+---+---+---+---+-- - - - - --+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 |             |  <data>    |
	+---------+---+---+---+---+---+---+---+---+-- - - - - --+------------+
                   len                         pad		              ^
									      |
									new value of DP

	and <data> is whatever 32 bit integer was at the top of the stack.

	, (COMMA) is quite a fundamental operation when compiling.  It is used to append codewords
	to the current word that is being compiled.
*/

	defcode ",",1,,COMMA
	POPDATASTACK a2		// Code pointer to store.
	call0 _COMMA
	NEXT

/* This routine adds the integer in a2 to the dictionary (as pointed by DP) and advances DP to next location.
	Inarguments
	   a2 : Codepointer to be stored in Dictionary

	Return value
	   none
*/
_COMMA:
	READ_VAR a8, DP		// a8 <- DP
	S32i a2, a8, 0		// Store it.
	addi a8, a8, 4		// increment DP
	WRITE_VAR a8, a9, DP	// update DP
	ret

/*
	Our definitions of : (COLON) and ; (SEMICOLON) will need to switch to and from compile mode.

	Immediate mode vs. compile mode is stored in the global variable STATE, and by updating this
	variable we can switch between the two modes.

	For various reasons which may become apparent later, FORTH defines two standard words called
	[ and ] (LBRAC and RBRAC) which switch between modes:

	Word	Assembler	Action		Effect
	[	LBRAC		STATE := 0	Switch to immediate mode.
	]	RBRAC		STATE := 1	Switch to compile mode.

	[ (LBRAC) is an IMMEDIATE word.  The reason is as follows: If we are in compile mode and the
	interpreter saw [ then it would compile it rather than running it.  We would never be able to
	switch back to immediate mode!  So we flag the word as IMMEDIATE so that even in compile mode
	the word runs immediately, switching us back to immediate mode.
*/

	defcode "[",1,F_IMMED,LBRAC
	movi a8, 0
	WRITE_VAR a8, a9, STATE	// Set STATE to 0.
	NEXT

	defcode "]",1,,RBRAC
	movi a8, 1
	WRITE_VAR a8, a9, STATE	// Set STATE to 1.
	NEXT

/*
	Now we can define : (COLON) using HEADER, (HEADER_COMMA).  It just calls HEADER, (HEADER_COMMA),
	appends DOCOL (the codeword), sets the word HIDDEN and goes into compile mode.
*/

	defword ":",1,,COLON
	.int WORD		// Get the name of the new word
	.int HEADER_COMMA	// Create the dictionary entry / header
	.int LIT, DOCOL, COMMA	// Append DOCOL  (the codeword).
	.int LATEST, FETCH, HIDDEN // Make the word hidden (see below for definition).
	.int RBRAC		// Go into compile mode.
	.int EXIT		// Return from the function.

/*
	; (SEMICOLON) is also elegantly simple.  Notice the F_IMMED flag.
*/

	defword ";",1,F_IMMED,SEMICOLON
	.int LIT, EXIT, COMMA	// Append EXIT (so the word will return).
	.int LATEST, FETCH, HIDDEN // Toggle hidden flag -- unhide the word (see below for definition).
	.int LBRAC		// Go back to IMMEDIATE mode.
	.int EXIT		// Return from the function.

/*
	EXTENDING THE COMPILER ----------------------------------------------------------------------

	Words flagged with IMMEDIATE (F_IMMED) aren't just for the FORTH compiler to use.  You can define
	your own IMMEDIATE words too, and this is a crucial aspect when extending basic FORTH, because
	it allows you in effect to extend the compiler itself.  Does gcc let you do that?

	Standard FORTH words like IF, WHILE, ." and so on are all written as extensions to the basic
	compiler, and are all IMMEDIATE words.

	The IMMEDIATE word toggles the F_IMMED (IMMEDIATE flag) on the most recently defined word,
	or on the current word if you call it in the middle of a definition.

	Typical usage is:

	: MYIMMEDWORD IMMEDIATE
		...definition...
	;

	but some FORTH programmers write this instead:

	: MYIMMEDWORD
		...definition...
	; IMMEDIATE

	The two usages are equivalent, to a first approximation.
*/

	defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE
	READ_VAR a8, LATEST		// LATEST word.
	addi a8, a8, 4			// Point to name/flags byte.
	movi a9, F_IMMED
	xor a8, a8, a9			// Toggle the IMMED bit.
	WRITE_VAR a8, a9, LATEST	// Update the F_IMMED flag in the LATEST word
	NEXT

/*
	'addr HIDDEN' toggles the hidden flag (F_HIDDEN) of the word defined at addr.  To hide the
	most recently defined word (used above in : and ; definitions) you would do:

		LATEST @ HIDDEN

	'HIDE word' toggles the flag on a named 'word'.

	Setting this flag stops the word from being found by (FIND), and so can be used to make 'private'
	words.  For example, to break up a large word into smaller parts you might do:

		: SUB1 ... subword ... ;
		: SUB2 ... subword ... ;
		: SUB3 ... subword ... ;
		: MAIN ... defined in terms of SUB1, SUB2, SUB3 ... ;
		HIDE SUB1
		HIDE SUB2
		HIDE SUB3

	After this, only MAIN is 'exported' or seen by the rest of the program.
*/

	defcode "HIDDEN",6,,HIDDEN
	READ_VAR a8, LATEST		// LATEST word.
	addi a8, a8, 4			// Point to name/flags byte.
	movi a9, F_IMMED
	xor a8, a8, a9			// Toggle the IMMED bit.
	WRITE_VAR a8, a9, LATEST	// Update the F_IMMED flag in the LATEST word
	NEXT

	defword "HIDE",4,,HIDE
	.int WORD			// Get the word (after HIDE).
	.int PAREN_FIND			// Look up in the dictionary.
	.int HIDDEN			// Set F_HIDDEN flag.
	.int EXIT			// Return.

/*
	['] (BRACKET_TICK) is a standard FORTH word which returns the codeword pointer of the next word.

	The common usage is:

	['] FOO ,

	which appends the codeword of FOO to the current word we are defining (this only works in compiled code).

	You tend to use ['] in IMMEDIATE words.  For example an alternate (and rather useless) way to define
	a literal 2 might be:

	: LIT2 IMMEDIATE
		['] LIT ,		\ Appends LIT to the currently-being-defined word
		2 ,		\ Appends the number 2 to the currently-being-defined word
	;

	So you could do:

	: DOUBLE LIT2 * ;

	(If you don't understand how LIT2 works, then you should review the material about compiling words
	and immediate mode).

	This definition of ['] uses a cheat which I copied from buzzard92.  As a result it only works in
	compiled code.  It is possible to write a version of ['] based on WORD, (FIND), >CFA which works in
	immediate mode too.

	This definition of ['] uses a cheat which I copied from buzzard92.  As a result it only works in
	compilied and when the word after it is not an immediate word. It is possible to write a version
	of ['] which works on immediate word, or to write another version based on WORD, (FIND), >CFA
	which works in immediate mode too.
*/
	defcode "[']",3,,BRACKET_TICK
	l32i a8, a14, 0			// get the address of the next word
	addi a14, a14, 4		// and skip it.
	PUSHDATASTACK a8		// Push it on the stack.
	NEXT

/*
	BRANCHING ----------------------------------------------------------------------

	It turns out that all you need in order to define looping constructs, IF-statements, etc.
	are two primitives.

	BRANCH is an unconditional branch. 0BRANCH is a conditional branch (it only branches if the
	top of stack is zero).

	The diagram below shows how BRANCH works in some imaginary compiled word.  When BRANCH executes,
	%esi starts by pointing to the offset field (compare to LIT above):

	+---------------------+-------+---- - - ---+------------+------------+---- - - - ----+------------+
	| (Dictionary header) | DOCOL |            | BRANCH     | offset     | (skipped)     | word       |
	+---------------------+-------+---- - - ---+------------+-----|------+---- - - - ----+------------+
								   ^  |			      ^
								   |  |			      |
								   |  +-----------------------+
								  %esi added to offset

	The offset is added to %esi to make the new %esi, and the result is that when NEXT runs, execution
	continues at the branch target.  Negative offsets work as expected.

	0BRANCH is the same except the branch happens conditionally.

	Now standard FORTH words such as IF, THEN, ELSE, WHILE, REPEAT, etc. can be implemented entirely
	in FORTH.  They are IMMEDIATE words which append various combinations of BRANCH or 0BRANCH
	into the word currently being compiled.

	As an example, code written like this:

		condition-code IF true-part THEN rest-code

	compiles to:

		condition-code 0BRANCH OFFSET true-part rest-code
					  |		^
					  |		|
					  +-------------+
*/

	defcode "BRANCH",6,,BRANCH
	l32i a8, a14, 0			// read offset
	add a14, a14, a8		// add the offset to the instruction pointer
	NEXT

	defcode "0BRANCH",7,,ZBRANCH
	POPDATASTACK a8			// get condition from top of stack
	beqz a8, code_BRANCH		// top of stack is zero? if so, jump back to the branch function above
	addi a14, a14, 4		// otherwise we need to skip the offset
	NEXT

/*
	LITERAL STRINGS ----------------------------------------------------------------------

	LITSTRING is a primitive used to implement the ." and S" operators (which are written in
	FORTH).  See the definition of those operators later.

	TELL just prints a string.  It's more efficient to define this in assembly because we
	can make it a single Linux syscall.
*/

	defcode "LITSTRING",9,,LITSTRING
	l32i a8, a14, 0         // get the length of the string
	addi a14, a14, 4	// advance the instruction pointer
	PUSHDATASTACK a14	// push the address of the start of the string
	PUSHDATASTACK a8	// push length on the stack
	add a14, a14, a8	// skip past the string
 	addi a14,a14, 3		// but round up to next 4 byte boundary
 	movi a8, ~3		// align 4-byte mask
	and a14, a14, a8	// align instruction pointer
	NEXT

	defcode "TELL",4,,TELL
	POPDATASTACK a3
	POPDATASTACK a2
	call0 putChars
	// TODO (niclas); putChars() returns a negative number if there was an error. What to do?
	NEXT

/*
	COMBINING DATA AND BEHAVIOR --------------------------------------------------------

	A FORTH word with codeword DOCOL defines the word's behavior with other FORTH words.
	On the other hand, a built-in variable's behavior is simply push the pointer to its
	data onto the stack.

	One will wonder how can a FORTH word which owns complicated data specify its behavior on
	these data using other FORTH words. The magic word DODOES serves this purpose. 

	The diagram below shows how DODOES works.  When DODOES executes, it pushes the pointer to
	its data onto the stack and execute the behavior words pointed to by the behavior pointer.

	+---------------------+--------+---------+------+----------------+
	| (Dictionary header) | DODOES |         | data | behavior words |
	+---------------------+--------+---------+------+----------------+
			     behavior pointer |		  ^
					      |		  |
					      +-----------+

	When the behavior pointer is zero, there is no behavior words, DODOES simply pushes the pointer to
	its data onto the stack.

	+---------------------+--------+--------+------+
	| (Dictionary header) | DODOES |   0    | data |
	+---------------------+--------+--------+------+

*/

	.text
	.align 4
DODOES:
	l32i a9, a8, 4		// get Behavior Word
	beqz a9, 1f		// branch if offset is zero
	PUSHRSP a14
	l32i a14, a8, 4

1:	addi a8, a8, 8
	PUSHDATASTACK a8
	NEXT

	defconst "DODOES",6,,__DODOES,DODOES

/*
	QUIT AND INTERPRET ----------------------------------------------------------------------

	QUIT is the first FORTH function called, almost immediately after the FORTH system "boots".
	As explained before, QUIT doesn't "quit" anything.  It does some initialisation (in particular
	it clears the return stack) and it calls INTERPRET in a loop to interpret commands.  The
	reason it is called QUIT is because you can call it from your own FORTH words in order to
	"quit" your program and start again at the user prompt.

	INTERPRET is the FORTH interpreter ("toploop", "toplevel" or "REPL" might be a more accurate
	description -- see: http://en.wikipedia.org/wiki/REPL).
*/
	DECL_VAR interpret_is_lit, 4, 4		// Flag used to record if reading a literal

	// QUIT must not return (ie. must not call EXIT).
	defword "QUIT",4,,QUIT
	.int RZ,RSPSTORE			// R0 RSP!, clear the return stack
	.int INTERPRET				// interpret the next word
	.int BRANCH,-8				// and loop (indefinitely)

/*
	This interpreter is pretty simple, but remember that in FORTH you can always override
	it later with a more powerful one!
 */
	defcode "INTERPRET",9,,INTERPRET
	call0 _WORD				// Returns a3 = length, a2 = pointer to word.

	// Is it in the dictionary?
	movi a8, 0
	WRITE_VAR a8, a9, interpret_is_lit	// Not a literal number (not yet anyway ...)

	call0 _FIND				// Returns a2 = pointer to header or 0 if not found.
	beqz a2, 1f				// Found?

	// In the dictionary.  Is it an IMMEDIATE codeword?
	l8ui a8, a2, 4				// Get name_length+flags.
	PUSHDATASTACK a8			// Just save it for now.
	call0 _TCFA				// Convert dictionary entry (in a2) to codeword pointer (to a2).
	POPDATASTACK a8
	movi a9, F_IMMED
	and a9, a8, a9				// is IMMED flag set?
	mov a8, a2				// save codeword pointer in a8
	bnez a9, 4f				// If IMMED, jump straight to executing.
	j 2f

1:	// Not in the dictionary (not a word) so assume it's a literal number.
	READ_VAR a8, interpret_is_lit
	addi a8, a8, 1
	WRITE_VAR a8, a7, interpret_is_lit	// increment interpret_is_lit

	call0 _NUMBER				// Returns the parsed number in a2, a3 > 0 if error
	bnez a3, 6f				// branch if there was an error
	mov a10, a8				// store number in a10

	.literal .ADDR_TO_LIT, LIT
	l32r a8, .ADDR_TO_LIT			// The word is LIT, a8 points now points to the code for the literal??

2:	// Are we compiling or executing?
	READ_VAR a11, STATE
	beqz a11, 4f				// Jump if executing.

	// Compiling - just append the word to the current dictionary definition.
	call0 _COMMA				// a2 must contain the integer to be stored, a posibility of
	 					// 1: a dictionary word pointer returned by _WORD
						// 2: an integer returned from _NUMBER,
						// 3(?): pointer to code
	READ_VAR a9, interpret_is_lit		// Was it a literal?
	beqz a9, 3f
	mov a8, a10				// Yes, so LIT is followed by a number.
	call0 _COMMA
3:	NEXT

4:	// Executing - run it!
	READ_VAR a9, interpret_is_lit		// Was it a literal?
	bnez a9, 5f				// branch if literal

	// Not a literal, execute it now.  This never returns, but the codeword will
	// eventually call NEXT which will reenter the loop in QUIT.
        l32i a8, a8, 0				// Read address to jump to
	jx a8					// Jump to that address

5:	// Executing a literal, which means push it on the stack.
	PUSHDATASTACK a10			// a10 contains the saved integer v
	NEXT

6:	// Parse error (not a known word or a number in the current BASE).
	// Print an error message followed by up to 40 characters of context.
	l32r a2, errmsg
	movi a3, errmsg_size
	call0 putChars				// print the error

	READ_VAR a9, currkey			// the error occurred just before currkey position
	ENV a8, system_t_input_buffer		// Get position of Input Buffer
	sub a3, a9, a8				// a3 = currkey - buffer (length in buffer before currkey)
	movi a10, 41
	blt a3, a10, 7f				// if > 40, then print only 40 characters
	movi a3, 40
7:	sub a2, a9, a3				// a2 = start of area to print, a3 = length
	call0 putChars				// print the characters

	l32r a2, errmsgcr
	call0 putChar				// print CR
	l32r a2, errmsgnl
	call0 putChar				// print LF
	NEXT

	.section .rodata
	.align 4
errmsg:
	.ascii "PARSE ERROR: "
	.set errmsg_size, .-errmsg
	.align 4
errmsgnl: .ascii "\n"
	.align 4
errmsgcr: .ascii "\n"


/*
	ANS Forth Core Words  ----------------------------------------------------------------------
	Some lower level ANS Forth CORE words are not presented in the orignal jonesforth. They are
	included here without explaination.

	TODO (niclas); The following section was lacking enough documentation and the porting may be very faulty.
*/

/* Words to deal with the return stack. */

	defcode "2*",2,,TWOMUL
	READTOSX a8
	slli a8, a8, 1		// shift left logical 1 bit
	WRITETOSX a8
	NEXT

	defcode "2/",2,,TWODIV
	READTOSX a8
	srai a8, a8, 1		// shift right arithmeic 1 bit
	WRITETOSX a8
	NEXT

	defcode "(DO)", 4,,PAREN_DO
	POPDATASTACK a8		// pop parameter stack into %eax and %edx
	POPDATASTACK a9
	PUSH2RSP a9, a8		// push it on to the return stack
	NEXT

	defcode "(LOOP)", 6,,PAREN_LOOP
	POP2RSP a9, a8
	addi a8, a8, 1
	beq a9, a8, 1f
	PUSH2RSP a9, a8
	l32i a8, a14, 0		// load offset from instruction pointer location
	add a14, a14, a8	// add the offset to the instruction pointer
	NEXT
1:
	addi a14, a14, 4	// Advance instruction pointer
	NEXT

	defcode "(+LOOP)", 7,,PAREN_PLUS_LOOP
	POP2RSP a11, a8		// index in a8, limit in a11
	sub a8, a8, a11		// index-limit in a8
	POPDATASTACK a9		// n in a9
	add a9, a8, a9		// index-limit+n in a9
	xor a9, a9, a8		// (index-limit) and (index-limit+n) have different sign?
	bltz a9, 1f
	add a9, a11, a9		// index+n in a9
	PUSH2RSP a11, a9
	l32i a8, a14, 0		// read jump offset
	add a14, a14, a8	// add the offset to the instruction pointer
	NEXT
1:
	addi a14, a14, 4	// Advance instruction pointer
	NEXT

	defcode "UNLOOP", 6,,UNLOOP
	l32i a13, a13, 8	// Read top+8 of Return Stack
	NEXT

	defcode "I", 1,,I
	l32i a8, a13, 0		// Read top of Return Stack
	PUSHDATASTACK a8	// Push to Data Stack
	NEXT

	defcode "J", 1,,J
	l32i a8, a13, 8		// Read top+8 of Return Stack
	PUSHDATASTACK a8	// Push to Data Stack
	NEXT

/*
	ODDS AND ENDS ----------------------------------------------------------------------

	CHAR puts the ASCII code of the first character of the following word on the stack.  For example
	CHAR A puts 65 on the stack.

	EXECUTE is used to run execution tokens.  See the discussion of execution tokens in the
	FORTH code for more details.

	SYSCALL0, SYSCALL1, SYSCALL2, SYSCALL3 make a standard Linux system call.  (See <asm/unistd.h>
	for a list of system call numbers).  As their name suggests these forms take between 0 and 3
	syscall parameters, plus the system call number.

	In this FORTH, EXECUTE must be the last word in the built-in (assembler) dictionary because we
	initialise the LATEST variable to point to it.  This means that if you want to extend the assembler
	part, you must put new words before EXECUTE, or else change how LATEST is initialised.
*/

	defcode "CHAR",4,,CHAR
	call0 _WORD		// Returns a3 = length, a2 = pointer to word.
	l8ui a8, a2, 0		// Get the first character of the word.
	PUSHDATASTACK a8	// Push it onto the stack.
	NEXT

//	defcode "SYSCALL3",8,,SYSCALL3
//	pop %eax		// System call number (see <asm/unistd.h>)
//	pop %ebx		// First parameter.
//	pop %ecx		// Second parameter
//	pop %edx		// Third parameter
//	int $0x80
//	push %eax		// Result (negative for -errno)
//	NEXT

//	defcode "SYSCALL2",8,,SYSCALL2
//	pop %eax		// System call number (see <asm/unistd.h>)
//	pop %ebx		// First parameter.
//	pop %ecx		// Second parameter
//	int $0x80
//	push %eax		// Result (negative for -errno)
//	NEXT

//	defcode "SYSCALL1",8,,SYSCALL1
//	pop %eax		// System call number (see <asm/unistd.h>)
//	pop %ebx		// First parameter.
//	int $0x80
//	push %eax		// Result (negative for -errno)
//	NEXT

//	defcode "SYSCALL0",8,,SYSCALL0
//	pop %eax		// System call number (see <asm/unistd.h>)
//	int $0x80
//	push %eax		// Result (negative for -errno)
//	NEXT

	defcode "EXECUTE",7,,EXECUTE
	POPDATASTACK a8		// Get xt into a8
	l32i a8, a8, 0		// Load the address from memory
	jx a8			// Jump to that address
				// After xt runs its NEXT will continue executing the current word.


/*
	DATA SEGMENT ----------------------------------------------------------------------

	Here we set up the Linux data segment, used for user definitions and variously known as just
	the 'data segment', 'user memory' or 'user definitions area'.  It is an area of memory which
	grows upwards and stores both newly-defined FORTH words and global variables of various
	sorts.

	It is completely analogous to the C heap, except there is no generalised 'malloc' and 'free'
	(but as with everything in FORTH, writing such functions would just be a Simple Matter
	Of Programming).  Instead in normal use the data segment just grows upwards as new FORTH
	words are defined/appended to it.

	There are various "features" of the GNU toolchain which make setting up the data segment
	more complicated than it really needs to be.  One is the GNU linker which inserts a random
	"build ID" segment.  Another is Address Space Randomization which means we can't tell
	where the kernel will choose to place the data segment (or the stack for that matter).

	Therefore writing this set_up_data_segment assembler routine is a little more complicated
	than it really needs to be.  We ask the Linux kernel where it thinks the data segment starts
	using the brk(2) system call, then ask it to reserve some initial space (also using brk(2)).

	You don't need to worry about this code.
*/

/* The internal state of the Forth environment is kept in these variables. */
	DECL_VAR c_stack_address,4,4		// The Stack Pointer at Entry to Assembler
	DECL_VAR c_return_address,4,4		// The Return address to the C bootstrapper

	.text
initialize:
	// a0 Return address
	// a2 system_t pointer

	mov a12, a2				// Set the System Environment pointer
	WRITE_VAR a1, a8, c_stack_address
	WRITE_VAR a0, a8, c_return_address

	ENV a13, system_t_return_stack
	ENV a15, system_t_data_stack

	ENV a11, system_t_data_segment		// Get position of data segment
	WRITE_VAR a11, a8, DP			// Save Forth variable named DP

	ENV a8, system_t_input_buffer		// Get position of Input Buffer
	ENV a9, system_t_input_buffer_size	// Get size of Input Buffer
	WRITE_VAR a8, a9, currkey		// Save currkey position
	WRITE_VAR a8, a9, bufftop		// Save last value in buffer
	ret

/*
	START OF FORTH CODE ----------------------------------------------------------------------

	We've now reached the stage where the FORTH system is running and self-hosting.  All further
	words can be written as FORTH itself, including words like IF, THEN, .", etc which in most
	languages would be considered rather fundamental.

	I used to append this here in the assembly file, but I got sick of fighting against gas's
	crack-smoking (lack of) multiline string syntax.  So now that is in a separate file called
	jonesforth.f

	If you don't already have that file, download it from http://annexia.org/forth in order
	to continue the tutorial.
*/

/* END OF jonesforth.S */
