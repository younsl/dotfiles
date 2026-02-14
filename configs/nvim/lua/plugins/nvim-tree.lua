-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24-bit color
vim.opt.termguicolors = true

-- Auto change directory to current file
vim.o.autochdir = true

return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    require("nvim-tree").setup {
      update_focused_file = {
        enable = true,           -- Auto focus on file open
        update_cwd = true,       -- Update working directory
        ignore_list = {},        -- Files to ignore
      },
      view = {
        width = {
          min = 25,              -- Minimum width
          max = 50,              -- Maximum width (1/3 of screen)
        },
        adaptive_size = true,    -- Auto adjust width by filename length
        number = false,          -- Disable line numbers
        relativenumber = false,  -- Disable relative line numbers
        signcolumn = "yes",      -- Enable sign column for git status and LSP
      },
      git = {
        enable = true,           -- Show git status
        ignore = false,          -- Show git ignored files
      },
      renderer = {
        group_empty = true,      -- Group empty directories
        highlight_git = true,    -- Highlight git status
        indent_markers = {
          enable = true,         -- Show indent markers
        },
      },
    }

    local function open_nvim_tree()
      -- Open tree on startup
      require("nvim-tree.api").tree.open()
    end

    -- Set up automatic opening of NvimTree
    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
  end,
}
