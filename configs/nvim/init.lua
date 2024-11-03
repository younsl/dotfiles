--------------------------------------------------
-- Configuration
--------------------------------------------------

-- Load and configure lazy loading for plugins
require("config.lazy")

--------------------------------------------------
-- Plugin Configurations
--------------------------------------------------

-- Initialize nvim-tree plugin with default settings
require("plugins.nvim-tree")

-- Set up the indent-blankline plugin
require("plugins.indent-blankline")

-- Configure and enable Treesitter for better syntax highlighting and code analysis
require("plugins.nvim-treesitter")

-- Set up Telescope for fuzzy finding
require("plugins.telescope")

require("plugins.nvim-autopairs")

--------------------------------------------------
-- Editor Settings
--------------------------------------------------

require("core.options")

--------------------------------------------------
-- Keymaps
--------------------------------------------------

-- Load custom keymaps
require("core.keymaps")

