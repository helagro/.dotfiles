if [ -d "$HOME/.iterm2" ]; then
    defaults write com.googlecode.iterm2 PrefsCustomFolder "$HOME/.dotfiles"
fi

if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew tap zackelia/formulae

# --------------------------- DUTI --------------------------- #

brew install duti

duti -s com.apple.QuickTimePlayerX .mp4 all
duti -s com.apple.QuickTimePlayerX .m4a all

duti -s com.googlecode.iterm2 .sh all
duti -s com.googlecode.iterm2 .zsh all

duti -s com.microsoft.VSCode public.json all
duti -s com.microsoft.VSCode public.plain-text all
duti -s com.microsoft.VSCode public.python-script all
duti -s com.microsoft.VSCode public.shell-script all
duti -s com.microsoft.VSCode public.source-code all
duti -s com.microsoft.VSCode public.text all
duti -s com.microsoft.VSCode public.unix-executable all
duti -s com.microsoft.VSCode .md all
