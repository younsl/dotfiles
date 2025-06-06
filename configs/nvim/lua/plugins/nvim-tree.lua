-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- Enable autochdir - automatically change directory to the file being edited
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
        enable = true,           -- 파일 열면 자동으로 focus
        update_cwd = true,       -- 현재 작업 디렉토리를 변경
        ignore_list = {},        -- 무시할 파일 목록
      },
      view = {
        adaptive_size = true,    -- 파일 트리 창 크기 자동 조절
        number = true,           -- 일반 라인 번호 표시
        relativenumber = true,   -- 상대적 라인 번호 표시
      },
      git = {
        enable = true,           -- Git 상태를 표시
        ignore = false,          -- Git ignore된 파일도 표시
      },
      renderer = {
        group_empty = true,      -- 빈 디렉토리들을 트리 구조에서 하나로 묶어 표시
        highlight_git = true,    -- Git 상태에 따른 하이라이팅
        indent_markers = {
          enable = true,         -- 계층 구조에 따른 들여쓰기 마커
        },
      },
    }

    local function open_nvim_tree()
      -- open the tree
      require("nvim-tree.api").tree.open()
    end

    -- Set up automatic opening of NvimTree
    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
  end,
}
