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

-- Move cwd to ~/github/ and focus it in nvim-tree
local function focus_github_directory()
    -- Change working directory
    vim.cmd('cd ~/github/')

    -- nvim-tree API
    local api = require('nvim-tree.api')

    -- Open the tree if it is closed
    if not api.tree.is_visible() then
        api.tree.open() -- Open tree when closed
    end

    -- Set root to current directory and focus
    api.tree.change_root(vim.fn.getcwd())
    vim.cmd('NvimTreeFindFile') -- Focus current directory
end

-- Keymap to jump to and focus ~/github/
vim.keymap.set('n', '<leader>g', focus_github_directory,
    { noremap = true, silent = true, desc = "Focus ~/github/ in NvimTree" })

-- Picker (native cmdline completion)
vim.keymap.set('n', '<leader>ff', ':find ', { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', ':Grep ', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', ':buffer ', { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fh', ':help ', { desc = 'Help tags' })

-- Git Fugitive
vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = 'Git status' })
vim.keymap.set('n', '<leader>gd', ':Git diff<CR>', { desc = 'Git diff all changes' })
vim.keymap.set('n', '<leader>gdf', ':Gdiff<CR>', { desc = 'Git diff current file' })
vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', { desc = 'Git commit' })
vim.keymap.set('n', '<leader>gcb', ':Git checkout -b ', { desc = 'Git create new branch' })
vim.keymap.set('n', '<leader>gp', ':Git push<CR>', { desc = 'Git push' })
vim.keymap.set('n', '<leader>gl', ':Git log<CR>', { desc = 'Git log' })
vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { desc = 'Git blame' })
vim.keymap.set('n', '<leader>gq', ':Git close<CR>', { desc = 'Close all git windows' })
vim.keymap.set('n', '<leader>ga', ':Git add .<CR>', { desc = 'Git add all files' })
vim.keymap.set('n', '<leader>gac', function()
  vim.cmd('Git add .')
  vim.cmd('Git commit')
end, { desc = 'Git add all and commit' })

