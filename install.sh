git clone https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git
cd ./San-Francisco-Pro-Fonts
mkdir ~/.fonts
cp -r * ~/.fonts
cd ..
cp -r .config ~/ && cp -r .local ~/
sudo cp ./zshenv /etc/zsh/zshenv