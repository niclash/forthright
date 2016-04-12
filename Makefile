#
#   Copyright 2016 Niclas Hedhman, All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

all:
	mkdir -p arch/esp8266/generated/ 2>/dev/null
	# also sed -E 's/\\([)(]|[ A-Za-z0-9.,?-])*$$//' |  ??
	# cat forthright.f | sed '/^[(]/,/^[)]/{/^[(]/!{/^[)]/!d}}'| sed 's/\t/ /g' | sed 's/^\\.*//' | sed 's/( .* )//' | sed 's/^ *//' | sed 's/ *$$//' | sed -E 's/  / /g' | grep -v "^$$" | sed 's/\\/\\\\/' | sed 's/"/\\"/g' >arch/esp8266/generated/intermediate1.asm
	# cat arch/esp8266/generated/intermediate1.asm  | grep -v "^[(].*$$" | grep -v "^[)]$$" | tr '\n' ' ' | sed 's/ ; / ;\n/g' >arch/esp8266/generated/intermediate2.asm
	# cat arch/esp8266/generated/intermediate1.asm | sed 's/  / /g' | sed -E 's/(^.*$$)/\t\t.ascii \"\1\\n\"/g' >arch/esp8266/generated/forthright.asm
	cat forthright.f | grep -v "^ *\\\\" | grep -v "^ *$$" | sed 's/\\/\\\\/' | sed 's/"/\\"/g' | tr '\t' ' ' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed -E 's/(^.*$$)/\t\t.ascii \"\1\\n\"/g' >arch/esp8266/generated/forthright.asm
	cd arch/esp8266 && make clean && make
clean:
	cd arch/esp8266 && make clean
