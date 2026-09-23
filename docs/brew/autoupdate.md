# Brew Autoupdate 가이드

## 개요

Homebrew의 자동 업데이트 기능을 설정하는 두 가지 방법과 각각의 장단점을 비교합니다.

## 설정 방법

### 방법 1: Brew 내장 자동 업데이트 (기본)

#### 설정 방법
```bash
# 24시간마다 자동 업데이트 (86400초)
export HOMEBREW_AUTO_UPDATE_SECS=86400

# 자동 업데이트 비활성화
export HOMEBREW_NO_AUTO_UPDATE=1
```

#### 장점
- 기본 제공 기능으로 별도 설치 불필요
- 환경변수로 간단 제어
- 메모리 사용량 적음

#### 단점
- brew 명령어 실행 시에만 동작 (수동 트리거)
- 업데이트 주기 제어 옵션 제한적
- 로그 및 모니터링 기능 부족

### 방법 2: brew autoupdate (tap 기반)

#### 설치 및 설정
```bash
# tap 설치
brew tap homebrew/autoupdate

# 자동 업데이트 활성화 (24시간마다)
brew autoupdate start 86400

# 고급 옵션과 함께 설정
brew autoupdate start 86400 --upgrade --cleanup --enable-notification

# 즉시 시작 (다음 스케줄을 기다리지 않음)
brew autoupdate start 86400 --immediate

# 모든 옵션 조합
brew autoupdate start 86400 --upgrade --cleanup --enable-notification --immediate

# 상태 확인
brew autoupdate status

# 비활성화
brew autoupdate stop
```

#### 주요 옵션

옵션들은 조합하여 사용 가능하며, 대부분의 경우 `--upgrade --cleanup --immediate` 조합을 권장합니다.

- `--upgrade`: 패키지 업그레이드도 함께 수행
- `--cleanup`: 오래된 버전 자동 정리
- `--enable-notification`: 업데이트 완료 시 macOS 알림
- `--immediate`: 스케줄 등록 후 즉시 첫 업데이트 실행

#### 장점
- 완전 자동화된 백그라운드 업데이트
- launchd 기반으로 정확한 스케줄링
- 상세한 로그 및 알림 기능
- 다양한 고급 옵션 제공
- 실패 시 재시도 로직

#### 단점
- 외부 tap 설치 필요
- 시스템 리소스 추가 사용
- 백그라운드 프로세스 관리 필요

## 권장사항

### 일반 사용자
내장 자동 업데이트 사용:
```bash
echo 'export HOMEBREW_AUTO_UPDATE_SECS=86400' >> ~/.zshrc
```

### 고급 사용자/서버 환경
brew autoupdate tap 사용:
```bash
brew tap homebrew/autoupdate
brew autoupdate start 86400 --upgrade --cleanup --immediate
```

## 현재 dotfiles 설정

현재 이 dotfiles에서는 **방법 2 (brew autoupdate tap)**을 사용하고 있습니다.

- `homebrew/autoupdate` tap이 설치되어 있음
- `brew autoupdate` 서비스가 실행 중
- launchd 기반으로 백그라운드에서 자동 업데이트 수행
- `configs/zsh/.zshrc`에는 별도 설정 없음 (tap 기반 자동화)

### 현재 상태 확인

```bash
brew autoupdate status
launchctl list | grep homebrew
```
