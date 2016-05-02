# Forthright

This is a port of Jones Forth to the ESP-8266 microcontroller.

The starting point was the work done by Cheng Chang Wu, who
tried to achieve ANS Forth compliance.

See https://github.com/chengchangwu/jonesforth


## Planned features

    * Filesystem (SPIFFS)
    * GPIO
    * PWM
    * ADC
    * Block I/O a la fig-Forth Forth-79/83 onto Flash SPI sectors directly.
    * Debug serial out
    * Timer
    * I2C
    * SPI
    * Actors, similar to Erlang

To keep the higher level libraries reasonably portable, I think some constants
will be required to be defined at Assembler level, or perhaps even in Makefile configuration.


## Future CPUs
Other processors will be considered (or maybe not) in the future if this one is successful.

Obvious candidates are;

   * ARM
      * Texas Instrument CC2538, CC32xx controllers
      * Atmel (now/soon Microchip) range of ARM-based controllers
      * ST Eectronics ARM range of controllers
      * Many Linux/Android capable systems

   * 8051
      * Many Texas Instrument controllers are 8051 based
      * ST Microelectronic range of 8051 based controllers.

   * Atmel (?)

## Note for Mac users
This project requires a cross-compile environment, and Espressif recommends the crosstool-ng
project, and provides instructions on how to build that. However, that doesn't work on Mac OSX
as the "sed" instruction is different in GNU vs the BSD origin of Mac OSX.

Here is what I did (assuming MacPorts is installed)

    sudo port install gsed
    sudo mv /usr/bin/sed /usr/bin/sed.orig
    sudo ln -s `which gsed` /usr/bin/sed

That should do the trick and crosstool-ng building.
