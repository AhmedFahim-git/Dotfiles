-- From ChatGPT
-- File: lua/plugins/treesitter-textobjects.lua
return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    config = function()
        require("nvim-treesitter.configs").setup({
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true, -- Jump forward automatically to textobj
                    keymaps = {
                        -- Functions
                        ["af"] = { query = "@function.outer", desc = "Select outer function" },
                        ["if"] = { query = "@function.inner", desc = "Select inner function body" },

                        -- Classes
                        ["ac"] = { query = "@class.outer", desc = "Select outer class" },
                        ["ic"] = { query = "@class.inner", desc = "Select inner class" },

                        -- Blocks (if / for / while / try)
                        ["ab"] = { query = "@block.outer", desc = "Select outer block" },
                        ["ib"] = { query = "@block.inner", desc = "Select inner block" },

                        -- Parameters
                        ["ap"] = { query = "@parameter.outer", desc = "Select outer parameter" },
                        ["ip"] = { query = "@parameter.inner", desc = "Select inner parameter" },

                        -- Conditionals
                        ["ai"] = { query = "@conditional.outer", desc = "Select outer conditional" },
                        ["ii"] = { query = "@conditional.inner", desc = "Select inner conditional" },

                        -- Loops
                        ["al"] = { query = "@loop.outer", desc = "Select outer loop" },
                        ["il"] = { query = "@loop.inner", desc = "Select inner loop" },
                    },
                },

                move = {
                    enable = true,
                    set_jumps = true, -- record movements in jumplist
                    goto_next_start = {
                        ["]f"] = { query = "@function.outer", desc = "Next function start" },
                        ["]c"] = { query = "@class.outer", desc = "Next class start" },
                    },
                    goto_next_end = {
                        ["]F"] = { query = "@function.outer", desc = "Next function end" },
                        ["]C"] = { query = "@class.outer", desc = "Next class end" },
                    },
                    goto_previous_start = {
                        ["[f"] = { query = "@function.outer", desc = "Previous function start" },
                        ["[c"] = { query = "@class.outer", desc = "Previous class start" },
                    },
                    goto_previous_end = {
                        ["[F"] = { query = "@function.outer", desc = "Previous function end" },
                        ["[C"] = { query = "@class.outer", desc = "Previous class end" },
                    },
                },

                swap = {
                    enable = true,
                    swap_next = {
                        ["<leader>a"] = { query = "@parameter.inner", desc = "Swap with next parameter" },
                    },
                    swap_previous = {
                        ["<leader>A"] = { query = "@parameter.inner", desc = "Swap with previous parameter" },
                    },
                },
            },
        })

        -- Optional: register with which-key for better discoverability
        local wk = require("which-key")
        wk.add({
            mode = { "o", "x" },
            { "af", "Select outer function", icon = "" },
            { "if", "Select inner function", icon = "" },
            { "ac", "Select outer class", icon = "ﴯ" },
            { "ic", "Select inner class", icon = "ﴯ" },
            { "ab", "Select outer block", icon = "󰅩" },
            { "ib", "Select inner block", icon = "󰅩" },
            { "ap", "Select outer parameter", icon = "󰘧" },
            { "ip", "Select inner parameter", icon = "󰘧" },
            { "ai", "Select outer conditional", icon = "" },
            { "ii", "Select inner conditional", icon = "" },
            { "al", "Select outer loop", icon = "" },
            { "il", "Select inner loop", icon = "" },
            { "]f", "Next function", icon = "" },
            { "[f", "Previous function", icon = "" },
            { "]c", "Next class", icon = "" },
            { "[c", "Previous class", icon = "" },
            { "<leader>a", "Swap with next parameter", icon = "" },
            { "<leader>A", "Swap with previous parameter", icon = "" },
        })
    end,
}
