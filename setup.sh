#!/usr/bin/env bash

function confirm {
	read -r -p "$1 [y/N]" response
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		return 0
	else
		return 1
	fi
}

# clone the repo
if [ -d "$HOME/setup/mac-setup" ]; then
	echo Repo downloaded updating...
	cd $HOME/setup/mac-setup
	echo Repo updated
	git pull
else
	echo Downloading repo...
	git clone https://github.com/jhessin/mac-setup.git $HOME/setup/mac-setup
	cd $HOME/setup/mac-setup
fi


# install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install Homebrew packages
brew install $(cat ./brew.packages)

# install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# install pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py

# install pip packages
pip3 install $(cat ./pip.packages) --user

# update npm and add packages
npm i -g $(cat ./npm.packages)

# install rustup and cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
export PATH=$HOME/.cargo/bin:$PATH
cargo install $(cat ./cargo.packages)

# setup gh login
if confirm "would you like to login to gh?"; then
	gh auth login
fi

# copy bin from github
if [ ! -d "$HOME/.local/bin/.git" ]; then
	rm -rf $HOME/.local/bin
	gh repo clone jhessin/bin $HOME/.local/bin
fi

# add the bin to you path for tools
PATH=$PATH:$HOME/.local/bin

# copy dotfiles from github along with .config hopefully
pushd $HOME
gmerge dotfiles
git submodule update --init --recursive
popd

# setup zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# setup zinit
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

# setup neovim
$HOME/.config/nvim/install.sh

# configure zsh as default shell
if confirm "Would you like to set zsh as your default shell?"; then
	chsh -s /usr/bin/zsh
fi

