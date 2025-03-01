return {
    "neovim/nvim-lspconfig",
    config = function()
        local lspconfig = require('lspconfig')

        -- Terraform LSP
        lspconfig.terraformls.setup({
            cmd = { "terraform-ls", "serve" },
            filetypes = { "terraform" },
            root_dir = lspconfig.util.root_pattern(".git", ".terraform"),
        })
        
        -- Go LSP
        lspconfig.gopls.setup({
            cmd = { "gopls" },
            filetypes = { "go" },
            root_dir = lspconfig.util.root_pattern("go.mod", ".git"),
        })
        
        -- Helm LSP
        lspconfig.helm_ls.setup({
            cmd = { "helm-ls", "serve" },
            filetypes = { "yaml" },
            root_dir = lspconfig.util.root_pattern("Chart.yaml", ".git"),
        })

        -- Lua LSP
        lspconfig.lua_ls.setup({
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

        lspconfig.cssls.setup({
            capabilities = capabilities,
            cmd = { "vscode-css-language-server", "--stdio" },
            filetypes = { "css", "scss", "less" },
            root_dir = lspconfig.util.root_pattern(".git"),
            settings = {
                {
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
            }
        })
    end
}
