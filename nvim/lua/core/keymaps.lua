-- Set leader key to space
vim.g.mapleader = ' '

-- Tab management
vim.keymap.set('n', '<leader>t', ':tabnew<CR>', { desc = '새 탭 열기' })
vim.keymap.set('n', '<leader>]', ':tabnext<CR>', { desc = '다음 탭으로 이동' })
vim.keymap.set('n', '<leader>[', ':tabprevious<CR>', { desc = '이전 탭으로 이동' })
vim.keymap.set('n', '<leader>x', ':tabclose<CR>', { desc = '현재 탭 닫기' })

-- Window management
vim.keymap.set('n', '<leader>v', ':vsplit<CR>', { desc = '수직 분할' })
vim.keymap.set('n', '<leader>h', ':split<CR>', { desc = '수평 분할' })
vim.keymap.set('n', '<leader>q', ':close<CR>', { desc = '현재 창 닫기' })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = '왼쪽 창으로 이동' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = '아래 창으로 이동' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = '위 창으로 이동' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = '오른쪽 창으로 이동' })

-- File operations
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = '파일 저장' })

-- Search
vim.keymap.set('n', '<leader>nh', ':nohlsearch<CR>', { desc = '검색 강조 제거' })

-- nvim-tree
vim.keymap.set('n', '<leader>n', ':NvimTreeToggle<CR>', { noremap = true, silent = true, desc = "Toggle NvimTree" })
vim.keymap.set('n', '<leader>c', ':NvimTreeCollapse<CR>', { noremap = true, silent = true, desc = "Collapse NvimTree" })

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })