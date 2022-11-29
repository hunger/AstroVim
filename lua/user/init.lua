local config = {
  options = {
    opt = {
      clipboard = "", -- the default is *SLOW* on my system
      -- cmdheight = 1, -- the default of 0 still triggers bugs
      colorcolumn = "80,100",
      numberwidth = 4,
      scrolloff = 15,
      showtabline = 0,
      sidescrolloff = 15,
      spell = true,
      spelllang = { "en_us" },
      timeoutlen = 1000, -- I am slow at typing:-/
      undofile = false,
    },
    g = {
      autoformat_enabled = false,
      markdown_fenced_languages = { "ts=typescript" },
    },
  },

  lsp = {
    -- will be set up by rust-tools & the typescript plugin
    skip_setup = { "rust_analyzer", "tsserver" },
  },

  luasnip = {
    vscode_snippet_paths = { "/home/extra/.config/nvim-data/snippets" },
  },

  -- Add plugins
  plugins = {
    -- Now configure some of the default plugins:
    ["cmp"] = function(config)
      local cmp_ok, cmp = pcall(require, "cmp")
      local luasnip_ok, luasnip = pcall(require, "luasnip")

      if cmp_ok and luasnip_ok then
        config.mapping["<CR>"] = cmp.mapping.confirm()
        config.mapping["<Tab>"] = cmp.mapping(function(fallback)
          if luasnip.expandable() then
            luasnip.expand()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, {
          "i",
          "s",
        })
        config.mapping["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, {
          "i",
          "s",
        })
      end
      return config
    end,
    ["heirline"] = function()
      return {
        -- Status line:
        {
          hl = { fg = "fg", bg = "bg" },
          astronvim.status.component.mode(),
          astronvim.status.component.git_branch(),
          astronvim.status.component.fill(),
          astronvim.status.component.lsp(),
          astronvim.status.component.treesitter(),
          astronvim.status.component.nav { scrollbar = false, percentage = false, padding = { left = 1 } },
          astronvim.status.component.mode { surround = { separator = "right" } },
        },
        -- Winbar:
        {
          hl = { fg = "fg", bg = "bg" },
          astronvim.status.component.file_info {
            filename = { modify = ":p:." },
            padding = { left = 1, right = 1 },
          },
          { provider = "::" },
          astronvim.status.component.breadcrumbs { icon = { hl = true }, padding = { left = 1 } },
          astronvim.status.component.fill(),
          astronvim.status.component.git_diff(),
          astronvim.status.component.diagnostics(),
        },
      }
    end,
    ["init"] = {
      -- Extended file type support
      { "sheerun/vim-polyglot" },

      -- DAP:
      { "mfussenegger/nvim-dap" },
      {
        "rcarriga/nvim-dap-ui",
        requires = { "nvim-dap", "rust-tools.nvim" },
        config = function()
          local dapui = require "dapui"
          dapui.setup {}

          local dap = require "dap"
          dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
          dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
          dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

          -- DAP mappings:
          local map = vim.api.nvim_set_keymap
          map("n", "<f5>", ":lua require('dap').continue()<cr>", { desc = "Continue" })
          map("n", "<f10>", ":lua require('dap').step_over()<cr>", { desc = "Step over" })
          map("n", "<f11>", ":lua require('dap').step_into()<cr>", { desc = "Step into" })
          map("n", "<f12>", ":lua require('dap').step_out()<cr>", { desc = "Step out" })
          map("n", "<leader>bp", ":lua require('dap').toggle_breakpoint()<cr>", { desc = "Toggle breakpoint" })
          map(
            "n",
            "<leader>Bp",
            ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>",
            { desc = "Set conditional breakpoint" }
          )
          map(
            "n",
            "<leader>lp",
            ":lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Logpoint message: '))<cr>",
            { desc = "Set logpoint" }
          )
          map("n", "<leader>rp", ":lua require('dap').repl.open()<cr>", { desc = "Open REPL" })
          map("n", "<leader>RR", ":lua require('dap').run_last()<cr>", { desc = "Run last debugged program" })
          map("n", "<leader>XX", ":lua require('dap').terminate()<cr>", { desc = "Terminate program being debugged" })
          map("n", "<leader>du", ":lua require('dap').up()<cr>", { desc = "Up one frame" })
          map("n", "<leader>dd", ":lua require('dap').down()<cr>", { desc = "Down one frame" })
        end,
      },
      {
        "mfussenegger/nvim-dap-python",
      },
      -- Rust support
      {
        "simrat39/rust-tools.nvim",
        after = { "mason-lspconfig.nvim" },
        -- Is configured via the server_registration_override installed below!
        config = function()
          require("rust-tools").setup {
            server = astronvim.lsp.server_settings "rust_analyzer",
            tools = {
              inlay_hints = {
                parameter_hints_prefix = "  ",
                other_hints_prefix = "  ",
              },
            },
          }
        end,
      },
      {
        "Saecki/crates.nvim",
        after = "nvim-cmp",
        config = function()
          require("crates").setup()
          astronvim.add_cmp_source { name = "crates", priority = 1100 }

          -- Crates mappings:
          local map = vim.api.nvim_set_keymap
          map("n", "<leader>Ct", ":lua require('crates').toggle()<cr>", { desc = "Toggle extra crates.io information" })
          map("n", "<leader>Cr", ":lua require('crates').reload()<cr>", { desc = "Reload information from crates.io" })
          map("n", "<leader>CU", ":lua require('crates').upgrade_crate()<cr>", { desc = "Upgrade a crate" })
          map("v", "<leader>CU", ":lua require('crates').upgrade_crates()<cr>", { desc = "Upgrade selected crates" })
          map("n", "<leader>CA", ":lua require('crates').upgrade_all_crates()<cr>", { desc = "Upgrade all crates" })
        end,
      },

      -- typescript:
      {
        "jose-elias-alvarez/typescript.nvim",
        after = "mason-lspconfig.nvim",
        config = function() require("typescript").setup { server = astronvim.lsp.server_settings "tsserver" } end,
      },

      {
        "hrsh7th/cmp-calc",
        after = "nvim-cmp",
        config = function() astronvim.add_cmp_source { name = "calc", priority = 100 } end,
      },
      {
        "f3fora/cmp-spell",
        after = "nvim-cmp",
        config = function() astronvim.add_cmp_source { name = "spell", priority = 200 } end,
      },

      -- Tools
      { "tpope/vim-fugitive" },
      {
        "kylechui/nvim-surround",
        config = function() require("nvim-surround").setup {} end,
      },
      {
        "ggandor/leap.nvim",
        config = function() require("leap").set_default_keymaps() end,
      },

      -- Text objects
      {
        "nvim-treesitter/playground",
        after = "nvim-treesitter",
        config = function() require("nvim-treesitter.configs").setup {} end,
      },
      {
        "ziontee113/syntax-tree-surfer",
        after = "nvim-treesitter",
        config = function()
          require("syntax-tree-surfer").setup {}

          local opts = { noremap = true, silent = true }

          -- Normal Mode Swapping:
          -- Swap The Master Node relative to the cursor with it's siblings, Dot Repeatable
          vim.keymap.set("n", "vU", function()
            vim.opt.opfunc = "v:lua.STSSwapUpNormal_Dot"
            return "g@l"
          end, { silent = true, expr = true })
          vim.keymap.set("n", "vD", function()
            vim.opt.opfunc = "v:lua.STSSwapDownNormal_Dot"
            return "g@l"
          end, { silent = true, expr = true })

          -- Swap Current Node at the Cursor with it's siblings, Dot Repeatable
          vim.keymap.set("n", "vd", function()
            vim.opt.opfunc = "v:lua.STSSwapCurrentNodeNextNormal_Dot"
            return "g@l"
          end, { silent = true, expr = true })
          vim.keymap.set("n", "vu", function()
            vim.opt.opfunc = "v:lua.STSSwapCurrentNodePrevNormal_Dot"
            return "g@l"
          end, { silent = true, expr = true })

          -- Visual Selection from Normal Mode
          vim.keymap.set("n", "vx", "<cmd>STSSelectMasterNode<cr>", opts)
          vim.keymap.set("n", "vn", "<cmd>STSSelectCurrentNode<cr>", opts)

          -- Select Nodes in Visual Mode
          vim.keymap.set("x", "J", "<cmd>STSSelectNextSiblingNode<cr>", opts)
          vim.keymap.set("x", "K", "<cmd>STSSelectPrevSiblingNode<cr>", opts)
          vim.keymap.set("x", "H", "<cmd>STSSelectParentNode<cr>", opts)
          vim.keymap.set("x", "L", "<cmd>STSSelectChildNode<cr>", opts)

          -- Swapping Nodes in Visual Mode
          vim.keymap.set("x", "<A-j>", "<cmd>STSSwapNextVisual<cr>", opts)
          vim.keymap.set("x", "<A-k>", "<cmd>STSSwapPrevVisual<cr>", opts)
        end,
      },

      -- Github:
      {
        "pwntester/octo.nvim",
        after = { "telescope.nvim" },
        config = function() require("octo").setup() end,
      },

      -- disable plugins:
      ["akinsho/bufferline.nvim"] = { disable = true },
      ["goolord/alpha-nvim"] = { disable = true },
      ["nvim-telescope/telescope-fzf-native.nvim"] = { disable = true }, -- fails to build due to missing build tools
      ["declancm/cinnamon.nvim"] = { disable = true }, -- Slow scrolling
      ["nvim-treesitter/nvim-treesitter"] = { run = ':echo "No TSUpdate!"' },
    },
    ["neo-tree"] = {
      event_handlers = {}, -- do not mess with signcolumns!
    },
    ["null-ls"] = function(config)
      local null_ls = require "null-ls"
      local vale = null_ls.builtins.diagnostics.vale
      vale["filetypes"] = { "markdown", "tex", "asciidoc", "html" }
      -- Check supported formatters and linters
      config.sources = {
        null_ls.builtins.code_actions.shellcheck,
        -- Set a linter
        null_ls.builtins.diagnostics.actionlint,
        null_ls.builtins.diagnostics.eslint,
        null_ls.builtins.diagnostics.fish,
        null_ls.builtins.diagnostics.gitlint,
        null_ls.builtins.diagnostics.luacheck,
        null_ls.builtins.diagnostics.markdownlint,
        null_ls.builtins.diagnostics.mypy,
        null_ls.builtins.diagnostics.shellcheck,
        vale,
        null_ls.builtins.diagnostics.vulture,
        null_ls.builtins.diagnostics.yamllint,
        -- Set a formatter
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.jq,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.shellharden,
        null_ls.builtins.formatting.stylua,
      }
      return config
    end,
    ["telescope"] = {
      defaults = {
        layout_strategy = "vertical",
        layout_config = {
          vertical = {
            prompt_position = "top",
            mirror = true,
            preview_cutoff = 40,
            preview_height = 0.5,
          },
          width = 0.95,
          height = 0.95,
        },
      },
    },
  },

  polish = function()
    vim.opt.runtimepath:append "/home/extra/.local/share/nvim/treesitter" -- treesiter location override!

    local map = vim.api.nvim_set_keymap
    local unmap = vim.api.nvim_del_keymap

    _G.hu_is_qf_open = function()
      for _, win in pairs(vim.fn.getwininfo()) do
        if win["quickfix"] == 1 then return true end
      end
      return false
    end

    _G.hu_toggle_qf = function()
      if hu_is_qf_open() then
        vim.cmd "cclose"
      else
        vim.cmd "copen"
      end
    end

    -- Undo some AstroVim mappings:
    -- unmap("n", "<leader>u")
    unmap("n", "<C-q>")
    unmap("n", "<C-s>")
    unmap("n", "<leader>h")
    unmap("n", "<leader>q")
    unmap("n", "<leader>sb") -- use <leader>gb
    unmap("n", "<leader>sh") -- use <leader>fh
    unmap("n", "<leader>sm")
    unmap("n", "<leader>tl")
    unmap("n", "<leader>tn")
    unmap("n", "<leader>tp")
    unmap("n", "<leader>w")
    -- Packer/Mason keymaps:
    unmap("n", "<leader>pA")
    unmap("n", "<leader>pS")
    unmap("n", "<leader>pc")
    unmap("n", "<leader>pi")
    unmap("n", "<leader>ps")
    unmap("n", "<leader>pu")
    unmap("n", "<leader>pv")

    -- Allow gf to work for non-existing files
    map("n", "gf", ":edit <cfile><cr>", { desc = "Edit file" })
    map("v", "gf", ":edit <cfile><cr>", { desc = "Edit file" })
    map("o", "gf", ":edit <cfile><cr>", { desc = "Edit file" })

    map("n", "<f8>", ":cprev<cr>", { desc = "Previous item in quickfix list" })
    map("n", "<f9>", ":cnext<cr>", { desc = "Next item in quickfix list" })
    map("n", "<leader>qf", ":lua hu_toggle_qf()<cr>", { desc = "Toggle quickfix list" })

    vim.api.nvim_create_augroup("slint_auto", { clear = true })
    vim.api.nvim_create_autocmd(
      { "BufNewFile", "BufRead" },
      { group = "slint_auto", pattern = "*.slint", callback = function() vim.bo.filetype = "slint" end }
    )

    -- Prettify LSP logs:
    require('vim.lsp.log').set_format_func(vim.inspect);

    -- Slint LSP test related helpers:
    _G.slint_dev_attach_to_current_buffer = function()
      if _G.slint_dev_id then
        print "Already running!"
        return nil
      end

      local srv = astronvim.lsp.server_settings "slint_lsp" or {}
      srv.name = "dev-slint"
      srv.root_dir = vim.fn.expand "%:p:h"

      srv.cmd = { "/home/dev/src/slint/target/debug/slint-lsp" }
      srv.cmd_cwd = srv.root_dir

      _G.slint_dev_id = vim.lsp.start_client(srv)
      vim.lsp.buf_attach_client(0, _G.slint_dev_id)
      return _G.slint_dev_id
    end

    _G.slint_dev_client = function() return vim.lsp.get_client_by_id(_G.slint_dev_id) end

    _G.slint_dev_kill = function()
      vim.lsp.stop_client(_G.slint_dev_id, true)
      _G.slint_dev_id = nil
    end

    _G.slint_dev_execute = function(cmd, args, handler)
      _G.slint_dev_client().request("workspace/executeCommand", { command = cmd, arguments = args }, handler, 0)
    end

    _G.slint_dev_restart = function()
      if _G.slint_dev_id then _G.slint_dev_kill() end
      _G.slint_dev_attach_to_current_buffer()
    end

    _G.slint_dev_notifier = function(e, r, ctx, c)
      vim.notify("Handled something!\n" .. vim.inspect { error = e, reply = r, context = ctx, config = c })
    end

    vim.api.nvim_create_user_command("SDAttach", _G.slint_dev_attach_to_current_buffer, {})
    vim.api.nvim_create_user_command("SDRestart", _G.slint_dev_restart, {})
    vim.api.nvim_create_user_command("SDKill", _G.slint_dev_kill, {})
    vim.api.nvim_create_user_command(
      "SDExecShowPreview",
      function()
        _G.slint_dev_execute(
          "workspace/executeCommand",
          { command = "showPreview", arguments = { vim.fn.expand "%s:p", "Counter" } },
          _G.slint_dev_notifier
        )
      end,
      {}
    )

    vim.api.nvim_create_augroup("slint_dev_auto", { clear = true })
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
      group = "slint_auto",
      pattern = "*.slintnightly",
      callback = function() _G.slint_dev_attach_to_current_buffer() end,
    })
  end,
}

return config
