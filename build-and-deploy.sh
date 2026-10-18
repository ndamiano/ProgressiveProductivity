#!/bin/bash

./build.sh "$1"

# Define variables
OUTPUT_ZIP="progressive-productivity_$1.zip"
FACTORIO_MODS_PATH="${FACTORIO_MODS_PATH:-$HOME/.factorio/mods}"

if [ ! -d "$FACTORIO_MODS_PATH" ]; then
  echo "Error: mods directory $FACTORIO_MODS_PATH does not exist. Set FACTORIO_MODS_PATH."
  exit 1
fi

# Check if the build file exists
if [ ! -f "./build/$OUTPUT_ZIP" ]; then
  echo "Error: ./build/$OUTPUT_ZIP does not exist. Did you run the zip script first?"
  exit 1
fi

# Copy the new zip file to the mods directory
cp -r "./build/$OUTPUT_ZIP" "$FACTORIO_MODS_PATH/progressive-productivity_$1.zip"

echo "Mod successfully copied to $FACTORIO_MODS_PATH"
