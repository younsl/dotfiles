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
    filetypes = { "helm" },
    root_markers = { "Chart.yaml" },
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
                }
            }
        })
    end,
    settings = {
        Lua = {}
    }
})

-- Rust LSP
vim.lsp.config('rust_analyzer', {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", ".git" },
    settings = {
        ["rust-analyzer"] = {
            check = {
                command = "clippy",
            },
        },
    },
})

-- YAML LSP
vim.lsp.config('yamlls', {
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml", "yaml.docker-compose" },
    root_markers = { ".git" },
    settings = {
        yaml = {
            schemas = {
                kubernetes = "/*.k8s.yaml",
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["https://json.schemastore.org/github-action.json"] = "/.github/actions/*/action.yaml",
            },
            validate = true,
            completion = true,
            hover = true,
        },
    },
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
vim.lsp.enable({'terraformls', 'gopls', 'helm_ls', 'lua_ls', 'rust_analyzer', 'yamlls', 'cssls'})
