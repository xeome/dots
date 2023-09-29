#!/bin/bash
python3 ~/.config/sway/scripts.d/clipboard.py -r 100 | wofi --show dmenu --prompt "Clipboard" -k /dev/null | cut -d ":" -f1 | xargs python3 ~/.config/sway/scripts.d/clipboard.py -s | wl-copy
