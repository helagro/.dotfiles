defaults write com.apple.ActivityMonitor IconType -int 5
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.apple.screensaver askForPasswordDelay -int 1200
defaults write -g AppleAccentColor -int 0

# Disables "smart" quotes
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

# Disables boot chime
sudo nvram SystemAudioVolume=" "

# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Maps caps lock to escape

echo -n "Map caps lock to escape for all users? (y/n) "
read response
if [[ "$response" =~ ^[Yy]$ ]]; then
    hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
fi

# ------------------- REDUCE ANIMATION TIME ------------------ #

defaults write com.apple.dock expose-animation-duration -float 0
defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock autohide-delay -float 0

defaults write com.apple.dock springboard-page-duration -float 0
defaults write com.apple.dock springboard-hide-duration -float 0
defaults write com.apple.dock springboard-show-duration -float 0

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
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.finder FXPreferredGroupBy -string "Tags"

# --------------------------- DOCK --------------------------- #

defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock autohide -bool true

echo -n "Clear dock? (y/n) "
read response
if [[ "$response" =~ ^[Yy]$ ]]; then
    defaults write com.apple.dock persistent-apps -array
fi

killall Dock
