defaults write com.apple.dock springboard-page-duration -float .1
defaults write com.apple.dock springboard-hide-duration -float .1
defaults write com.apple.dock springboard-show-duration -float .1
defaults write com.apple.dock autohide-time-modifier -int 0
killall Dock

defaults write com.apple.screencapture location /Users/h/Pictures
