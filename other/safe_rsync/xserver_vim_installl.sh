# ncurses　をインストール
mkdir ~/opt && cd $_
wget http://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.1.tar.gz
tar zxfv ncurses-6.1.tar.gz
cd ncurses-6.1
./configure --prefix=$HOME/local
make
make install

# Vim　をインストール
cd ~/opt
git clone https://github.com/vim/vim.git
cd vim
./configure --with-features=huge --enable-fail-if-missing --prefix=$HOME/local --with-local-dir=$HOME/local
make
make install

# 環境設定
vi ~/.bashrc
# .bashrc に下記行を追加
export PATH=$PATH:$HOME/local/bin
alias vi='vim'