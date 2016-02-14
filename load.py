import serial

ser = serial.Serial("/dev/tty.SLAB_USBtoUART", 115200)
x = ser.write(': HELLO ;')
ser.close()