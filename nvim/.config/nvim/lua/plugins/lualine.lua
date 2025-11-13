local tmux_char = {
    function()
        -- check if current pane is zoomed
        local result = io.popen("tmux list-panes -F '#F' | grep Z")

        if result ~= nil and result:read("*a") ~= "" then
            result:close()
            return "  " --current pane is zoomed
        else
            return " " -- not zoomed
        end
    end,
    padding = { left = 1, right = 1 }, -- We don't need space before this
    cond = function()
        return os.getenv("TMUX") ~= nil
    end,
    on_click = function()
        os.execute("tmux resize-pane -Z")
    end,
}

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("lualine").setup({
            options = {
                theme = "catppuccin",
                -- section_separators = { left = "", right = "" },
                -- component_separators = { left = "", right = "" },
            },
            sections = {
                lualine_x = { tmux_char, "encoding", "fileformat", "filetype" },
            },
        })
    end,
}
