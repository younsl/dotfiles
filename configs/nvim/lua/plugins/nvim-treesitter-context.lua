return {
  "nvim-treesitter/nvim-treesitter-context",
  config = function()
    require'treesitter-context'.setup {
      enable = true,
      max_lines = 0,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = 'outer',
      mode = 'cursor',
      separator = nil,
      zindex = 20,
      -- TODO: remove after Neovim 0.12.0 markdown treesitter bug is fixed
      on_attach = function(buf)
        return vim.bo[buf].filetype ~= "markdown"
      end,
    }
  end,
}
