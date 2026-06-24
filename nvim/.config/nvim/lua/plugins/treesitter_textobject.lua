-- From ChatGPT
-- File: lua/plugins/treesitter-textobjects.lua
return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },

    init = function()
        -- Disable entire built-in ftplugin mappings to avoid conflicts.
        -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
        vim.g.no_plugin_maps = true

        -- Or, disable per filetype (add as you like)
        -- vim.g.no_python_maps = true
        -- vim.g.no_ruby_maps = true
        -- vim.g.no_rust_maps = true
        -- vim.g.no_go_maps = true
    end,
    config = function()
        require("nvim-treesitter-textobjects").setup({
            select = {
                -- Automatically jump forward to the textobject, like targets.vim.
                lookahead = true,

                selection_modes = {
                    -- Parameters/arguments should stay charwise.
                    -- This is exactly what the plugin docs show.
                    ["@parameter.outer"] = "v",
                    ["@parameter.inner"] = "v",

                    -- Python defs/classes/blocks feel better linewise.
                    ["@function.outer"] = "V",
                    ["@function.inner"] = "V",
                    ["@class.outer"] = "V",
                    ["@class.inner"] = "V",
                    ["@loop.outer"] = "V",
                    ["@loop.inner"] = "V",
                    ["@conditional.outer"] = "V",
                    ["@conditional.inner"] = "V",
                    ["@block.outer"] = "V",
                    ["@block.inner"] = "V",
                },

                include_surrounding_whitespace = function(opts)
                    -- Do not add extra whitespace around args/params.
                    -- Python's @parameter.outer query already includes commas where useful.
                    if opts.query_string == "@parameter.outer" then
                        return false
                    end

                    return opts.query_string:match("%.outer$") ~= nil
                end,
            },
            move = {
                set_jumps = true,
            },
        })

        local select = require("nvim-treesitter-textobjects.select")
        local move = require("nvim-treesitter-textobjects.move")
        local swap = require("nvim-treesitter-textobjects.swap")
        local repeatable_move = require("nvim-treesitter-textobjects.repeatable_move")

        local function map(mode, lhs, rhs, desc, opts)
            opts = vim.tbl_extend("force", {
                desc = desc,
                silent = true,
            }, opts or {})

            vim.keymap.set(mode, lhs, rhs, opts)
        end

        local function textobject(lhs, query, desc)
            map({ "x", "o" }, lhs, function()
                select.select_textobject(query, "textobjects")
            end, desc)
        end

        -- Selection textobjects.
        -- Examples:
        --   daf  delete around function
        --   vif  visually select inner function
        --   cia  change inner argument
        --   ya=  yank around assignment
        textobject("af", "@function.outer", "Around function")
        textobject("if", "@function.inner", "Inside function")

        textobject("ac", "@class.outer", "Around class")
        textobject("ic", "@class.inner", "Inside class")

        textobject("aa", "@parameter.outer", "Around argument/parameter")
        textobject("ia", "@parameter.inner", "Inside argument/parameter")

        textobject("aC", "@call.outer", "Around function call")
        textobject("iC", "@call.inner", "Inside function call")

        textobject("al", "@loop.outer", "Around loop")
        textobject("il", "@loop.inner", "Inside loop")

        textobject("ai", "@conditional.outer", "Around conditional")
        textobject("ii", "@conditional.inner", "Inside conditional")

        textobject("ab", "@block.outer", "Around block")
        textobject("ib", "@block.inner", "Inside block")

        textobject("ar", "@return.outer", "Around return")
        textobject("ir", "@return.inner", "Inside return")

        textobject("a=", "@assignment.outer", "Around assignment")
        textobject("i=", "@assignment.inner", "Inside assignment value")
        textobject("l=", "@assignment.lhs", "LHS assignment")
        textobject("r=", "@assignment.rhs", "RHS assignment")

        textobject("a#", "@comment.outer", "Around comment")
        textobject("i#", "@comment.inner", "Inside comment")

        -- Movement.
        map({ "n", "x", "o" }, "]f", function()
            move.goto_next_start("@function.outer", "textobjects")
        end, "Next function start")

        map({ "n", "x", "o" }, "[f", function()
            move.goto_previous_start("@function.outer", "textobjects")
        end, "Previous function start")

        map({ "n", "x", "o" }, "]F", function()
            move.goto_next_end("@function.outer", "textobjects")
        end, "Next function end")

        map({ "n", "x", "o" }, "[F", function()
            move.goto_previous_end("@function.outer", "textobjects")
        end, "Previous function end")

        map({ "n", "x", "o" }, "]]", function()
            move.goto_next_start("@class.outer", "textobjects")
        end, "Next class start")

        map({ "n", "x", "o" }, "[[", function()
            move.goto_previous_start("@class.outer", "textobjects")
        end, "Previous class start")

        map({ "n", "x", "o" }, "]a", function()
            move.goto_next_start("@parameter.inner", "textobjects")
        end, "Next argument/parameter")

        map({ "n", "x", "o" }, "[a", function()
            move.goto_previous_start("@parameter.inner", "textobjects")
        end, "Previous argument/parameter")

        map({ "n", "x", "o" }, "]l", function()
            move.goto_next_start("@loop.outer", "textobjects")
        end, "Next loop")

        map({ "n", "x", "o" }, "[l", function()
            move.goto_previous_start("@loop.outer", "textobjects")
        end, "Previous loop")

        map({ "n", "x", "o" }, "]r", function()
            move.goto_next_start("@return.outer", "textobjects")
        end, "Next return")

        map({ "n", "x", "o" }, "[r", function()
            move.goto_previous_start("@return.outer", "textobjects")
        end, "Previous return")

        -- Swap arguments/parameters.
        -- Very useful in Python calls, function definitions, lists, tuples, dicts, imports, etc.
        map("n", "<leader>a", function()
            swap.swap_next("@parameter.inner")
        end, "Swap argument/parameter with next")

        map("n", "<leader>A", function()
            swap.swap_previous("@parameter.outer")
        end, "Swap argument/parameter with previous")

        -- Make textobject movements repeatable with ; and ,
        map({ "n", "x", "o" }, ";", repeatable_move.repeat_last_move_next, "Repeat movement forward")
        map({ "n", "x", "o" }, ",", repeatable_move.repeat_last_move_previous, "Repeat movement backward")

        -- Preserve normal f/F/t/T behavior while making them work with the repeat system.
        map({ "n", "x", "o" }, "f", repeatable_move.builtin_f_expr, "f", { expr = true })
        map({ "n", "x", "o" }, "F", repeatable_move.builtin_F_expr, "F", { expr = true })
        map({ "n", "x", "o" }, "t", repeatable_move.builtin_t_expr, "t", { expr = true })
        map({ "n", "x", "o" }, "T", repeatable_move.builtin_T_expr, "T", { expr = true })
    end,
}
