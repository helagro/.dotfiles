source "$HOME/.dotfiles/.zshrc/shared.sh"
source "$HOME/.dotfiles/.zshrc/secrets.sh"

if [ "$(uname)" = "Darwin" ]; then
    source "$HOME/.dotfiles/.zshrc/macOS.sh"
elif [ "$(uname)" = "Linux" ]; then
    source "$HOME/.dotfiles/.zshrc/"
fi
