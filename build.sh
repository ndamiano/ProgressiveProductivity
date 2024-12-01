#!/bin/bash

# Define the version and output zip file name
VERSION=$1
OUTPUT_ZIP="progressive-productivity_$VERSION.zip"

# Ensure a version argument is provided
if [ -z "$VERSION" ]; then
  echo "Error: You must specify a version (e.g., ./build.sh 1.0.0)"
  exit 1
fi

# Define temporary directory for structuring files
TEMP_DIR="build"
TARGET_DIR="$TEMP_DIR/progressive-productivity"

# Clean up any previous build
rm -rf "$TARGET_DIR"
rm -f "$TEMP_DIR/$OUTPUT_ZIP"

# Create the required folder structure
mkdir -p "$TARGET_DIR"

# Copy files into the target directory, excluding unwanted patterns
find . \
  -type f \
  ! -path "*/build/*" \
  ! -path "*/.vscode/*" \
  ! -path "*/node_modules/*" \
  ! -name ".gitignore" \
  ! -name "*.sh" \
  ! -path "*/.git/*" \
  ! -name "package.json" \
  ! -name "package-lock.json" \
  ! -name "*.txt" \
  -exec cp --parents {} "$TARGET_DIR" \;

# Zip the files with the required folder structure
(cd build && zip -r "$OUTPUT_ZIP" "progressive-productivity")

# Clean up the temporary directory
rm -rf "$TARGET_DIR"

echo "Files zipped into build/$OUTPUT_ZIP"