#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi
input_file="$1"

# This script uses jq to parse the JSON output from matugen.
# It then formats the colors as kernel parameters.
jq_filter='
[
  .special.background,
  .colors.color8,
  .colors.color10,
  .colors.color9,
  .colors.color12,
  .colors.color13,
  .colors.color14,
  .special.foreground,
  .colors.color0,
  .colors.color8,
  .colors.color2,
  .colors.color3,
  .colors.color4,
  .colors.color5,
  .colors.color6,
  .colors.color15
] | .[]
'

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, please install it."
    exit
fi

hex_to_dec() {
  printf "%d" "0x${1}"
}

hex_string_to_rgb() {
  hex_color="${1#\#}" # remove leading #
  r=$(hex_to_dec "${hex_color:0:2}")
  g=$(hex_to_dec "${hex_color:2:2}")
  b=$(hex_to_dec "${hex_color:4:2}")
  echo "$r,$g,$b"
}

temp_file=$(mktemp)
jq -r "$jq_filter" "$input_file" | while read -r hex; do
  hex_string_to_rgb "$hex" >> "$temp_file"
done

default_red=()
default_grn=()
default_blu=()
while IFS=, read -r r g b; do
  default_red+=("$r")
  default_grn+=("$g")
  default_blu+=("$b")
done < "$temp_file"

# --- THIS IS THE MODIFIED LINE ---
# By wrapping the command in a subshell `(...)` and setting IFS inside it,
# we can join the array elements with a comma for this command only.
(IFS=,; echo "vt.default_red=${default_red[*]} vt.default_grn=${default_grn[*]} vt.default_blu=${default_blu[*]}") > "$input_file"

rm "$temp_file"