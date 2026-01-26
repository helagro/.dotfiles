ask() {
    echo -n "$1 (y/n) "
    read response
    [[ "$response" =~ ^[Yy]$ ]]
}

if [ -d "$HOME/.iterm2" ]; then
    defaults write com.googlecode.iterm2 PrefsCustomFolder "$HOME/.dotfiles"
fi

if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew tap zackelia/formulae
npm i -g firebase-tools

# --------------------------- DUTI --------------------------- #

brew install duti

# Audio
duti -s com.apple.QuickTimePlayerX .mp3 all
duti -s com.apple.QuickTimePlayerX .wav all
duti -s com.apple.QuickTimePlayerX .m4a all

# Video
duti -s com.apple.QuickTimePlayerX .mp4 all
duti -s com.apple.QuickTimePlayerX .mov all

# Shell scripts
duti -s com.googlecode.iterm2 .sh all
duti -s com.googlecode.iterm2 .zsh all

# Code
duti -s com.microsoft.VSCode public.json all
duti -s com.microsoft.VSCode public.plain-text all
duti -s com.microsoft.VSCode public.python-script all
duti -s com.microsoft.VSCode public.shell-script all
duti -s com.microsoft.VSCode public.source-code all
duti -s com.microsoft.VSCode public.text all
duti -s com.microsoft.VSCode public.unix-executable all
duti -s com.microsoft.VSCode .md all

# =================================== OTHER ================================== #

defaults write com.openai.chat NSRequiresAquaSystemAppearance -bool YES

if ask "Install go"; then
    brew install go
fi

if ask "Install toggl cli?"; then
    go get github.com/sachaos/toggl
fi

if ask "Install gosling?"; then
    go install github.com/Samyak2/gosling@latest
fi

if command -v go && ask "Install blink timer?"; then
    go install github.com/helagro/look_away/cmd/look_away@latest
fi
