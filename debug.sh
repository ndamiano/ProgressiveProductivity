# Delete existing mods with the same name
rm -rf $FACTORIO_MODS_PATH/progressive-productivity*

# Copy the new zip file to the mods directory
cp -r "." "$FACTORIO_MODS_PATH/progressive-productivity_$1"