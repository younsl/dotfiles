-- Enable line numbers
vim.wo.number = true

-- Enable relative line numbers
vim.wo.relativenumber = true

-- Set tab width to 2 spaces
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.showtabline = 2

-- Enable smart indenting
vim.o.smartindent = true

-- Preserve indentation on line wrap
vim.o.breakindent = true

-- Wrap long lines at word boundaries
vim.o.linebreak = true

-- Default split direction: horizontal splits open below, vertical splits open right
vim.o.splitbelow = true
vim.o.splitright = true

-- Enable mouse support in all modes
vim.o.mouse = 'a'

-- Set a column at 80 characters
vim.o.colorcolumn = '80'

-- Set a column at 100 characters for Go files
vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
      vim.opt_local.colorcolumn = "100"
    end
})

-- Enable clipboard integration
if vim.fn.has('mac') == 1 then
    vim.o.clipboard = 'unnamed'
else
    vim.o.clipboard = 'unnamedplus'
end

-- Enable persistent undo
vim.o.undofile = true

-- Highlight the current line
vim.o.cursorline = true

-- Set minimum number of screen lines above and below the cursor
vim.o.scrolloff = 8

-- Faster update time
vim.o.updatetime = 250

-- Enable case-insensitive search unless capital letters are used
vim.o.ignorecase = true
vim.o.smartcase = true

-- Enable auto-saving when focus is lost
vim.cmd [[autocmd FocusLost * silent! wa]]

-- Disable default statusline (using lualine instead)
vim.o.laststatus = 0
vim.o.ruler = false
vim.o.showcmd = false
vim.o.showmode = false
