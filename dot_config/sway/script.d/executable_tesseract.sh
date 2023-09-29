#!/bin/bash
#################################################
##
#### Tesseract helper
##
#################################################
ocrdata=$(mktemp)
tmpdata=$(mktemp)

grim -g "$(slurp)" - > $tmpdata
cat $tmpdata | tesseract - stdout -l eng+tur --psm 6 2>/dev/null | sed -E -e '/^[[:space:]]*$/b' -e ':a;N;$!ba;s/([^[:space:]])\n/\1 /g' | sed 's/\n//g' > $ocrdata
[[ ! -s $ocrdata ]] && exit

case $@ in
	--extract|-e)
		out="$(cat $ocrdata | wofi --show dmenu --prompt "OCR" -n -k /dev/null)"
	;;
	--translate|-t)
		out="$(cat $ocrdata | trans -brief :tr - | wofi --show dmenu --prompt "Translator" -n -k /dev/null)"
	;;
esac

[[ -n "$out" ]] && echo $out | wl-copy
rm $ocrdata $tmpdata
