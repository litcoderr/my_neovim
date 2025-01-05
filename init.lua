-- ====================
--  Basic Settings
-- ====================

-- Set leader key
vim.g.mapleader = " "

-- Enable system clipboard
vim.opt.clipboard = "unnamedplus"

-- Visual mode clipboard keybindings
vim.keymap.set('v', '<leader>y', '"+y', { noremap = true, silent = true }) -- Copy to clipboard
vim.keymap.set('v', '<leader>p', '"+p', { noremap = true, silent = true }) -- Paste from clipboard

-- Enable relative numbering
vim.opt.number = true         -- Absolute number for the current line
vim.opt.relativenumber = true -- Relative numbers for other lines

-- ====================
--  Plugin Management
-- ====================

vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
  -- Plugin manager
  use 'wbthomason/packer.nvim'

  -- LSP and Language Tools
  use 'neovim/nvim-lspconfig'          -- LSP configurations
  use 'williamboman/mason.nvim'        -- LSP/DAP installer
  use 'williamboman/mason-lspconfig.nvim'
  use 'hrsh7th/nvim-cmp'               -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp'           -- LSP completion source
  use 'L3MON4D3/LuaSnip'               -- Snippet engine
  use 'nvim-treesitter/nvim-treesitter'-- Treesitter for better syntax
  use 'rust-lang/rust.vim'             -- Rust support

  -- Telescope and Extensions
  use {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.2', -- Stable version
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' } -- FZF sorter
  use { 'nvim-telescope/telescope-file-browser.nvim' }             -- File browser

  -- Git Integration
  use 'tpope/vim-fugitive' -- Git commands

  -- Themes
  use 'Mofiqul/vscode.nvim'
  use 'projekt0n/github-nvim-theme'
end)

-- ====================
--  Mason Setup
-- ====================
require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    'pyright',
    'ts_ls', -- Ensure TypeScript server is installed
    'html',
    'cssls',
    'rust_analyzer',
  }
})

-- ====================
--  LSP Keymaps & Setup
-- ====================

-- Common on_attach function for all LSP servers
local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Go to definition
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  -- Go to references (usages)
  vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, { noremap = true, silent = true })
  -- Hover documentation
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  -- Signature help
  vim.keymap.set('n', '<leader>k', vim.lsp.buf.signature_help, opts)
  -- Rename symbol
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  -- Code actions
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  -- Go to declaration
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  -- Go to implementation
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  -- Format the buffer
  vim.keymap.set('n', '<leader>f', function()
    vim.lsp.buf.format { async = true }
  end, opts)
end

local lspconfig = require('lspconfig')

-- Python
lspconfig.pyright.setup({
  on_attach = on_attach,
})

-- TypeScript/JavaScript with JSX/TSX Support
lspconfig.ts_ls.setup({
  on_attach = on_attach,
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", ".git"),
})

-- HTML
lspconfig.html.setup({
  on_attach = on_attach,
})

-- CSS
lspconfig.cssls.setup({
  on_attach = on_attach,
})

-- Rust
lspconfig.rust_analyzer.setup({
  on_attach = on_attach,
})

-- ====================
--  Treesitter setup
-- ====================
require('nvim-treesitter.configs').setup {
  ensure_installed = { 'python', 'javascript', 'typescript', 'tsx', 'html', 'css', 'rust' },
  highlight = {
    enable = true
  },
}

-- ====================
--  Autocompletion setup
-- ====================
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- Use LuaSnip for snippets
    end,
  },
  mapping = {
    ['<Tab>']   = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>']    = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = 'nvim_lsp' }, -- LSP-based completion
    { name = 'buffer' },   -- From the current buffer
    { name = 'path' },     -- File path suggestions
  },
})

-- ====================
--  Telescope Setup
-- ====================
local telescope = require('telescope')
local actions   = require('telescope.actions')
local fb_actions = require('telescope._extensions.file_browser.actions')

telescope.setup({
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
    },
    prompt_prefix = "🔍 ",
    selection_caret = "➜ ",
    path_display = { "truncate" },
    layout_strategy = "horizontal",
    layout_config = {
      width = 0.8,
      height = 0.8,
      preview_width = 0.5,
      prompt_position = "top",
    },
    sorting_strategy = "ascending",
  },
  pickers = {
    find_files = {
      hidden = true,
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    file_browser = {
      mappings = {
        ["i"] = {
          ["<CR>"] = actions.select_default,
          ["<C-e>"] = fb_actions.create,
          ["<C-r>"] = fb_actions.rename,
          ["<C-d>"] = fb_actions.remove,
          ["<C-m>"] = fb_actions.move,
        },
        ["n"] = {
          ["<CR>"] = actions.select_default,
          ["e"] = fb_actions.create,
          ["r"] = fb_actions.rename,
          ["d"] = fb_actions.remove,
          ["m"] = fb_actions.move,
        },
      },
    },
  },
})

-- Load telescope extensions
telescope.load_extension('fzf')
telescope.load_extension('file_browser')

-- Telescope keybindings
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, { noremap = true, silent = true })

-- Open the file browser, starting in the current file's directory
vim.keymap.set('n', '<leader>fe', function()
  telescope.extensions.file_browser.file_browser({
    path = vim.fn.expand('%:p:h'),
    cwd = vim.fn.expand('%:p:h'),
    respect_gitignore = false,
    hidden = true,
    grouped = true,
    previewer = false,
  })
end, { noremap = true, silent = true })

-- Telescope Git Fugitive commands
vim.keymap.set('n', '<leader>gs', builtin.git_status, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gc', builtin.git_commits, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gb', builtin.git_branches, { noremap = true, silent = true })

-- ====================
--  Color Scheme
-- ====================
vim.o.background = 'dark'
vim.cmd.colorscheme "github_dark_high_contrast"

-- ====================
--  Indentation for All Files
-- ====================
vim.opt.tabstop = 2      -- Number of spaces a <Tab> counts for
vim.opt.shiftwidth = 2   -- Number of spaces used for autoindent
vim.opt.expandtab = true -- Convert tabs to spaces

