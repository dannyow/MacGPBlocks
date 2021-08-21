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

set -x

SOURCE_DIR=MacGPBlocks/smallvm
RUNTIME_DIR=runtimes/newMorphic/runtime
WEBAPP_DIR=webapp
BUILD_DIR=.build

rm -r $BUILD_DIR
mkdir -p $BUILD_DIR

cp -r $SOURCE_DIR $BUILD_DIR
cp -r $RUNTIME_DIR $BUILD_DIR

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
cp "$BUILD_DIR/gp_wasm.data" $WEBAPP_DIR
cp "$BUILD_DIR/gp_wasm.js" $WEBAPP_DIR
cp "$BUILD_DIR/gp_wasm.wasm" $WEBAPP_DIR
