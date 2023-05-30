-- where a value with no key simply has an implicit numeric key

-- Slint LSP test related helpers:
local slint_dev_lsp_id = nil

_G.slint_dev_attach_to_current_buffer = function()
  if slint_dev_lsp_id then
    if vim.lsp.get_client_by_id(slint_dev_lsp_id) then
      print "Already running!"
      return slint_dev_lsp_id
    else
      slint_dev_lsp_id = nil
    end
  end

  local lsp = require("astronvim.utils.lsp");

  local srv = lsp.config "slint_lsp" or {}
  srv.name = "dev-slint"
  srv.root_dir = vim.fn.expand "%:p:h"

  srv.cmd = { "C:\\src\\slint\\target\\debug\\slint-lsp" }
  srv.cmd_cwd = srv.root_dir
  local on_init = srv.on_init

  slint_dev_lsp_id = nil

  srv.on_init = function(client, result)
    slint_dev_lsp_id = client.id
    if on_init then
      on_init(client, result)
    end
    vim.lsp.buf_attach_client(0, slint_dev_lsp_id)
  end

  vim.lsp.start_client(srv)
end

_G.slint_dev_client = function() return vim.lsp.get_client_by_id(slint_dev_lsp_id) end

_G.slint_dev_kill = function()
  if slint_dev_lsp_id then
    vim.lsp.stop_client(slint_dev_lsp_id, true)
    slint_dev_lsp_id = nil
  end
end

_G.slint_dev_execute = function(cmd, args, handler)
  _G.slint_dev_client().request("workspace/executeCommand", { command = cmd, arguments = args }, handler, 0)
end

_G.slint_dev_restart = function()
  _G.slint_dev_kill()
  _G.slint_dev_attach_to_current_buffer()
end

_G.slint_dev_notifier = function(e, r, ctx, c)
  vim.notify("Handled something!\n" .. vim.inspect { error = e, reply = r, context = ctx, config = c })
end

local config = {
  -- set vim options here (vim.<first_key>.<second_key> = value)
  options = {
    opt = {
      clipboard = "",
      colorcolumn = "80,100",
      foldcolumn = "0", -- no folding marks
      numberwidth = 4,
      showtabline = 0,
      -- set to true or false etc.
      spell = true, -- sets vim.opt.spell
      timeoutlen = 1000, -- I'm a slow typist!
      undofile = false,
    },
    g = {
      autoformat_enabled = false, -- enable or disable auto formatting at start (lsp.formatting.format_on_save must be enabled)
      markdown_fenced_languages = { "ts=typescript" },
    },
  },

  -- Mapping data with "desc" stored directly by vim.keymap.set().
  mappings = {
    -- first key is the mode
    n = {
      ["<C-q>"] = false,
      ["<C-s>"] = false,

      -- My config:
      ["gf"] = { ":edit <cfile><cr>", desc = "Edit file" },

    },
    v = {
      ["gf"] = { ":edit <cfile><cr>", desc = "Edit file" },
    },
    o = {
      ["gf"] = { ":edit <cfile><cr>", desc = "Edit file" },
    },
    t = {},
  },

  -- Configure plugins
  plugins = {
    -- Extended file type support
    { "sheerun/vim-polyglot", lazy = false },

    -- Community plugins:
    "AstroNvim/astrocommunity",
    { import = "astrocommunity.pack.bash" },
    { import = "astrocommunity.pack.cmake" },
    { import = "astrocommunity.pack.cpp" },
    { import = "astrocommunity.pack.json" },
    { import = "astrocommunity.pack.lua" },
    { import = "astrocommunity.pack.markdown" },
    { import = "astrocommunity.pack.python" },
    { import = "astrocommunity.pack.rust" },
    { import = "astrocommunity.pack.toml" },
    { import = "astrocommunity.pack.typescript" },
    { import = "astrocommunity.pack.yaml" },

    { import = "astrocommunity.diagnostics.trouble-nvim" },
    { import = "astrocommunity.git.octo-nvim" },
    { import = "astrocommunity.lsp.lsp-inlayhints-nvim" },
    -- Use real inlay hints!
    { "lvimuser/lsp-inlayhints.nvim", branch = "anticonceal", },
    { import = "astrocommunity.motion.leap-nvim" },
    { import = "astrocommunity.motion.nvim-surround" },

    -- OVERRIDE AstronVim plugins:
    { "max397574/better-escape.nvim", enabled = false },
    { "goolord/alpha-nvim", enabled = false },
    { "nvim-telescope/telescope-fzf-native.nvim", enabled = false }, -- fails to build due to missing build tools
    -- {
    --   "L3MON4D3/LuaSnip",
    --   config = function(plugin, opts)
    --     require("plugins.configs.luasnip")(plugin, opts)
    --     require("luasnip.loaders.from_vscode").lazy_load { paths = { "/home/extra/.config/nvim-data/snippets" } } -- Not needed on windows! 
    --   end,
    -- },
    -- force enable nvim-dap on windows
    { "mfussenegger/nvim-dap", enabled = true },
    {
      "hrsh7th/nvim-cmp",
      opts = function(_, opts)
        local cmp = require "cmp"
        local utils = require("astronvim.utils")
        local luasnip = require "luasnip"

        return utils.extend_tbl({
          mapping = {
            ["<Tab>"] = cmp.mapping(function(fallback)
              if luasnip.jumpable(1) then
                luasnip.jump(1)
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          },
        }, opts)
      end,
    },
    {
      "nvim-telescope/telescope.nvim",
      opts = {
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
        pickers = {
          current_buffer_tags = { fname_width = 100, },
          jumplist = { fname_width = 100, },
          loclist = { fname_width = 100, },
          lsp_definitions = { fname_width = 100, },
          lsp_document_symbols = { fname_width = 100, },
          lsp_dynamic_workspace_symbols = { fname_width = 100, },
          lsp_implementations = { fname_width = 100, },
          lsp_incoming_calls = { fname_width = 100, },
          lsp_outgoing_calls = { fname_width = 100, },
          lsp_references = { fname_width = 100, },
          lsp_type_definitions = { fname_width = 100, },
          lsp_workspace_symbols = { fname_width = 100, symbol_width = 50, },
          quickfix = { fname_width = 100, },
          tags = { fname_width = 100, },
        }
      },
    },
    -- override heirline config
    {
      "rebelot/heirline.nvim",
      opts = function(_, opts)
        local status = require("astronvim.utils.status");

        opts.statusline = {
          hl = { fg = "fg", bg = "bg" },
          status.component.mode(),
          status.component.git_branch(),
          status.component.git_diff(),
          status.component.fill(),
          status.component.lsp(),
          status.component.treesitter(),
          status.component.nav { scrollbar = false, percentage = false, padding = { left = 1 } },
          status.component.mode { surround = { separator = "right" } },
        }
        opts.winbar = {
          hl = { fg = "fg", bg = "bg" },
          status.component.file_info { filename = { modify = ":p:." }, },
          status.component.breadcrumbs { icon = { hl = true }, padding = { left = 1 } },
          status.component.fill(),
          status.component.diagnostics(),
        }
        opts.tabline = {}

        return opts
      end,
    },
  },

  polish = function()
    -- vim.opt.runtimepath:append "/home/extra/.local/share/nvim/treesitter" -- treesiter location override!
  
    -- override LSP inlay hints
    vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#777d86", italic = true, })

    vim.api.nvim_create_augroup("slint_auto", { clear = true })
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
      group = "slint_auto",
      pattern = "*.slint",
      callback = function() vim.bo.filetype = "slint" end,
    })

    -- Prettify LSP logs:
    require("vim.lsp").set_log_level("OFF")
    require("vim.lsp.log").set_format_func(vim.inspect)

    vim.api.nvim_create_user_command("SDAttach", _G.slint_dev_attach_to_current_buffer, {})
    vim.api.nvim_create_user_command("SDRestart", _G.slint_dev_restart, {})
    vim.api.nvim_create_user_command("SDKill", _G.slint_dev_kill, {})
    vim.api.nvim_create_user_command(
      "SDExecDesignModeEnable",
      function()
        _G.slint_dev_execute("slint/setDesignMode", { true }, _G.slint_dev_notifier)
      end,
      {}
    )
    vim.api.nvim_create_user_command(
      "SDExecDesignModeDisable",
      function()
        _G.slint_dev_execute("slint/setDesignMode", { false }, _G.slint_dev_notifier)
      end,
      {}
    )
    vim.api.nvim_create_user_command(
      "SDExecShowPreview",
      function()
        local url = vim.fn.expand "%:p"
        url = url:gsub("\\", "/");
        url = "file://" .. url;
        _G.slint_dev_execute("slint/showPreview", { url }, _G.slint_dev_notifier)
      end,
      {}
    )
  end,
}

return config
