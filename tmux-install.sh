git clone https://github.com/gpakosz/.tmux.git ~/.config/oh-my-tmux
mkdir -p ~/.config/tmux
ln -s ~/.config/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf
cp ~/.config/oh-my-tmux/.tmux.conf.local ~/.config/tmux/tmux.conf.local
echo "set -g mouse on
set -g history-limit 30000
bind-key -n C-Right select-pane -R
bind-key -n C-Left select-pane -L
bind-key -n C-S-Right split-window -h" >> ~/.config/tmux/tmux.conf.local
