#!/bin/zsh

# ------------------------- FUNCTIONS ------------------------ #

ask() {
    read "response?$1 (y/n) "
    [[ "$response" =~ ^[Yy]$ ]]
}

# ------------------------- SCRIPT ------------------------ #

cd $HOME/.dotfiles/setup

echo "RUNNING setup/general.sh"
./general.sh

if [ "$(uname)" = "Darwin" ]; then
    echo "RUNNING setup/macOS/general.sh"
    ./macOS/general.sh

    if ask "RUN setup/macOS/brewPkgs.sh?"; then
        ./macOS/brewPkgs.sh
    fi

    if ask "RUN setup/macOS/os.sh?"; then
        ./macOS/os.sh
    fi

elif [ "$(uname)" = "Linux" ]; then
    echo "RUNNING setup/linux/general.sh"
    ./linux/general.sh
fi

source $HOME/.zshrc
