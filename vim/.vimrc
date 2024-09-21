" ---------- 기본 설정 ----------

" 줄 번호 표시
set number

" 탭 대신 스페이스 사용
set expandtab

" 탭 너비 설정 (2칸)
set tabstop=2
set shiftwidth=2

" 자동 들여쓰기
set autoindent
set smartindent

" 검색 시 대소문자 구분 없음
set ignorecase

" 대소문자 포함 검색 시 대소문자 구분
set smartcase

" 실시간 검색 결과 하이라이트
set hlsearch
set incsearch

" 커서가 화면 밖으로 나가지 않게 하기
set nowrap

" 커서가 어디에 있는지 항상 표시 (상,하 여백 확보)
set scrolloff=8

" 백업 파일 생성하지 않기
set nobackup
set nowritebackup
set noswapfile

" 문법 강조 (Syntax Highlighting)
syntax on

" 파일 인코딩 설정 (UTF-8)
set encoding=utf-8

" 파일 자동 업데이트 (다른 프로그램에서 파일이 수정될 때)
set autoread

" 클립보드 공유 (복사/붙여넣기)
set clipboard=unnamedplus

" ---------- UI 설정 ----------

" 상태 줄을 항상 보이게 설정
set laststatus=2

" 탭이 아닌 스페이스를 사용할 때 공백을 하이라이트
set listchars=tab:»\ ,trail:·
set list

" 괄호 자동 매칭 시 강조
set showmatch

" 컬러 스킴 (colorscheme)
colorscheme black  " Vim에 기본 포함된 테마

" 커서 라인 하이라이트
set cursorline