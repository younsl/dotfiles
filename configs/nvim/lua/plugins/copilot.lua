return {
    'github/copilot.vim',
    config = function()
        -- Enable Copilot with automatic key mapping
        vim.g.copilot_assume_mapped = true

        -- Allow Tab key for accepting suggestions
        vim.g.copilot_no_tab_map = false

        -- Disable Copilot for specific file types
        vim.g.copilot_filetypes = {
          markdown = false  -- Disable in markdown files
        }
    end
}
