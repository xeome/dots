alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
alias fixmouse="su -c 'echo on > /sys/bus/usb/devices/1-2/power/control'"
alias mp3='yt-dlp -x --audio-format mp3'
alias v='neovide --multigrid'
alias gamerun='mesa_glthread=true gamemoderun'
alias xdpreload='sudo xdp-loader unload -a wlan0; sudo xdp-loader load -m skb -s prog wlan0 obj/icmp_block.o'
alias yt="yt-dlp --format 'bestvideo[height<=1080]+bestaudio'"
alias vim='nvim'
alias gia='git add .'
alias gica='git commit -a'
alias rsync='rsync -avz --progress --partial --human-readable'
alias tldr='cht.sh'
