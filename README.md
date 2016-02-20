# InputTest
A Z80 assembler program to test D-pad, Start and other Buttons on a Sega Game Gear.

Displays a Game Gear device and checkboxes for each button. Pressed buttons indacated by checked boxes
and red sprites on the image (see screenshot below).

<img src="images/InputTestGameGearScreenshot_320x240.png" alt="Screenshot Kega Fusion" width="50%" height="50%">

Toolchain (minimal):
* make
* wla-dx https://github.com/vhelin/wla-dx (Z80 assembler)

IDE (used to integrate command line tools above, an emulator to test and Git):
* Qt Creator on OS X, http://www.qt.io/ide/

Tested on emulators
* Kega Fusion Emulator (OS X, see screenshot above), http://www.carpeludum.com/kega-fusion/
* Osmose via RetroPie on Raspberry Pi, http://blog.petrockblock.com/retropie/

Tested on real hardware
* via EverDrive GG

Inspired by Maxim’s World of Stuff (SMS Tutorial)
http://www.smspower.org/maxim/HowToProgram/Index
