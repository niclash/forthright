all:
	mkdir -p arch/esp8266/generated/ 2>/dev/null
	cat forthright.f | sed 's/\\/\\\\/' | sed 's/"/\\"/g' | sed -E 's/(^.*$$)/\t\t.ascii \"\1\"/g'  >arch/esp8266/generated/forthright.asm
	cd arch/esp8266 && make clean && make
