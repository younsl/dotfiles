return {
    "neovim/nvim-lspconfig",
    config = function()
        -- Terraform LSP
        vim.lsp.config('terraformls', {
            cmd = { "terraform-ls", "serve" },
            filetypes = { "terraform" },
            root_markers = { ".git", ".terraform" },
        })

        -- Go LSP
        vim.lsp.config('gopls', {
            cmd = { "gopls" },
            filetypes = { "go" },
            root_markers = { "go.mod", ".git" },
        })

        -- Helm LSP
        vim.lsp.config('helm_ls', {
            cmd = { "helm_ls", "serve" },
            filetypes = { "yaml" },
            root_markers = { "Chart.yaml", ".git" },
        })

        -- Lua LSP
        vim.lsp.config('lua_ls', {
            cmd = { "lua-language-server" },
            filetypes = { "lua" },
            root_markers = { ".git", ".luarc.json", ".luarc.jsonc" },
            on_init = function(client)
                if client.workspace_folders then
                    local path = client.workspace_folders[1].name
                    if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
                        return
                    end
                end

                client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                    runtime = {
                        version = 'LuaJIT'
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = {
                            vim.env.VIMRUNTIME
                            -- Depending on the usage, you might want to add additional paths here.
                            -- "${3rd}/luv/library"
                            -- "${3rd}/busted/library",
                        }
                    }
                })
            end,
            settings = {
                Lua = {}
            }
        })

        -- CSS LSP
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.completion.completionItem.snippetSupport = true

        vim.lsp.config('cssls', {
            capabilities = capabilities,
            cmd = { "vscode-css-language-server", "--stdio" },
            filetypes = { "css", "scss", "less" },
            root_markers = { ".git" },
            settings = {
                css = {
                    validate = true
                },
                less = {
                    validate = true
                },
                scss = {
                    validate = true
                }
            }
        })

        -- Enable all configured LSP servers
        vim.lsp.enable({'terraformls', 'gopls', 'helm_ls', 'lua_ls', 'cssls'})
    end
}
