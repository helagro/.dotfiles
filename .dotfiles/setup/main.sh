sourceLine="source \"$HOME/.dotfiles/.zshrc/router.sh\""
grep -qF "$sourceLine" "$HOME/.zshrc" || echo "$sourceLine" >>"$HOME/.zshrc"
