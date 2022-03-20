local status = require "core.status"

local config = {

  -- Set colorscheme
  colorscheme = "default_theme",

  default_theme = {
    diagnostics_style = "italic",
    -- Modify the highlight groups
    highlights = function(highlights)
      -- Add InlayHints
      local inlay_hint = highlights["Comment"]
      inlay_hint["style"] = "italic"
      highlights["InlayHints"] = inlay_hint

      return highlights
    end,
  },

  -- Add plugins
  plugins = {
    -- Change Packer config itself:
    packer = {
      compile_path = vim.fn.stdpath "cache" .. "/lua/packer_compiled.lua",
    },
    -- Change plugins to install:
    init = function(plugins)
      local result = {
        -- Extended file type support
        { "sheerun/vim-polyglot" },

        -- Cursor Jump Highlight
        {
          "DanilaMihailov/beacon.nvim",
          config = function()
            vim.g.beacon_size = 160
            vim.g.beacon_minimal_jump = 5

            local opts = { noremap = true, silent = true }
            local map = vim.api.nvim_set_keymap

            map("n", "n", "n:Beacon<cr>", opts)
            map("n", "N", "N:Beacon<cr>", opts)
            map("n", "*", "*:Beacon<cr>", opts)
            map("n", "#", "#:Beacon<cr>", opts)
          end,
        },

        -- LSP
        {
          "ray-x/lsp_signature.nvim",
          config = function()
            require("lsp_signature").setup()
          end,
        },

        -- Properly paste code into vim:
        { "ConradIrwin/vim-bracketed-paste" },

        -- My slint plugin
        { "slint-ui/vim-slint" },

        -- DAP:
        { "mfussenegger/nvim-dap" },
        {
          "rcarriga/nvim-dap-ui",
          requires = { "nvim-dap", "rust-tools.nvim" },
          config = function()
            require("dapui").setup {}
          end,
        },
        {
          "Pocco81/DAPInstall.nvim",
          config = function()
            require("dap-install").setup {}
          end,
        },

        -- Rust support
        {
          -- "simrat39/rust-tools.nvim",
          "hunger/rust-tools.nvim", -- fix inlay hints
          requires = { "nvim-lspconfig", "nvim-lsp-installer", "nvim-dap", "Comment.nvim" },
          -- Is configured via the server_registration_override installed below!
        },
        {
          "Saecki/crates.nvim",
          after = "nvim-cmp",
          config = function()
            require("crates").setup()

            local cmp = require "cmp"
            local config = cmp.get_config()
            table.insert(config.sources, { name = "crates" })
            cmp.setup(config)
          end,
        },

        -- github telescope extension:
        {
          "nvim-telescope/telescope-github.nvim",
          after = "telescope.nvim",
          config = function()
            require("telescope").load_extension "gh"
          end,
        },
        {
          "nvim-telescope/telescope-file-browser.nvim",
          after = "telescope.nvim",
          config = function()
            require("telescope").load_extension "file_browser"
          end,
        },
        {
          "nvim-telescope/telescope-ui-select.nvim",
          after = "telescope.nvim",
          config = function()
            require("telescope").load_extension "ui-select"
          end,
        },

        -- Tools
        { "tpope/vim-repeat" },
        { "tpope/vim-surround" },
        { "tpope/vim-fugitive" },

        {
          "ggandor/lightspeed.nvim",
          config = function()
            require("lightspeed").setup {}
          end,
        },

        -- Text objects
        { "bkad/CamelCaseMotion" },
        {
          "nvim-treesitter/nvim-treesitter-textobjects",
          after = "nvim-treesitter",
          config = function()
            require("nvim-treesitter.configs").setup {
              textobjects = {
                select = {
                  enable = true,

                  -- Automatically jump forward to textobj, similar to targets.vim
                  lookahead = true,

                  keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                    ["ab"] = "@block.outer",
                    ["ib"] = "@block.inner",
                    ["a-"] = "@parameter.outer",
                    ["i-"] = "@parameter.inner",

                    -- Or you can define your own textobjects like this
                    -- ["iF"] = {
                    --    python = "(function_definition) @function",
                    --    cpp = "(function_definition) @function",
                    --    c = "(function_definition) @function",
                    --    java = "(method_declaration) @function",
                    -- },
                  },
                },
              },
            }
          end,
        },
      }

      plugins["nvim-telescope/telescope-fzf-native.nvim"] = nil

      -- disable delayed loading of all default plugins:
      for _, plugin in pairs(plugins) do
        -- disable lazy loading
        plugin["cmd"] = nil
        plugin["event"] = nil
        -- disable special stuff done on startup (like build TS plugins!)
        plugin["run"] = nil

        table.insert(result, plugin)
      end

      return result
    end,
    -- Now configure some of the default plugins:
    lualine = {
      sections = {
        lualine_a = {
          { "filename", file_status = true, path = 1, full_path = true, shorten = false },
          -- { "mode", padding = { left = 1, right = 1 } },
        },
        lualine_b = {
          "filetype",
          { "branch", icon = "" },
        },
        lualine_c = {
          { "diff", symbols = { added = " ", modified = "柳", removed = " " } },
          { "diagnostics", sources = { "nvim_diagnostic" } },
        },
        lualine_x = {
          status.lsp_progress,
        },
        lualine_y = {
          { status.lsp_name, icon = " " },
          status.treesitter_status,
        },
        lualine_z = {
          { "progress" },
          { "location" },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    },
    luasnip = {
      vscode_snippets_paths = { "/home/extra/.config/nvim-data/snippets" },
    },
    treesitter = {
      ensure_installed = {},
    },
  },

  lsp = {
    server_registration = function(server, server_opts)
      -- Special code for rust.tools.nvim!
      if server.name == "rust_analyzer" then
        local extension_path = vim.fn.stdpath "data" .. "/dapinstall/codelldb/extension/"
        local codelldb_path = extension_path .. "adapter/codelldb"
        local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

        require("rust-tools").setup {
          server = server_opts,
          dap = {
            adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
          },
          tools = {
            inlay_hints = {
              highlight = "InlayHints",
              parameter_hints_prefix = " ",
              other_hints_prefix = " ",
            },
          },
        }
      else
        server:setup(server_opts)
      end
    end,
  },

  -- Disable default plugins
  enabled = {
    bufferline = false,
    nvim_tree = false,
    lualine = true,
    lspsaga = true,
    gitsigns = true,
    colorizer = true,
    toggle_term = false,
    comment = true,
    symbols_outline = true,
    indent_blankline = true,
    dashboard = false,
    which_key = false,
    neoscroll = false,
    ts_rainbow = true,
    ts_autotag = true,
  },

  polish = function()
    local opts = { noremap = true, silent = true }
    local map = vim.api.nvim_set_keymap
    local unmap = vim.api.nvim_del_keymap

    vim.opt.colorcolumn = "80,100,9999"
    vim.opt.scrolloff = 15
    vim.opt.sidescrolloff = 15

    vim.opt.numberwidth = 4

    vim.opt.undofile = false

    vim.opt.timeoutlen = 1000 -- I am slow at typing:-/
    vim.opt.clipboard = "" -- the default is *SLOW* on my system

    -- Undo some AstroVim mappings:
    unmap("n", "<C-w>")
    unmap("n", "<C-q>")
    unmap("n", "<leader>gd")

    map("n", "fm", ":lua vim.lsp.buf.formatting()<cr>", opts)
    map("n", "<leader>D", ":Telescope lsp_type_definitions<cr>", opts)

    -- Telescope mappings:
    map("n", "<leader>faf", ":Telescope find_files hidden=true no_ignore=true<cr>", opts)

    map("n", "<leader>fS", ":Telescope lsp_workspace_symbols<cr>", opts)
    map("n", "<leader>fs", ":Telescope lsp_document_symbols<cr>", opts)
    -- map("n", "<leader>fq", ":Telescope quickfix<cr>", opts)
    map("n", "<leader>fr", ":Telescope lsp_references<cr>", opts)
    map("n", "<leader>fs", ":Telescope lsp_document_symbols<cr>", opts)
    map("n", "<leader>fS", ":Telescope lsp_workspace_symbols<cr>", opts)

    map("n", "<leader>fgi", ":Telescope gh issues<cr>", opts)
    map("n", "<leader>fgp", ":Telescope gh pull_request<cr>", opts)
    map("n", "<leader>fgg", ":Telescope gh gist<cr>", opts)

    map("n", "<leader>fB", ":Telescope file_browser<cr>", opts)

    -- Crates mappings:
    map("n", "<leader>Ct", ":lua require('crates').toggle()<cr>", opts)
    map("n", "<leader>Cr", ":lua require('crates').reload()<cr>", opts)
    map("n", "<leader>CU", ":lua require('crates').upgrade_crate()<cr>", opts)
    map("v", "<leader>CU", ":lua require('crates').upgrade_crates()<cr>", opts)
    map("n", "<leader>CA", ":lua require('crates').upgrade_all_crates()<cr>", opts)

    -- DAP mappings:
    map("n", "<F5>", ":lua require('dap').continue()<cr>", opts)
    map("n", "<F10>", ":lua require('dap').step_over()<cr>", opts)
    map("n", "<F11>", ":lua require('dap').step_into()<cr>", opts)
    map("n", "<F12>", ":lua require('dap').step_out()<cr>", opts)
    map("n", "<leader>bp", ":lua require('dap').toggle_breakpoint()<cr>", opts)
    map("n", "<leader>Bp", ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", opts)
    map("n", "<leader>lp", ":lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Logpoint message: '))<cr>", opts)
    map("n", "<leader>repl", ":lua require('dap').repl.open()<cr>", opts)
    map("n", "<leader>rrrr", ":lua require('dap').run_last()<cr>", opts)
    map("n", "<leader>xxxx", ":lua require('dap').terminate()<cr>", opts)

    -- Allow gf to work for non-existing files
    map("n", "gf", ":edit <cfile><cr>", opts)
    map("v", "gf", ":edit <cfile><cr>", opts)
    map("o", "gf", ":edit <cfile><cr>", opts)

    map("n", "<f8>", ":cprev<cr>", opts)
    map("n", "<f9>", ":cnext<cr>", opts)
  end,
}

return config
