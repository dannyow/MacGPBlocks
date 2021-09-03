#!/bin/sh
# Build GP for MacOS with statically-linked SDL2, jpeg, cairo, and portaudio libraries
#
# First, build and install the libraries GP depends on:
#
#	brew install SDL2 cairo pixman freetype fontconfig libjpeg libpng portaudio
#
# Then run this shell script to build and link.
#
# You can use "otool -L mac_gp" to list the library dependencies. That list should include
# only frameworks and standard MacOS libraries (not SDL2 or cairo). The standard libraries
# are (as of Oct 2019): libz, libbz, libiconv, libexpat, libSystem.B, and libobjc.A

VM_SRC_DIR=MacGPBlocks/smallvm
WEBAPP_TARGET_DIR=webapp
BUILD_DIR=.build

rm -r $BUILD_DIR
mkdir -p $BUILD_DIR

echo "✅ Copying vm sources from >${VM_SRC_DIR}<"
cp -r $VM_SRC_DIR $BUILD_DIR


# GP files can be located in subfolders in $RUNTIME_SRC_DIR, for browser we need to put them all in a single folder
echo "✅ Copying runtime sources from >${RUNTIME_SRC_DIR}<"
mkdir -p $BUILD_DIR/runtime/lib
cp $RUNTIME_SRC_DIR/* $BUILD_DIR/runtime 2>/dev/null               # Copy top level files
cp $RUNTIME_SRC_DIR/lib/* $BUILD_DIR/runtime/lib 2>/dev/null        # Copy files from lib/ that are not in subfolder
cp -R $RUNTIME_SRC_DIR/lib/**/* $BUILD_DIR/runtime/lib 2>/dev/null  # Flatten the subfolders structure into one lib/

echo "✅ Building..."
cd "$BUILD_DIR/smallvm"

gcc -std=c99 -Wall -O3 -mmacosx-version-min=10.14 \
-D NO_CAMERA \
-I/usr/local/include/SDL2 \
cache.c dict.c embeddedFS.c events.c gp.c graphicsPrims.c interp.c jpegPrims.c mem.c memGC.c oop.c parse.c \
pathPrims.c prims.c serialPortPrims.c sha1.c sha2.c socketPrims.c soundPrims.c textAndFontPrims.c vectorPrims.c networkPrims.c \
/usr/local/lib/libSDL2.a \
/usr/local/lib/libcairo.a \
/usr/local/lib/libpixman-1.a \
/usr/local/lib/libfreetype.a \
/usr/local/lib/libfontconfig.a \
/usr/local/lib/libjpeg.a \
/usr/local/lib/libpng.a \
/usr/local/lib/libportaudio.a \
-lz -lbz2 -liconv -lexpat -lcurl \
-framework AudioToolBox -framework AudioUnit -framework Carbon -framework Cocoa \
-framework CoreAudio -framework CoreMIDI -framework ForceFeedback -framework IOKit \
-framework CoreVideo -framework Metal -framework MediaPlayer -framework GameController \
-o ../mac_gp

cd "../.."


echo "✅ Done. Run >.build/mac_gp -h<"

