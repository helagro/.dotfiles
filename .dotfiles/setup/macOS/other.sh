if [ -d "$HOME/.iterm2" ]; then
    defaults write com.googlecode.iterm2 PrefsCustomFolder "$HOME/.dotfiles"
fi

if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
