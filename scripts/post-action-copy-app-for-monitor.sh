#!/bin/sh
#
# This script called by Xcode as Build/Post-action in scheme MacGPBlocks
# "$SRCROOT/scripts/post-action-copy-app-for-monitor.sh"
# Copies the freshly built app to the .build/ folder

echo "✅ Copying app to .build folder for scripts/monitor.js"

mkdir "$SRCROOT/.build"
cp -r "$TARGET_BUILD_DIR/$WRAPPER_NAME" "$SRCROOT/.build"
