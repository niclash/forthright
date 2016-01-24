# $Id: Makefile,v 1.9 2007-10-22 18:53:12 rich Exp $

BUILD_ID_NONE := 
CC := xtensa-lx106-elf-gcc
SHELL	:= /bin/bash

all:	forthright

esp8266.o: esp8266.asm
	${CC} -U__STRICT_ANSI__  -c -x assembler-with-cpp -MMD -DF_CPU=80000000L esp8266.asm

forthright.o: forthright.s
	${CC} -U__STRICT_ANSI__  -c -x assembler-with-cpp -MMD -DF_CPU=80000000L forthright.s

# Compile the ASM generated from the C compiler.
# This extra step is primarily educational, to be able to review what is happening in the C compiler,
# so we can interface with it from assembler if/when we need to.
#
# DATA_SEGMENT_SIZE = The size of the Forth Data Segment, which is where programs are stored and data is allocated long-term
# DATA_STACK_SIZE = The size of the primary stack, a.k.a the Data Stack
# RETURN_STACK_SIZE = The size of the return stack, which is only used for entering/returning from Forth words (functions)
# INPUT_BUFFER_SIZE = The size of the buffer where the characters are placed coming from the serial port (a.k.a terminal)
#
forthright.s : forthright.c
	${CC} \
	-U__STRICT_ANSI__ \
	-S \
	-c \
	-MMD \
	-DF_CPU=80000000L \
	-DDATA_SEGMENT_SIZE=8192 \
	-DDATA_STACK_SIZE=512 \
	-DRETURN_STACK_SIZE=512 \
	-DINPUT_BUFFER_SIZE=64 \
	forthright.c

# Linking. Currently unsolved, and needs to be fixed for testing to commence
forthright: forthright.o esp8266.o

clean:
	-rm esp8266.o esp8266.d forthright.o forthright.d forthright.s
 
# Tests.

TESTS	:= $(patsubst %.f,%.test,$(wildcard test_*.f))

test check: $(TESTS)

test_%.test: test_%.f jonesforth
	@echo -n "$< ... "
	@rm -f .$@
	@cat <(echo ': TEST-MODE ;') jonesforth.f $< <(echo 'TEST') | \
	  ./jonesforth 2>&1 | \
	  sed 's/DSP=[0-9]*//g' > .$@
	@diff -u .$@ $<.out
	@rm -f .$@
	@echo "ok"

# Performance.

perf_dupdrop: perf_dupdrop.c
	gcc -O3 -Wall -Werror -o $@ $<

run_perf_dupdrop: jonesforth
	cat <(echo ': TEST-MODE ;') jonesforth.f perf_dupdrop.f | ./jonesforth

.SUFFIXES: .f .test
.PHONY: test check run run_perf_dupdrop

remote:
	scp jonesforth.S jonesforth.f rjones@oirase:Desktop/
	ssh rjones@oirase sh -c '"rm -f Desktop/jonesforth; \
	  gcc -m32 -nostdlib -static -Wl,-Ttext,0 -o Desktop/jonesforth Desktop/jonesforth.S; \
	  cat Desktop/jonesforth.f - | Desktop/jonesforth arg1 arg2 arg3"'
