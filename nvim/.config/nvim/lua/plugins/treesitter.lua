return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            ensure_installed = {
                "c",
                "lua",
                "vim",
                "vimdoc",
                "query",
                "elixir",
                "heex",
                "javascript",
                "html",
                "python",
                "go",
                "markdown",
                "markdown_inline",
                "cpp",
                "typescript",
                "tsx",
                "yaml",
                "css",
                "prisma",
                "svelte",
                "graphql",
                "bash",
                "dockerfile",
                "gitignore",
                "latex",
            },
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<CR>", -- set to `false` to disable one of the mappings
                    node_incremental = "<CR>",
                    scope_incremental = "<S-CR>",
                    node_decremental = "<BS>",
                },
            },
        })
        -- use bash parser for zsh files
        vim.treesitter.language.register("bash", "zsh")
    end,
}
