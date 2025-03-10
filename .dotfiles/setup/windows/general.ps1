winget install JanDeDobbeleer.OhMyPosh -s winget
winget install --id Microsoft.VisualStudioCode -e

winget uninstall "Microsoft News" --silent --accept-source-agreements
winget uninstall "Disney+" --silent --accept-source-agreements
winget uninstall "Microsoft Tips" --silent --accept-source-agreements
winget uninstall "MSN Weather" --silent --accept-source-agreements
winget uninstall "Movies & TV" --silent --accept-source-agreements
winget uninstall "Spotify Music" --silent --accept-source-agreements
winget uninstall "Windows Maps" --silent --accept-source-agreements
winget uninstall "Xbox TCUI" --silent --accept-source-agreements
winget uninstall "Xbox Game Bar Plugin" --silent --accept-source-agreements
winget uninstall "Xbox Game Bar" --silent --accept-source-agreements
winget uninstall "Xbox Identity Provider" --silent --accept-source-agreements
winget uninstall "Xbox Game Speech Windows" --silent --accept-source-agreements

# ========================= SETTINGS ========================= #

# Show hidden files and folders
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
# Don't hide file extensions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 1

# ======================== LOCKSCREEN ======================== #

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'ContentDeliveryAllowed' -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenEnabled' -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenOverlayEnabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-88000326Enabled' -Value 0

# ========================== RESTART ========================= #

Get-Process -Name explorer | Stop-Process
start explorer.exe