#!/usr/bin/env bash

function confirm {
	read -r -p "$1 [y/N]" response
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		return 0
	else
		return 1
	fi
}

set -x

# install command line tools
xcode-select --install

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

# install programmer dvorak if necessary...
layout="`defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | egrep -w 'KeyboardLayout Name' |sed -E 's/^.+ = \"?([^\"]+)\"?;$/\1/'`"
if [ "$layout" != "Programmer Dvorak" ]; then
  sudo installer -pkg "./Programmer Dvorak v1.2.pkg" -target /
  sudo rm -f /System/Library/Caches/com.apple.IntlDataCache.le*
fi

# Use it as the only layout
for file in ~/Library/Preferences/com.apple.HIToolbox.plist; do
	for key in AppleCurrentKeyboardLayoutInputSourceID; do
		/usr/libexec/PlistBuddy -c "delete :${key}" ${file}
		/usr/libexec/PlistBuddy -c "add :${key} string 'com.apple.keyboardlayout.Programmer Dvorak'" ${file}
	done
	for key in AppleDefaultAsciiInputSource AppleCurrentAsciiInputSource AppleCurrentInputSource AppleEnabledInputSources AppleInputSourceHistory AppleSelectedInputSources; do
		/usr/libexec/PlistBuddy -c "delete :${key}" ${file}
		/usr/libexec/PlistBuddy -c "add :${key} array" ${file}
		/usr/libexec/PlistBuddy -c "add :${key}:0 dict" ${file}
		/usr/libexec/PlistBuddy -c "add :${key}:0:InputSourceKind string 'Keyboard Layout'" ${file}
		/usr/libexec/PlistBuddy -c "add ':${key}:0:KeyboardLayout ID' integer 6454" ${file}
		/usr/libexec/PlistBuddy -c "add ':${key}:0:KeyboardLayout Name' string 'Programmer Dvorak'" ${file}
	done
done

# copy layout to root
sudo cp ~/Library/Preferences/com.apple.HIToolbox.plist /Library/Preferences/

# Add the kitty terminal
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# install Homebrew
if [ ! -d "/usr/local/Homebrew" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# install source Code Pro and Fira_code fonts
cp ./fonts/SourceCodePro/*.* $HOME/Library/Fonts/
cp ./fonts/Fira_Code_v5.2/ttf/*.* $HOME/Library/Fonts/

# install iTerm
cp -r ./apps/*.* /Applications

# install Homebrew packages
brew install $(cat ./brew.packages)

# Fix the gnupg permissions
sudo chown -R $(whoami) $HOME/.gnupg/
find ~/.gnupg -type f -exec chmod 600 {} \;
find ~/.gnupg -type d -exec chmod 700 {} \;

# install ruby and gems
#gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
#curl -sSL https://get.rvm.io | bash -s stable
#rvm install ruby-head
gem install $(cat ./gem.packages)

# install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# install pip
python3 -m ensurepip --default-pip

# install pip packages
python3 -m pip install $(cat ./pip.packages) --user

# install nvm and node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install --lts
nvm use --lts

# update npm and add packages
npm i -g npm
npm i -g $(cat ./npm.packages)

# install rustup and cargo
if [ ! -f  "$HOME/.cargo/bin/cargo"]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  export PATH=$HOME/.cargo/bin:$PATH
fi
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

# setup zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# setup zinit
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

# copy dotfiles from github along with .config hopefully
pushd $HOME
gmerge dotfiles
popd

pushd $HOME/.config
gmerge .config
popd

# Clone the flutter repo for flutter development
git clone https://github.com/flutter/flutter.git $HOME/flutter

# setup neovim
$HOME/.config/nvim/install.sh

