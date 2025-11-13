return {
    "rmagatti/auto-session",
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
        suppressed_dirs = { "~/", "/" },
        -- allowed_dirs = { "~/my_projects/" },
        -- log_level = 'debug',
    },
    config = function()
        vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
        require("auto-session").setup({
            pre_save_cmds = { "Neotree close" },
            post_restore_cmds = { "Neotree filesystem show" },
        })
    end,
}
