sudo nvram SystemAudioVolume=" " # disables boot chime
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

# ------------------- REDUCE ANIMATION TIME ------------------ #

defaults write com.apple.dock springboard-page-duration -float .1
defaults write com.apple.dock springboard-hide-duration -float .1
defaults write com.apple.dock springboard-show-duration -float .1
defaults write com.apple.dock autohide-time-modifier -int 0
killall Dock

# ------------------------ SCREENSHOTS ----------------------- #

defaults write com.apple.screencapture location /Users/h/Pictures
defaults write com.apple.screencapture type -string "png"

# -------------------------- FINDER -------------------------- #

defaults write com.apple.finder DisableAllAnimations -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# --------------------------- DOCK --------------------------- #

defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock autohide-delay -float 0
