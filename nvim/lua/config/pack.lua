vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and kind == "update" then
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    end
  end,
})

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  gh("nvim-tree/nvim-web-devicons"),
  { src = gh("nvim-tree/nvim-tree.lua"), version = vim.version.range("*") },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  gh("nvim-treesitter/nvim-treesitter-context"),
  gh("stevearc/conform.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("tpope/vim-fugitive"),
  gh("windwp/nvim-autopairs"),
  gh("machakann/vim-sandwich"),
})

for _, name in ipairs({
  "nvim-tree",
  "nvim-treesitter",
  "nvim-treesitter-context",
  "conform",
  "gitsigns",
  "fugitive",
  "nvim-autopairs",
}) do
  require("plugins." .. name)
end

local stamp = vim.fn.stdpath("state") .. "/pack-last-update"

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local stat = vim.uv.fs_stat(stamp)
    if stat and os.time() - stat.mtime.sec < 86400 then
      return
    end
    vim.defer_fn(function()
      vim.pack.update(nil, { force = true })
      vim.fn.writefile({}, stamp)
    end, 100)
  end,
})
