return {
    'github/copilot.vim',
    config = function()
        -- Copilot 기본 설정
        vim.g.copilot_assume_mapped = true
        vim.g.copilot_no_tab_map = false
    end
}
