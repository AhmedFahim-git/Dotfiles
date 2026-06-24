return {
    {
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        -- Main LSP Configuration
        "neovim/nvim-lspconfig",
        dependencies = {
            -- Automatically install LSPs and related tools to stdpath for Neovim
            -- Mason must be loaded before its dependents so we need to set it up here.
            -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
            { "mason-org/mason.nvim", opts = {} },
            "mason-org/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",

            -- Useful status updates for LSP.
            { "j-hui/fidget.nvim", opts = {} },

            -- Allows extra capabilities provided by blink.cmp
            "saghen/blink.cmp",
        },
        config = function()
            -- Brief aside: **What is LSP?**
            --
            -- LSP is an initialism you've probably heard, but might not understand what it is.
            --
            -- LSP stands for Language Server Protocol. It's a protocol that helps editors
            -- and language tooling communicate in a standardized fashion.
            --
            -- In general, you have a "server" which is some tool built to understand a particular
            -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
            -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
            -- processes that communicate with some "client" - in this case, Neovim!
            --
            -- LSP provides Neovim with features like:
            --  - Go to definition
            --  - Find references
            --  - Autocompletion
            --  - Symbol Search
            --  - and more!
            --
            -- Thus, Language Servers are external tools that must be installed separately from
            -- Neovim. This is where `mason` and related plugins come into play.
            --
            -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
            -- and elegantly composed help section, `:help lsp-vs-treesitter`

            --  This function gets run when an LSP attaches to a particular buffer.
            --    That is to say, every time a new file is opened that is associated with
            --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
            --    function will be executed to configure the current buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                callback = function(event)
                    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
                    -- to define small helper and utility functions so you don't have to repeat yourself.
                    --
                    -- In this case, we create a function that lets us more easily define mappings specific
                    -- for LSP related items. It sets the mode, buffer and description for us each time.
                    local map = function(keys, func, desc, mode)
                        mode = mode or "n"
                        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end

                    -- Rename the variable under your cursor.
                    --  Most Language Servers support renaming across files, etc.
                    map("grn", vim.lsp.buf.rename, "[R]e[n]ame")

                    -- Execute a code action, usually your cursor needs to be on top of an error
                    -- or a suggestion from your LSP for this to activate.
                    map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })

                    -- Find references for the word under your cursor.
                    map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

                    -- Jump to the implementation of the word under your cursor.
                    --  Useful when your language has ways of declaring types without an actual implementation.
                    map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

                    -- Jump to the definition of the word under your cursor.
                    --  This is where a variable was first declared, or where a function is defined, etc.
                    --  To jump back, press <C-t>.
                    map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

                    -- WARN: This is not Goto Definition, this is Goto Declaration.
                    --  For example, in C this would take you to the header.
                    map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                    -- Fuzzy find all the symbols in your current document.
                    --  Symbols are things like variables, functions, types, etc.
                    map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")

                    -- Fuzzy find all the symbols in your current workspace.
                    --  Similar to document symbols, except searches over your entire project.
                    map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")

                    -- Jump to the type of the word under your cursor.
                    --  Useful when you're not sure what type a variable is and you want to see
                    --  the definition of its *type*, not where it was *defined*.
                    map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

                    -- The following two autocommands are used to highlight references of the
                    -- word under your cursor when your cursor rests there for a little while.
                    --    See `:help CursorHold` for information about when this is executed
                    --
                    -- When you move your cursor, the highlights will be cleared (the second autocommand).
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client:supports_method("textDocument/documentHighlight", event.buf) then
                        local highlight_augroup =
                            vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_create_autocmd("LspDetach", {
                            group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                            callback = function(event2)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
                            end,
                        })
                    end

                    -- The following code creates a keymap to toggle inlay hints in your
                    -- code, if the language server you are using supports them
                    --
                    -- This may be unwanted, since they displace some of your code
                    if client and client:supports_method("textDocument/inlayHint", event.buf) then
                        map("<leader>th", function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
                        end, "[T]oggle Inlay [H]ints")
                    end
                end,
            })

            -- LSP servers and clients are able to communicate to each other what features they support.
            --  By default, Neovim doesn't support everything that is in the LSP specification.
            --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
            --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- Folding capability for Nvim-ufo
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
            }

            local vue_language_server_path = vim.fn.stdpath("data")
                .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
            local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }
            local vue_plugin = {
                name = "@vue/typescript-plugin",
                location = vue_language_server_path,
                languages = { "vue" },
                configNamespace = "typescript",
            }
            local html_capabilities = { textDocument = { completion = { completionItem = { snippetSupport = true } } } }
            -- vim.lsp.protocol.make_client_capabilities()
            -- html_capabilities.textDocument.completion.completionItem.snippetSupport = true

            -- Enable the following language servers
            --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
            --
            --  Add any additional override configuration in the following tables. Available keys are:
            --  - cmd (table): Override the default command used to start the server
            --  - filetypes (table): Override the default list of associated filetypes for the server
            --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
            --  - settings (table): Override the default settings passed when initializing the server.
            --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
            local servers = {
                -- clangd = {},
                -- gopls = {},
                ty = {},
                -- basedpyright = {
                --     settings = {
                --         basedpyright = {
                --             disableOrganizeImports = true,
                --             analysis = {
                --                 typeCheckingMode = "basic", -- options are "off", "basic", "standard", "strict", "recommended", "all"
                --                 useLibraryCodeForTypes = true,
                --             },
                --         },
                --     },
                -- },
                -- pyright = {
                --     settings = {
                --         pyright = {
                --             disableOrganizeImports = true,
                --         },
                --     },
                --     python = {
                --         analysis = {
                --             autoSearchPaths = true,
                --             useLibraryCodeForTypes = true,
                --             typeCheckingMode = "basic", -- or "strict" if you want
                --         },
                --     },
                -- },
                ruff = {},
                -- rust_analyzer = {},
                -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
                --
                -- Some languages (like typescript) have entire language plugins that can be useful:
                --    https://github.com/pmizio/typescript-tools.nvim
                --
                -- But for many setups, the LSP (`ts_ls`) will work just fine
                -- ts_ls = {},
                --

                -- lua_ls = {
                --     -- cmd = { ... },
                --     -- filetypes = { ... },
                --     -- capabilities = {},
                --     settings = {
                --         Lua = {
                --             completion = {
                --                 callSnippet = "Replace",
                --             },
                --             -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                --             -- diagnostics = { disable = { 'missing-fields' } },
                --         },
                --     },
                -- },
                vtsls = {
                    settings = {
                        vtsls = {
                            autoUseWorkspaceTsdk = true,
                            tsserver = {
                                globalPlugins = {
                                    vue_plugin,
                                },
                            },
                        },
                    },
                    filetypes = tsserver_filetypes,
                },
                vue_ls = {},
                biome = {},
                emmet_language_server = {},
                clangd = {},
                taplo = {},
                gopls = {},
            }

            -- Ensure the servers and tools above are installed
            --
            -- To check the current status of installed tools and/or manually install
            -- other tools, you can run
            --    :Mason
            --
            -- You can press `g?` for help in this menu.
            --
            -- `mason` had to be setup earlier: to configure its options see the
            -- `dependencies` table for `nvim-lspconfig` above.
            --
            -- You can add other tools here that you want Mason to install
            -- for you, so that they are available from within Neovim.
            local ensure_installed = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed, {
                "stylua", -- Used to format Lua code
                "prettier",
                "debugpy",
                "lua_ls",
                "html-lsp",
                "css-lsp",
                "clang-format",
                "cmakelang",
                "markdownlint",
                "yamllint",
                "yaml-language-server",
                "bash-language-server",
                "shellcheck",
                "shfmt",
                "docker-language-server",
                "golangci-lint",
                "goimports",
                "gofumpt",
                "rust-analyzer",
            })
            require("mason-tool-installer").setup({ ensure_installed = ensure_installed, auto_update = true })

            local extra_servers = {
                html = { capabilities = html_capabilities },
                cssls = { capabilities = html_capabilities },
                yamlls = {},
                bashls = {},
                docker_language_server = {},
                rust_analyzer = {
                    settings = {
                        ["rust-analyzer"] = {
                            cargo = {
                                allFeatures = true,
                            },
                            checkOnSave = true,
                            check = {
                                command = "clippy",
                            },
                            procMacro = {
                                enable = true,
                            },
                        },
                    },
                },
            }
            servers = vim.tbl_deep_extend("error", {}, servers, extra_servers)

            for name, server in pairs(servers) do
                server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                vim.lsp.config(name, server)
                vim.lsp.enable(name)
            end

            -- Special Lua Config, as recommended by neovim help docs
            vim.lsp.config("lua_ls", {
                on_init = function(client)
                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name
                        if
                            path ~= vim.fn.stdpath("config")
                            and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
                        then
                            return
                        end
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                        runtime = {
                            version = "LuaJIT",
                            path = { "lua/?.lua", "lua/?/init.lua" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
                            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
                            library = vim.api.nvim_get_runtime_file("", true),
                        },
                    })
                end,
                settings = {
                    Lua = {},
                },
            })
            vim.lsp.enable("lua_ls")

            -- require("mason-lspconfig").setup({
            --     ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
            --     automatic_installation = false,
            --     handlers = {
            --         function(server_name)
            --             local server = servers[server_name] or {}
            --             -- This handles overriding only values explicitly passed
            --             -- by the server configuration above. Useful when disabling
            --             -- certain features of an LSP (for example, turning off formatting for ts_ls)
            --             server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            --             -- require("lspconfig")[server_name].setup(server)
            --             vim.lsp.config(server_name, server)
            --             vim.lsp.enable(server_name)
            --         end,
            --     },
            -- })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client == nil then
                        return
                    end
                    if client.name == "ruff" then
                        -- Disable hover in favor of Pyright
                        client.server_capabilities.hoverProvider = false
                    end
                end,
                desc = "LSP: Disable hover capability from Ruff",
            })
        end,
    },
    { -- Linting (those that do not have lsp as well)
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")

            -- Associate linters with filetypes
            lint.linters_by_ft = {
                cpp = { "clang-tidy", "cppcheck" },
                c = { "clang-tidy", "cppcheck" },
                cmake = { "cmake-lint" },
                markdown = { "markdownlint" },
                yaml = { "yamllint" },
                sh = { "shellcheck" },
                bash = { "shellcheck" },
                go = { "golangcilint" },
            }
            -- Auto-run linting
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },

    { -- Autoformat
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                mode = "",
                desc = "[F]ormat buffer",
            },
        },
        opts = {
            notify_on_error = false,
            format_on_save = function(bufnr)
                -- Disable "format_on_save lsp_fallback" for languages that don't
                -- have a well standardized coding style. You can add additional
                -- languages here or re-enable it for the disabled ones.
                local disable_filetypes = {}
                if disable_filetypes[vim.bo[bufnr].filetype] then
                    return nil
                else
                    return {
                        timeout_ms = 500,
                        lsp_format = "fallback",
                    }
                end
            end,
            formatters_by_ft = {
                lua = { "stylua" },
                -- Conform can also run multiple formatters sequentially
                python = {
                    -- To fix auto-fixable lint errors.
                    "ruff_fix",
                    -- To run the Ruff formatter.
                    "ruff_format",
                    -- To organize the imports.
                    "ruff_organize_imports",
                },
                --
                -- You can use 'stop_after_first' to run the first available formatter from the list
                -- javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
                c = { "clang-format" },
                cpp = { "clang-format" },
                cmake = { "cmake_format" },
                javascript = { "biome-check" },
                javascriptreact = { "biome-check" },
                typescript = { "biome-check" },
                typescriptreact = { "biome-check" },
                json = { "biome-check" },
                jsonc = { "biome-check" },
                css = { "biome-check" },
                html = { "prettier" },
                markdown = { "prettier" },
                yaml = { "prettier" },
                sh = { "shfmt" },
                bash = { "shfmt" },
                go = { "goimports", "gofumpt" },
                rust = { "rustfmt" },
            },
            -- Overriding default values of formatters (customizing formatters)
            formatters = {
                stylua = {
                    prepend_args = { "--indent-type=Spaces" },
                },
            },
        },
    },

    { -- Autocompletion
        "saghen/blink.cmp",
        event = "VimEnter",
        version = "1.*",
        dependencies = {
            -- Snippet Engine
            {
                "L3MON4D3/LuaSnip",
                version = "2.*",
                build = (function()
                    -- Build Step is needed for regex support in snippets.
                    -- This step is not supported in many windows environments.
                    -- Remove the below condition to re-enable on windows.
                    if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
                        return
                    end
                    return "make install_jsregexp"
                end)(),
                dependencies = {
                    -- `friendly-snippets` contains a variety of premade snippets.
                    --    See the README about individual language/framework/plugin snippets:
                    --    https://github.com/rafamadriz/friendly-snippets
                    {
                        "rafamadriz/friendly-snippets",
                        config = function()
                            require("luasnip.loaders.from_vscode").lazy_load()
                        end,
                    },
                },
                opts = {},
            },
            "folke/lazydev.nvim",
            "saghen/blink.lib",
        },
        --- @module 'blink.cmp'
        --- @type blink.cmp.Config
        opts = {
            keymap = {
                -- 'default' (recommended) for mappings similar to built-in completions
                --   <c-y> to accept ([y]es) the completion.
                --    This will auto-import if your LSP supports it.
                --    This will expand snippets if the LSP sent a snippet.
                -- 'super-tab' for tab to accept
                -- 'enter' for enter to accept
                -- 'none' for no mappings
                --
                -- For an understanding of why the 'default' preset is recommended,
                -- you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                --
                -- All presets have the following mappings:
                -- <tab>/<s-tab>: move to right/left of your snippet expansion
                -- <c-space>: Open menu or open docs if already open
                -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
                -- <c-e>: Hide menu
                -- <c-k>: Toggle signature help
                --
                -- See :h blink-cmp-config-keymap for defining your own keymap
                preset = "default",

                -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
            },

            appearance = {
                -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned
                nerd_font_variant = "mono",
            },

            completion = {
                -- By default, you may press `<c-space>` to show the documentation.
                -- Optionally, set `auto_show = true` to show the documentation after a delay.
                documentation = { auto_show = false, auto_show_delay_ms = 500 },
            },

            sources = {
                default = { "lsp", "path", "snippets", "lazydev" },
                providers = {
                    lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
                },
            },

            snippets = { preset = "luasnip" },

            -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
            -- which automatically downloads a prebuilt binary when enabled.
            --
            -- By default, we use the Lua implementation instead, but you may enable
            -- the rust implementation via `'prefer_rust_with_warning'`
            --
            -- See :h blink-cmp-config-fuzzy for more information
            fuzzy = { implementation = "prefer_rust_with_warning" },

            -- Shows a signature help window while you type arguments for a function
            signature = { enabled = true },
        },
    },
    { -- DAP (debugging)
        "mfussenegger/nvim-dap",
        dependencies = {
            "mfussenegger/nvim-dap-python",
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-neotest/nvim-nio",
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            dapui.setup()
            require("dap-python").setup("uv")

            require("nvim-dap-virtual-text").setup({
                -- This just tries to mitigate the chance that I leak tokens here. Probably won't stop it from happening...
                display_callback = function(variable)
                    if #variable.value > 15 then
                        return " " .. string.sub(variable.value, 1, 15) .. "... "
                    end

                    return " " .. variable.value
                end,
            })

            -- Basic debugging keymaps, feel free to change to your liking!
            vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Start/Continue" })
            vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug: Step Into" })
            vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Debug: Step Over" })
            vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Debug: Step Out" })
            vim.keymap.set("n", "<leader>dk", dap.step_back, { desc = "Debug: Step Back" })
            vim.keymap.set("n", "<leader>dR", dap.restart, { desc = "Debug: Restart" })

            -- Breakpoints
            vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
            vim.keymap.set("n", "<leader>dB", function()
                dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, { desc = "Debug: Set Breakpoint" })

            -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
            vim.keymap.set("n", "<leader>du", function()
                dapui.toggle()
            end, { desc = "Debug: See last session result." })

            -- Eval var under cursor
            vim.keymap.set("n", "<leader>de", function()
                require("dapui").eval(nil, { enter = true })
            end, { desc = "Debug: Eval" })

            -- Change breakpoint icons
            vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
            vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00" })
            local breakpoint_icons = vim.g.have_nerd_font
                    and {
                        Breakpoint = "",
                        BreakpointCondition = "",
                        BreakpointRejected = "",
                        LogPoint = "",
                        Stopped = "",
                    }
                or {
                    Breakpoint = "●",
                    BreakpointCondition = "⊜",
                    BreakpointRejected = "⊘",
                    LogPoint = "◆",
                    Stopped = "⭔",
                }
            for type, icon in pairs(breakpoint_icons) do
                local tp = "Dap" .. type
                local hl = (type == "Stopped") and "DapStop" or "DapBreak"
                vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
            end

            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end
        end,
    },
}
