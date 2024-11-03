#!/bin/zsh

# Dotfiles 기본 디렉토리 설정
DOTFILES_DIR="$HOME/github/younsl/dotfiles/configs"

# 구성 요소와 해당 대상 디렉토리 목록을 key-value 쌍으로 정의
COMPONENTS=(
    "fortune:$HOME/.config/fortune"
    "git:$HOME/.config/git"
    "k9s:$HOME/.config/k9s"
    "neofetch:$HOME/.config/neofetch"
    "nvim:$HOME/.config/nvim"
    "pip:$HOME/.config/pip"
    "zed:$HOME/.config/zed"
    "zshrc:$HOME/.zshrc"  # .zshrc의 대상 경로
)

# 심볼릭 링크 예상 결과 출력 함수
print_symlinks() {
    echo "다음의 심볼릭 링크가 생성됩니다:"
    for entry in "${COMPONENTS[@]}"; do
        COMPONENT="${entry%%:*}"
        TARGET_DIR="${entry#*:}"

        # zshrc는 사용자 지정 경로로 처리
        if [[ "$COMPONENT" == "zshrc" ]]; then
            COMPONENT_PATH="$DOTFILES_DIR/zsh/.zshrc"
        else
            COMPONENT_PATH="$DOTFILES_DIR/$COMPONENT"
        fi

        # 구성 요소 디렉토리 또는 파일 확인 및 링크 출력
        if [[ -e "$COMPONENT_PATH" ]]; then
            echo "$TARGET_DIR -> $COMPONENT_PATH"
        else
            echo "존재하지 않음: $COMPONENT_PATH"
        fi
    done
}

# 심볼릭 링크 생성 함수
create_symlinks() {
    # ~/.config 디렉토리가 없으면 생성
    mkdir -p "$HOME/.config"

    for entry in "${COMPONENTS[@]}"; do
        COMPONENT="${entry%%:*}"
        TARGET_DIR="${entry#*:}"

        # zshrc 파일 경로 설정
        if [[ "$COMPONENT" == "zshrc" ]]; then
            COMPONENT_PATH="$DOTFILES_DIR/zsh/.zshrc"
        else
            COMPONENT_PATH="$DOTFILES_DIR/$COMPONENT"
        fi

        # 구성 요소가 디렉토리인지 파일인지 확인
        if [[ -d "$COMPONENT_PATH" ]]; then
            rm -rf "$TARGET_DIR"
            ln -sf "$COMPONENT_PATH" "$TARGET_DIR"
            echo "$TARGET_DIR -> $COMPONENT_PATH (디렉토리로 심볼릭 링크 생성)"

        elif [[ -f "$COMPONENT_PATH" ]]; then
            rm -f "$TARGET_DIR"
            ln -sf "$COMPONENT_PATH" "$TARGET_DIR"
            echo "$TARGET_DIR -> $COMPONENT_PATH (파일로 심볼릭 링크 생성)"

        else
            echo "존재하지 않음: $COMPONENT_PATH"
        fi
    done
}

# 사용자에게 실행 여부 묻기
prompt_user() {
    read -p "이 작업을 수행하시겠습니까? (y/n): " REPLY
    echo  # 새로운 줄 추가
}

install_precommit() {
  if ! command -v pre-commit &>/dev/null; then
    echo "pre-commit not found. Installing via Homebrew..."
    brew install pre-commit
  else
    echo "pre-commit is already installed."
    pre_commit_version=$(pre-commit --version)
    echo "pre-commit version: $pre_commit_version"
  fi

  printf "\n"
}

# 메인 함수
main() {
    print_symlinks
    prompt_user

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_symlinks
        echo "심볼릭 링크가 성공적으로 생성되었습니다!"
    else
        echo "작업이 취소되었습니다."
    fi

    install_precommit
    pre-commit install
}

# 스크립트 실행
main
