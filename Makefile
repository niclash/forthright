all:
	mkdir -p arch/esp8266/generated/ 2>/dev/null
	# also sed -E 's/\\([)(]|[ A-Za-z0-9.,?-])*$$//' |  ??
	# cat forthright.f | sed '/^[(]/,/^[)]/{/^[(]/!{/^[)]/!d}}'| sed 's/\t/ /g' | sed 's/^\\.*//' | sed 's/( .* )//' | sed 's/^ *//' | sed 's/ *$$//' | sed -E 's/  / /g' | grep -v "^$$" | sed 's/\\/\\\\/' | sed 's/"/\\"/g' >arch/esp8266/generated/intermediate1.asm
	# cat arch/esp8266/generated/intermediate1.asm  | grep -v "^[(].*$$" | grep -v "^[)]$$" | tr '\n' ' ' | sed 's/ ; / ;\n/g' >arch/esp8266/generated/intermediate2.asm
	# cat arch/esp8266/generated/intermediate1.asm | sed 's/  / /g' | sed -E 's/(^.*$$)/\t\t.ascii \"\1\\n\"/g' >arch/esp8266/generated/forthright.asm
	cat forthright.f | sed 's/\\/\\\\/' | sed 's/"/\\"/g' | tr '\t' ' ' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed -E 's/(^.*$$)/\t\t.ascii \"\1\\n\"/g' >arch/esp8266/generated/forthright.asm
	cd arch/esp8266 && make clean && make
clean:
	cd arch/esp8266 && make clean
