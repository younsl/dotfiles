# Neovim LSP Configuration Guide

This guide covers the setup and migration from nvim-lspconfig to Neovim 0.11+ native LSP configuration.

For detailed information, refer to the official [nvim-lspconfig Important Note](https://github.com/neovim/nvim-lspconfig?tab=readme-ov-file#important-%EF%B8%8F)

## ⚠️ IMPORTANT - Breaking Changes in Neovim 0.11+

### Deprecation Notice
- `require('lspconfig')` framework is **deprecated** in Neovim 0.11+
- The old configuration method will be removed in nvim-lspconfig v3.0.0
- **Migration to `vim.lsp.config()` is required**

### Migration Timeline
- **Neovim 0.11+**: New `vim.lsp.config()` API available
- **nvim-lspconfig v3.0.0**: Old `require('lspconfig')` removed
- **Action Required**: Migrate existing configurations

## Installation

### Method 1: Lazy.nvim (Current dotfiles setup)

```lua
-- In lua/plugins/nvim-lspconfig.lua
return {
    "neovim/nvim-lspconfig",
    config = function()
        -- LSP configuration using vim.lsp.config()
    end
}
```

### Method 2: Manual Installation

```bash
git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
```

## Quick Start

### 1. Install Language Servers

nvim-lspconfig is only a configuration plugin. **You MUST install the actual language server binaries** on your system for LSP functionality to work. The plugin cannot provide language features without these servers.

```bash
# Python - Required for Python LSP features
npm i -g pyright

# Go - Required for Go LSP features
go install golang.org/x/tools/gopls@latest

# Terraform - Required for Terraform LSP features
brew install terraform-ls

# Lua - Required for Lua LSP features
brew install lua-language-server

# CSS/HTML/JSON - Required for web development LSP features
npm i -g vscode-langservers-extracted
```

**Verification**: Check if language servers are installed:
```bash
# Quick check all servers
which terraform-ls gopls helm_ls lua-language-server vscode-css-language-server

# Individual check
command -v gopls && echo "✓ gopls installed" || echo "✗ gopls missing"
```

### 2. Basic Configuration (Neovim 0.11.4)

```lua
-- Enable basic LSP servers
vim.lsp.enable('pyright')
vim.lsp.enable('gopls')
vim.lsp.enable('terraformls')
vim.lsp.enable('lua_ls')
vim.lsp.enable('cssls')
```

### 3. Verify Setup

**Interactive:**

```vim
:checkhealth vim.lsp
```

**Headless (Terminal):**

```bash
# Check if LSP server binaries are installed on PATH
# Use this when LSP features aren't working or after fresh installation
nvim --headless -c 'lua
for _, s in ipairs({"terraform-ls", "gopls", "helm_ls", "lua-language-server", "vscode-css-language-server"}) do
  print(s .. ": " .. (vim.fn.executable(s) == 1 and "✓ installed" or "✗ not found"))
end' -c 'qa'

# Alternative: Simple shell check for binary availability
which terraform-ls gopls helm_ls lua-language-server vscode-css-language-server
```

## Migration from Old Configuration

### Before (Deprecated - nvim-lspconfig)

```lua
return {
    "neovim/nvim-lspconfig",
    config = function()
        local lspconfig = require('lspconfig')

        lspconfig.pyright.setup({
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                    },
                },
            },
        })

        lspconfig.gopls.setup({
            cmd = { "gopls" },
            filetypes = { "go", "gomod" },
            root_dir = lspconfig.util.root_pattern("go.mod", ".git"),
        })
    end
}
```

### After (New - vim.lsp.config)

```lua
return {
    "neovim/nvim-lspconfig",
    config = function()
        -- Python LSP
        vim.lsp.config('pyright', {
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                    },
                },
            },
        })

        -- Go LSP
        vim.lsp.config('gopls', {
            cmd = { "gopls" },
            filetypes = { "go", "gomod" },
            root_markers = { "go.mod", ".git" },
        })

        -- Enable configured servers
        vim.lsp.enable({'pyright', 'gopls'})
    end
}
```

## Complete Configuration Example

### Current dotfiles configuration
```lua
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
```

## Key API Changes

| Old API | New API | Notes |
|---------|---------|-------|
| `require('lspconfig')` | `vim.lsp.config()` | Main configuration function |
| `lspconfig.server.setup()` | `vim.lsp.config('server', {})` | Server setup |
| `root_dir = lspconfig.util.root_pattern()` | `root_markers = { "pattern" }` | Root detection |
| Auto-start | `vim.lsp.enable('server')` | Manual activation required |

## Alternative: LSP Directory Structure

Instead of using `vim.lsp.config()`, you can create individual LSP config files:

### Directory Structure
```
~/.config/nvim/
├── init.lua
└── lsp/
    ├── gopls.lua
    ├── pyright.lua
    ├── terraformls.lua
    └── lua_ls.lua
```

### Example: `~/.config/nvim/lsp/gopls.lua`
```lua
return {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod' },
    root_markers = { 'go.mod', '.git' },
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
        },
    },
}
```

### Enable in `init.lua`
```lua
vim.lsp.enable({'gopls', 'pyright', 'terraformls', 'lua_ls'})
```

## Troubleshooting

### Common Issues

1. **Server not starting**
   ```vim
   :checkhealth vim.lsp
   ```

2. **Deprecation warnings**
   - Ensure you're using `vim.lsp.config()` instead of `require('lspconfig')`
   - Update to Neovim 0.11+

3. **Server not found**
   - Verify language server is installed
   - Check `cmd` path in configuration

4. **No completions/diagnostics**
   - Verify filetype detection: `:set filetype?`
   - Check root directory detection
   - Ensure `vim.lsp.enable()` is called

### Health Check Commands
```vim
:checkhealth vim.lsp          " Check LSP health
:LspInfo                      " Show attached clients (if available)
:lua vim.print(vim.lsp.get_clients()) " List active clients
```

## Best Practices

1. **Always use `vim.lsp.enable()`** after configuring servers
2. **Use `root_markers`** instead of `root_dir` functions
3. **Group related configurations** for maintainability
4. **Test with `:checkhealth vim.lsp`** after changes
5. **Keep capabilities consistent** across servers when needed

## Resources

- [Neovim LSP Documentation](https://neovim.io/doc/user/lsp.html)
- [nvim-lspconfig GitHub](https://github.com/neovim/nvim-lspconfig)
- [Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
- [Neovim 0.11 Release Notes](https://neovim.io/doc/user/news-0.11.html)
