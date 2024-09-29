-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    require("nvim-tree").setup {}

    local function open_nvim_tree()
      -- open the tree
      require("nvim-tree.api").tree.open()
    end

    -- Set up automatic opening of NvimTree
    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

    -- Set up key mapping
    vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
  end,
}
