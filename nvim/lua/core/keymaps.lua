-- Set leader key to space
vim.g.mapleader = ' '

local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Helper function for setting keymaps
local function map(mode, lhs, rhs, desc)
  keymap(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
end

-- Tab management
map('n', '<leader>t', ':tabnew<CR>', '새 탭 열기')
map('n', '<leader>]', ':tabnext<CR>', '다음 탭으로 이동')
map('n', '<leader>[', ':tabprevious<CR>', '이전 탭으로 이동')
map('n', '<leader>x', ':tabclose<CR>', '현재 탭 닫기')

-- Window management
map('n', '<leader>v', ':vsplit<CR>', '수직 분할')
map('n', '<leader>h', ':split<CR>', '수평 분할')

-- Window navigation
map('n', '<C-h>', '<C-w>h', '왼쪽 창으로 이동')
map('n', '<C-j>', '<C-w>j', '아래 창으로 이동')
map('n', '<C-k>', '<C-w>k', '위 창으로 이동')
map('n', '<C-l>', '<C-w>l', '오른쪽 창으로 이동')

-- File operations
map('n', '<leader>w', ':w<CR>', '파일 저장')

-- Search
map('n', '<leader>nh', ':nohlsearch<CR>', '검색 강조 제거')
