#!/bin/bash

IFS=$'\n' read -r -d '' -a outputs <<<"$(swaymsg -t get_outputs | jq -r '.[].name')"

if [[ "${#outputs[@]}" == "1" ]]; then
  sed -i "s/set \$scr1.*/set \$scr1          ${outputs[0]}/g" $HOME/.config/sway/conf.d/settings.conf
  sed -i "s/set \$scr2.*/set \$scr2          ${outputs[0]}/g" $HOME/.config/sway/conf.d/settings.conf
elif [[ "${#outputs[@]}" == "2" ]]; then
  sed -i "s/set \$scr1.*/set \$scr1          ${outputs[0]}/g" $HOME/.config/sway/conf.d/settings.conf
  sed -i "s/set \$scr2.*/set \$scr2          ${outputs[1]}/g" $HOME/.config/sway/conf.d/settings.conf
  # Vertical stacking
  # sed -i "s/output \$scr1 pos.*/output \$scr1 pos           0     $(swaymsg -t get_outputs | jq -r '.[1].rect.height')/g" $HOME/.config/sway/conf.d/settings.conf
  # Horizontal stacking (laptop on the right and lower than external monitor)
  sed -i "s/output \$scr1 pos.*/output \$scr2 pos           $(swaymsg -t get_outputs | jq -r '.[1].rect.width')   $(swaymsg -t get_outputs | jq -r '.[1].rect.height/2')/g" $HOME/.config/sway/conf.d/settings.conf
fi
