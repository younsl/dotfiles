#!/bin/bash

#------------------------------------------------------------------------
#
# 888                     888           888                           
# 888                     888           888                           
# 888                     888           888                           
# 88888b.  .d88b.  .d88b. 888888.d8888b 888888888d888 8888b. 88888b.  
# 888 "88bd88""88bd88""88b888   88K     888   888P"      "88b888 "88b 
# 888  888888  888888  888888   "Y8888b.888   888    .d888888888  888 
# 888 d88PY88..88PY88..88PY88b.      X88Y88b. 888    888  888888 d88P 
# 88888P"  "Y88P"  "Y88P"  "Y888 88888P' "Y888888    "Y88888888888P"  
#                                                            888      
#                                                           888      
#                                                           888  
#
#------------------------------------------------------------------------

# Reference: https://github.com/sheharyarn/dotfiles/tree/master/iTerm

dotfiles_dir="$HOME/github/younsl/dotfiles"

echo "[i] Checking for iTerm2 installation..."

if [ -d "/Applications/iTerm.app" ]; then
    echo "[i] iTerm2 is already installed."

    # .DS_Store 자동 생성 비활성화
    echo "[i] Disable auto-creation of DS_Store files."
    defaults write com.apple.desktopservices DSDontWriteNetworkStores true &&
    echo "Done."

    # iTerm2 환경설정 dotfiles로 관리 활성화
    echo "[i] Setting iTerm preference folder"
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$dotfiles_dir/iterm2/settings" &&
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true &&
    echo "Done."

    # iTerm2 자동 업데이트 활성화
    echo "[i] Enabling automatic updates"
    defaults write com.googlecode.iterm2 SUEnableAutomaticChecks -bool true &&
    echo "Done."
else
    echo "[e] iTerm2 is not installed."
fi

# See also: defaults read com.googlecode.iterm2