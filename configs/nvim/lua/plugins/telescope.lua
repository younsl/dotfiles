return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  -- 또는 branch = '0.1.x' 사용 가능
  dependencies = {
    'nvim-lua/plenary.nvim'
  },
  config = function()
    require('telescope').setup({
      defaults = {
        file_ignore_patterns = { "node_modules", ".git/" },
      },
      pickers = {
        find_files = {
          hidden = true,  -- 숨겨진 파일/폴더 포함
          follow = true,  -- 심볼릭 링크 따라가기
        },
      },
    })
  end,
}