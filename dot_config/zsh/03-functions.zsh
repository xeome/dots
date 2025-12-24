# Utils
0short() { curl -F"shorten=$1" https://envs.sh; }
0file()  { curl -F"file=@$1" https://envs.sh; }

zst() {
    tar cf - "$1" | pv -s "$(du -sb "$1" | awk '{print $1}')" | zstd --adapt=min=6,max=19 -T0 >"$1.tar.zst"
}

jqi() {
    jq . "$1" > "tmp_$$.json" && mv "tmp_$$.json" "$1"
}
