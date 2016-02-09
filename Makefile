all:
	cat forthright.f | sed 's/\\.*//' | tr '\r' ' ' | tr '\n' ' ' | tr '\t' ' ' | sed 's/  / /g' | perl -pe 's| \( .*? \)| |g' | sed 's/    / /g' | sed 's/   / /g' | sed 's/  / /g' >arch/esp8266/forthright.4th
	cd arch/esp8266 && make clean && make
