#!/bin/zsh

# ------------------------- FUNCTIONS ------------------------ #

ask() {
    echo -n "$1 (y/n) "
    read response
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
