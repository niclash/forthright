#!/bin/sh
#
PORT=${PORT:-/dev/tty.SLAB_USBtoUART}
ESPTOOL=${ESPTOOL:-esptool}
BIN_PATH=target
FLASH_MODE=dio
FLASH_SIZE=32m
FLASH_FREQUENCY=40m

${ESPTOOL} --port=${PORT} \
        write_flash \
        -fm ${FLASH_MODE} \
        -fs ${FLASH_SIZE} \
        -ff ${FLASH_FREQUENCY} \
        0x0 ${BIN_PATH}/eagle.flash.bin \
        0x40000 ${BIN_PATH}/eagle.irom0text.bin

