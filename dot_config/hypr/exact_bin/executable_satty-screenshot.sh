#!/bin/sh

screenshots_dir="$HOME/Pictures/Screenshots"
timestamp=$(date '+%Y%m%d-%H%M%S')
output_file="$screenshots_dir/satty-$timestamp.png"

mkdir -p "$screenshots_dir" || exit 1

grimblast --freeze --filetype ppm save area - \
  | satty --filename - \
      --fullscreen \
      --copy-command wl-copy \
      --initial-tool brush
