export ZSH="$HOME/.oh-my-zsh"

source "$HOME/.dotfiles/.zshrc/shared.sh"
source "$HOME/.dotfiles/.zshrc/secrets.sh"
source "$HOME/.dotfiles/.zshrc/zshOpt.zsh"

if [ "$(uname)" = "Darwin" ]; then
  source "$HOME/.dotfiles/.zshrc/macOS.sh"
elif [ "$(uname)" = "Linux" ]; then
  source "$HOME/.dotfiles/.zshrc/"
fi

source $ZSH/oh-my-zsh.sh

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
