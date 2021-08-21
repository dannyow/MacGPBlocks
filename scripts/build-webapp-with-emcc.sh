#!/bin/sh
#
# Note (old?): Setting ALLOW_MEMORY_GROWTH=1 causes a 2x to 4x slowdown in Firefox on MacBook Pro!
# Note, March 2018: -O3 faster for Firefox & WASM; -Os faster for Safari & Chrome asm.js
#
# The following options to emcc can help with debugging:
#-s ASSERTIONS=2 \
#-s SAFE_HEAP=1 \
#
# Increased memory from 136314880 (130 MB) to 209715200 (~200 MB)

# set -x # debug

RUNTIME_SRC_DIR=${1:-runtimes/anamorphic/runtime}
VM_SRC_DIR=MacGPBlocks/smallvm
WEBAPP_TARGET_DIR=webapp
BUILD_DIR=.build


rm -r $BUILD_DIR
mkdir -p $BUILD_DIR

echo "✅ Copying vm sources from >${VM_SRC_DIR}"
cp -r $VM_SRC_DIR $BUILD_DIR

# GP files can be located in subfolders in $RUNTIME_SRC_DIR, for browser we need to put them all in a single folder
echo "✅ Copying runtime sources from >${RUNTIME_SRC_DIR}"
mkdir -p $BUILD_DIR/runtime/lib
cp $RUNTIME_SRC_DIR/* $BUILD_DIR/runtime 2>/dev/null               # Copy top level files
cp $RUNTIME_SRC_DIR/lib/* $BUILD_DIR/runtime/lib 2>/dev/null        # Copy files from lib/ that are not in subfolder
cp -R $RUNTIME_SRC_DIR/lib/**/* $BUILD_DIR/runtime/lib 2>/dev/null  # Flatten the subfolders structure into one lib/

echo "✅ Building..."
cd "$BUILD_DIR/smallvm"
emcc -std=gnu99 -Wall -O3 \
    -D EMSCRIPTEN \
    -D NO_JPEG \
    -D NO_SDL \
    -D NO_SOCKETS \
    -D SHA2_USE_INTTYPES_H \
    -s USE_ZLIB=1 \
    -s TOTAL_MEMORY=209715200 \
    -s ALLOW_MEMORY_GROWTH=0 \
    --memory-init-file 0 \
    -s WASM=1 \
    browserPrims.c cache.c dict.c embeddedFS.c events.c gp.c interp.c mem.c memGC.c \
    oop.c parse.c prims.c serialPortPrims.c sha1.c sha2.c soundPrims.c textAndFontPrims.c vectorPrims.c \
    --preload-file ../runtime \
    -o ../gp_wasm.html
cd "../.."

rm "$BUILD_DIR/gp_wasm.html"
cp "$BUILD_DIR/gp_wasm.data" $WEBAPP_TARGET_DIR
cp "$BUILD_DIR/gp_wasm.js" $WEBAPP_TARGET_DIR
cp "$BUILD_DIR/gp_wasm.wasm" $WEBAPP_TARGET_DIR
