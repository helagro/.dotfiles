local plugins = {{
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
        require("better_escape").setup()
    end
}, {
    "stevearc/conform.nvim",
    --  for users those who want auto-save conform + lazyloading!
    -- event = "BufWritePre"
    config = function()
        require "custom.configs.conform"
    end
}, {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle", -- optional for lazy loading on command
    event = {"InsertLeave", "TextChanged"}, -- optional for lazy loading on trigger events
    opts = {}
}, {
    "epwalsh/obsidian.nvim",
    version = "*",
    ft = "markdown",
    workspaces = {{
        name = "personal",
        path = "~/Dropbox/vault"
    }},
    dependencies = {"nvim-lua/plenary.nvim"}
}}

return plugins
