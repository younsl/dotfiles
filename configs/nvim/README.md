# Neovim Key Mappings

-- 이 문서를 요약해봐

-- 
This document provides an overview of the custom key mappings configured for `nvim`. The leader key is set to `Space (␣)` for efficient command access, and various mappings are defined for tab management, window operations, file management, and plugin functionality.

## Leader Key

The leader key is set to **space** (`␣`).

```lua
-- nvim/core/keymaps.lua
vim.g.mapleader = ' '
```

## Key Mappings

### Tab Management

| Key Binding     | Command                | Description               |
|-----------------|------------------------|---------------------------|
| `<leader>t`     | `:tabnew`               | Open a new tab            |
| `<leader>]`     | `:tabnext`              | Go to the next tab        |
| `<leader>[`     | `:tabprevious`          | Go to the previous tab    |
| `<leader>x`     | `:tabclose`             | Close the current tab     |

### Window Management

| Key Binding     | Command                | Description               |
|-----------------|------------------------|---------------------------|
| `<leader>v`     | `:vsplit`               | Vertical split            |
| `<leader>h`     | `:split`                | Horizontal split          |
| `<leader>q`     | `:close`                | Close the current window  |

### Window Navigation

| Key Binding     | Command                | Description                   |
|-----------------|------------------------|-------------------------------|
| `<C-h>`         | `<C-w>h`               | Move to the left window        |
| `<C-j>`         | `<C-w>j`               | Move to the window below       |
| `<C-k>`         | `<C-w>k`               | Move to the window above       |
| `<C-l>`         | `<C-w>l`               | Move to the right window       |

### File Operations

| Key Binding     | Command                | Description     |
|-----------------|------------------------|-----------------|
| `<leader>w`     | `:w`                   | Save the file   |

### Search

| Key Binding     | Command                | Description             |
|-----------------|------------------------|-------------------------|
| `<leader>nh`    | `:nohlsearch`          | Remove search highlight |

### Plugins

#### Nvim-Tree

| Key Binding     | Command                     | Description            |
|-----------------|-----------------------------|------------------------|
| `<leader>n`     | `:NvimTreeToggle`            | Toggle NvimTree        |
| `<leader>c`     | `:NvimTreeCollapse`          | Collapse all nodes     |

#### Telescope

| Key Binding     | Function                    | Description             |
|-----------------|-----------------------------|-------------------------|
| `<leader>ff`    | `builtin.find_files`         | Find files              |
| `<leader>fg`    | `builtin.live_grep`          | Live grep search        |
| `<leader>fb`    | `builtin.buffers`            | List open buffers       |
| `<leader>fh`    | `builtin.help_tags`          | Search help tags        |

## Installation

Ensure you have `nvim` installed along with the necessary plugins, such as `nvim-tree` and `telescope`. You can manage these plugins using a package manager like `Packer`, `Lazy.nvim`, or any other of your choice.

### Example Plugin Setup with Lazy.nvim

Here’s an example of how you can set up these plugins using `Lazy.nvim` in your `init.lua`:

```lua
-- nvim/init.lua
require("lazy").setup({
  -- Nvim Tree
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  
  -- Telescope
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } }
})
```

## Customization

Feel free to customize the key mappings according to your preferences. Modify the key bindings in your configuration file as needed. Here’s an example of how to change the key mapping for saving files:

```lua
-- nvim/core/keymaps.lua
vim.keymap.set('n', '<leader>s', ':w<CR>', { desc = '파일 저장' })  -- Change save to <leader>s
```

## Conclusion

This key mapping configuration enhances your productivity by allowing quick access to essential commands and tools in `nvim`. Explore and modify the mappings to fit your workflow better!

Happy coding!
