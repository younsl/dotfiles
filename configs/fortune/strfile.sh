#!/bin/bash

# 현재 디렉토리에서 .fortune 파일 목록을 가져옴
fortune_files=$(find . -maxdepth 1 -type f -name "*.fortune")

# 각 .fortune 파일에 대해 strfile 실행
for fortune_file in $fortune_files; do
  strfile "$fortune_file"
done
