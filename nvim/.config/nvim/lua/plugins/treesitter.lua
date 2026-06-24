return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
        local parsers = {
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
            "mermaid",
            "rust",
            "json",
            "json5",
            "java",
            "kotlin",
            "scala",
            "javadoc",
            "toml",
            "make",
            "cmake",
            "sql",
        }
        require("nvim-treesitter").install(parsers)

        local patterns = {}
        for _, parser in ipairs(parsers) do
            local parser_patterns = vim.treesitter.language.get_filetypes(parser)
            for _, pp in pairs(parser_patterns) do
                table.insert(patterns, pp)
            end
        end

        --     -- use bash parser for zsh files
        vim.treesitter.language.register("bash", "zsh")
        vim.treesitter.language.register("groovy", "Jenkinsfile")
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo[0][0].foldmethod = "expr"

        vim.api.nvim_create_autocmd("FileType", {
            pattern = patterns,
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
}
