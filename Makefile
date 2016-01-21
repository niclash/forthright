# $Id: Makefile,v 1.9 2007-10-22 18:53:12 rich Exp $

BUILD_ID_NONE := 
CC := xtensa-lx106-elf-gcc
SHELL	:= /bin/bash

all:	forthright

forthright: link

asm: esp8266.asm
	${CC} -U__STRICT_ANSI__  -c -x assembler-with-cpp -MMD -DF_CPU=80000000L esp8266.asm

compile: forthright.c
	${CC} -U__STRICT_ANSI__  -c -MMD -DF_CPU=80000000L -DFORTH_SIZE=65536 -S forthright.c

link: compile asm


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
