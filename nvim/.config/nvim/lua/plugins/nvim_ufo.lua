return {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        -- The lsp capability stuff is done in lsp-config.lua file
        -- Tell the server the capability of foldingRange,
        -- Neovim hasn't added foldingRange to default capabilities, users must add it manually
        -- local capabilities = vim.lsp.protocol.make_client_capabilities()
        -- capabilities.textDocument.foldingRange = {
        --     dynamicRegistration = false,
        --     lineFoldingOnly = true,
        -- }
        -- local language_servers = vim.lsp.get_clients() -- or list servers manually like {'gopls', 'clangd'}
        -- for _, ls in ipairs(language_servers) do
        --     require("lspconfig")[ls].setup({
        --         capabilities = capabilities,
        --         -- you can add other fields for setting up lsp server in this table
        --     })
        -- end

        require("ufo").setup()
        vim.keymap.set("n", "K", function()
            local winid = require("ufo").peekFoldedLinesUnderCursor()
            if not winid then
                vim.lsp.buf.hover()
            end
        end)
    end,
}
