# Building the uBlocks VM

### Building for Arduino

The following assumes that you've installed the Arduino tools and configured them for your Arduino board.

Create an empty folder for the Arduino project, if necessary.
Copy the following files into that folder:

	  SmallVM.ino
	  interp.c
	  interp.h
	  mem.c
	  mem.h
	  primitives.cpp
	  runtime.c

Open SmallVM.ino and click the "upload" button.

### Building with mbed's online compiler

The easiest way to build the uBlocks VM for the micro:bit is to create a (free) account
on the mbed website and then use their online compiler. I did by selecting "BBC micro:bit"
as the platform, clicking the "New" button, and selecting the first project template,
"microbit_blink". It's a good idea to compile that and run it on your micro:bit to be
sure the toolchain is working. Hit the "compile" button. The result will be downloaded
as a .hex file. Drop that file onto the MICROBIT USB drive. The micro:bit will load the
program and restart. You should see the top-left LED blinking.

Once this works, delete 'main.cpp' and drag and drop the following files into the project:

	interp.c
	interp.h
	main.c
	mem.c
	mem.h
	primitives.cpp
	runtime.c

Just hit compile and install the resulting hex on your micro:bit. Easy!

### Building with gcc's ARM tools

Compiling offline allows you to customize the build process. You'll first need to installing
the ARM gcc tools plus a program called srecord. I used homebrew to install these on my
Mac. I believe I used these commands:

	brew update
	brew install gcc-arm-none-eabi
	brew install srecord

You need a snapshot of the mbed libraries for the micro:bit. The easiest way to get
these is to create a micro:bit project (such "microbit_blink) and export it using the
context menu on the project. This will download a zip file with everything you need,
but you'll need to change the Makefile slightly.

1. Remove the following malloc wrappers from the PREPROC and LD_FLAGS lines:

	'-Wl,--wrap,_malloc_r' '-Wl,--wrap,_free_r' '-Wl,--wrap,_realloc_r' '-Wl,--wrap,_calloc_r'

2. Remove the following from the $(PROJECT)-combined.hex rule:

../mbed/TARGET_NRF51_MICROBIT/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/s130_nrf51822_1_0_0/s130_nrf51_1.0.0_softdevice.hex

That line should include only the s110 softdevice, not both the s110 and s130 softdevices.

After those changes, typing "make" should build a file ending in -combined.hex; that's the
file that you need to install on the micro:bit.

### Build without the BLE "softdevices" to save Flash and RAM

The uBlocks VM can be built for the micro:bit with or without a Nordic BLE softdevice.
Including a softdevice provides BLE support, but consumes Flash and, more importantly, RAM.

The following article has a table summarizing the softdevice memory costs:

S130 Softdevice: 16k Flash, 6k RAM
S110 Softdevice: 32k Flash, 8k RAM
No softdevice: 256k Flash, 16k RAM

The above numbers are from:

https://developer.mbed.org/forum/team-63-Bluetooth-Low-Energy-community/topic/17027/

What's difference between the two softdevices? The S130 softdevice can be a "central" BLE,
meaning it advertise itself and scan for other devices. The S110 can only be a BLE peripheral.

The online compiler on the mbed website includes the larger S130 softdevice.

If you export the project and built it with gcc, as outlined above, you get the S110
softdevice by default, saving 16k of Flash and 2k of RAM. By editing both the Makefile
and the loader script file NRF51822.ld, you can build without any softdevice.

To build without a softdevice, change NRF51822.ld from:

  FLASH (rx) : ORIGIN = 0x00018000, LENGTH = 0x28000
  RAM (rwx) :  ORIGIN = 0x20002000, LENGTH = 0x2000

to:

  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 0x40000
  RAM (rwx) :  ORIGIN = 0x20000000, LENGTH = 0x4000

Note that if you wanted to build with the S130, it would be:

  FLASH (rx) : ORIGIN = 0x0001C000, LENGTH = 0x24000
  RAM (rwx) :  ORIGIN = 0x20002800, LENGTH = 0x1800

The above numbers are from:
  https://github.com/lancaster-university/microbit-targets

You also need to tweak the Makefile by commenting out the lines that add these defines:

-DTARGET_MCU_NRF51_S110
-DTARGET_MCU_NRF51_16K_S110
-DFEATURE_BLE=1

I just guessed at the above, but it seems to work.

I did not try building for the S130, since you can do that with the online compiler.
However, I'd guess you could do that by changing the loader script for the S130 and
using the compiler switches for the S130, which are probably similar to the above.

Test Results

The following test results show how much ram is available with the three configurations:

No softdevice:
bottom of stack: 20003fe4, start of heap: 20000878, difference: 14188
max allocation: 14124

S110 softdevice:
bottom of stack: 20003fe4, start of heap: 20002878, difference: 5996
max allocation: 5932

S130 softdevice (compiled with online mbed compiler):
bottom of stack: 20003ff0, start of heap: 20002408, difference: 7144
max allocation: 3908