function addTerminalSpacer {
    defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'
    killall Dock
}
