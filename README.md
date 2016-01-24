# Forthright

This is a port of Jones Forth to the ESP-8266 microcontroller.

The starting point was the work done by Cheng Chang Wu, who
tried to achieve ANS Forth compliance.

See https://github.com/chengchangwu/jonesforth


Other processors will be considered in the future if this one is successful.

Obvious candidates are;

   * ARM
      TICC32xx CPUs
      STM





## Note for Mac users
This project requires a cross-compile environment, and Espressif recommends the crosstool-ng
project, and provides instructions on how to build that. However, that doesn't work on Mac OSX
as the "sed" instruction is different in GNU vs the BSD origin of Mac OSX.

Here is what I did (assuming MacPorts is installed)

    sudo port install gsed
    sudo mv /usr/bin/sed /usr/bin/sed.orig
    sudo ln -s `which gsed` /usr/bin/sed

That should do the trick and crosstool-ng building.