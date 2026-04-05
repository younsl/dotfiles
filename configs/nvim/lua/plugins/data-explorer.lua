return {
  'Kyytox/data-explorer.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('data-explorer').setup()
  end,
}
