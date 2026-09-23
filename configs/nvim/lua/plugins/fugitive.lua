return {
  'tpope/vim-fugitive',
  config = function()
    -- Git commit 메시지 작성시 spell check 활성화
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "gitcommit",
      callback = function()
        vim.opt_local.spell = true
        vim.opt_local.spelllang = "en_us"
        vim.opt_local.textwidth = 72
        vim.opt_local.colorcolumn = "72"
      end,
    })
  end,
}