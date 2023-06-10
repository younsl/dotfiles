#!/bin/bash

# 스크립트에서 에러 발생시 즉시 종료
set -e

# 변수 정의
BRANCH_NAME="latest_branch"
BASE_BRANCH="main"

# 사용자 입력 추가
echo "This script will delete the ${BASE_BRANCH} branch and create the ${BRANCH_NAME} branch."
read -p "Do you want to continue? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Aborted."
    exit 1
fi

# 명령어 실행
git checkout --orphan $BRANCH_NAME
git add -A
git commit -am "Initial commit"

git branch -D $BASE_BRANCH || true
git branch -m $BASE_BRANCH
git push -f origin $BASE_BRANCH

# 완료 메시지 출력
echo "Done."