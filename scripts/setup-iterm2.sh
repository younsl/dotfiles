dotfiles_dir="$HOME/github/younsl/dotfiles/configs"

# iTerm2 설치 여부 확인
check_iterm2_installed() {
    if [ -d "/Applications/iTerm.app" ]; then
        echo "[i] iTerm2 is already installed."
        return 0
    else
        echo "[e] iTerm2 is not installed."
        return 1
    fi
}

# .DS_Store 자동 생성 비활성화
disable_ds_store_creation() {
    echo "[i] Disable auto-creation of DS_Store files."
    defaults write com.apple.desktopservices DSDontWriteNetworkStores true &&
    echo "Done."
}

# iTerm2 환경설정 dotfiles로 관리 활성화
set_iterm2_preferences() {
    echo "[i] Setting iTerm preference folder"
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$dotfiles_dir/iterm2/settings" &&
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true &&
    echo "Done."
}

# iTerm2 자동 업데이트 활성화
enable_automatic_updates() {
    echo "[i] Enabling automatic updates"
    defaults write com.googlecode.iterm2 SUEnableAutomaticChecks -bool true &&
    echo "Done."
}

# 메인 함수
main() {
    echo "[i] Checking for iTerm2 installation..."

    if check_iterm2_installed; then
        disable_ds_store_creation
        set_iterm2_preferences
        enable_automatic_updates
    fi
}

# 메인 함수 호출
main
