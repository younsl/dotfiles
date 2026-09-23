return {
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter", -- 입력 모드 진입 시 로드
      config = function()
        require("nvim-autopairs").setup({})
      end,
    }
}