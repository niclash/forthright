
( Function calls into ROM to access I2C
rom_i2c_readReg = 0x40007268
rom_i2c_readReg_Mask = 0x4000729c
rom_i2c_writeReg = 0x400072d8
rom_i2c_writeReg_Mask = 0x4000730c
)


( Select a TWSI channel and slave address for subsequent access )
: set-twsi-target ( slave channel -- )
;

( Read a byte )
: twsi-b@ ( reg -- byte )
;

( Write a byte )
: twsi-b! ( byte reg -- byte )
;

( Write n bytes from the stack )
: twsi-write ( byte_n-1 .. byte0 n -- )
;

( Send #reg-bytes register address bytes from the stack, then read #data-bytes onto the stack. )
: twsi-get ( reg#_n-1 .. reg#0 #reg-bytes #data-bytes -- data_n-1 .. data0 )
;

