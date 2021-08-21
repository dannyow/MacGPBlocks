#!/bin/sh

echo "✅ Copying app to .build folder for scripts/monitor.js"

mkdir "$SRCROOT/.build"
cp -r "$TARGET_BUILD_DIR/$WRAPPER_NAME" "$SRCROOT/.build"
