# $Id: Makefile,v 1.9 2007-10-22 18:53:12 rich Exp $

BUILD_ID_NONE := 
CC := xtensa-lx106-elf-gcc
SHELL	:= /bin/bash

all:	forthright

esp8266.o: esp8266.asm
	${CC} -U__STRICT_ANSI__  -c -x assembler-with-cpp -MMD -DF_CPU=80000000L esp8266.asm

forthright.o: forthright.s
	${CC} -U__STRICT_ANSI__  -c -x assembler-with-cpp -MMD -DF_CPU=80000000L forthright.s

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

#forthright: forthright.o esp8266.o
#	${CC} -g \
#	-Os \
#	-nostdlib \
#	-Wl,--no-check-sections \
#	-u call_user_start \
#	-Wl,-static \
#	-L/Users/niclas/Library/Arduino15/packages/esp8266/hardware/esp8266/2.0.0/tools/sdk/lib \
#	-L/Users/niclas/Library/Arduino15/packages/esp8266/hardware/esp8266/2.0.0/tools/sdk/ld \
#	-Teagle.flash.4m1m.ld \
#	-Wl,--gc-sections \
#	-Wl,-wrap,system_restart_local \
#	-Wl,-wrap,register_chipv6_phy  \
#	-o forthcoming.elf \
#	-Wl,--start-group \
#	esp8266.o \
#	forthright.o \
#	-lm \
#	-lgcc \
#	-lhal \
#	-lphy \
#	-lnet80211 \
#	-llwip \
#	-lwpa \
#	-lmain \
#	-lpp \
#	-lsmartconfig \
#	-lwps \
#	-lcrypto \
#	-laxtls \
#	-Wl,--end-group


forthright: forthright.o esp8266.o
	${CC} \
	-DFORTHRIGHT_VERSION=48\
	-g \
	-Os \
	-nostdlib \
	-Wl,--no-check-sections \
	-u call_user_start \
	-Wl,-static \
	-L/Users/niclas/Library/Arduino15/packages/esp8266/hardware/esp8266/2.0.0/tools/sdk/lib \
	-L/Users/niclas/Library/Arduino15/packages/esp8266/hardware/esp8266/2.0.0/tools/sdk/ld \
	-Teagle.flash.4m1m.ld \
	-Wl,--gc-sections \
	-Wl,-wrap,system_restart_local \
	-Wl,-wrap,register_chipv6_phy  \
	-o forthright.elf \
	-Wl,--start-group \
	esp8266.o \
	forthright.o \
	"belt/ESP8266WiFi/ESP8266WiFi.cpp.o" \
	"belt/ESP8266WiFi/ESP8266WiFiMulti.cpp.o" \
	"belt/ESP8266WiFi/WiFiClient.cpp.o" \
	"belt/ESP8266WiFi/WiFiClientSecure.cpp.o" \
	"belt/ESP8266WiFi/WiFiServer.cpp.o" \
	"belt/ESP8266WiFi/WiFiUdp.cpp.o" \
	"belt/ESP8266mDNS/ESP8266mDNS.cpp.o" \
	"belt/ArduinoOTA/ArduinoOTA.cpp.o" \
	"belt/ESP8266WebServer/ESP8266WebServer.cpp.o" \
	"belt/ESP8266WebServer/Parsing.cpp.o" \
	"belt/OneWire/OneWire.cpp.o" \
	"belt/Arduino-Temperature-Control-Library-3.7.5/DallasTemperature.cpp.o" \
	"/var/folders/rk/g5qdsrnn4pl1jw6z1_p54llh0000gn/T/buildb42acf51ac3a0e2f0f2ba79c9e2be4bc.tmp/arduino.ar" \
	-lm \
	-lgcc \
	-lhal \
	-lphy \
	-lnet80211 \
	-llwip \
	-lwpa \
	-lmain \
	-lpp \
	-lsmartconfig \
	-lwps \
	-lcrypto \
	-laxtls \
	-Wl,--end-group


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
