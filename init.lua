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
  -- lualine
  use 'nvim-lualine/lualine.nvim'

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

  -- Cursor word
  use {
    "itchyny/vim-cursorword",
    event = {"BufReadPost", "BufWinEnter"},
  }

  -- JSON Schema Store
  use 'b0o/schemastore.nvim'

  -- Telescope and Extensions
  use {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.2', -- Stable version
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' } -- FZF sorter
  use { 'nvim-telescope/telescope-file-browser.nvim' }             -- File browser

  -- Nvim Tree
  use 'kyazdani42/nvim-tree.lua'

  -- Git Integration
  use 'tpope/vim-fugitive' -- Git commands

  -- Themes
  use 'Mofiqul/vscode.nvim'
  use 'projekt0n/github-nvim-theme'
  use { "scottmckendry/cyberdream.nvim" }
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
    'jsonls', -- JSON LSP
  }
})

-- ====================
--  LSP Keymaps & Setup
-- ====================

-- Python Setting
local function system(command)
  local file = assert(io.popen(command, 'r'))
  local output = file:read('*all'):gsub("%s+", "")
  file:close()
  return output
end

if vim.fn.executable("python") > 0 then
  vim.g.python3_host_prog = system("which python")
end

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
  settings = {
    python = {
      pythonPath = vim.g.python3_host_prog,
    }
  }
})

-- Configure `ruff-lsp`.
-- See: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ruff_lsp
-- For the default config, along with instructions on how to customize the settings
lspconfig.ruff.setup {
  init_options = {
    settings = {
      -- Any extra CLI arguments for `ruff` go here.
      args = {},
    }
  }
}

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

-- JSON
lspconfig.jsonls.setup({
  on_attach = on_attach,
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
})

-- ====================
--  Cursorword setup
-- ====================
vim.g.cursorword_highlight = true

-- ====================
--  Treesitter setup
-- ====================
require('nvim-treesitter.configs').setup {
  ensure_installed = { 'python', 'javascript', 'typescript', 'tsx', 'html', 'css', 'rust', 'json' },
  highlight = {
    enable = true
  },
}

-- ====================
--  Nvim-Tree Setup
-- ====================
require'nvim-tree'.setup {
  open_on_tab = false,
  disable_netrw = true,
  hijack_netrw = true,
  view = {
    width = 30,
    side = 'left',
  },
  update_focused_file = {
    enable = true, -- Enables syncing the tree view with the current file
    update_cwd = true, -- Change the directory of nvim-tree to the one of the current file
    ignore_list = {}, -- List of file types to ignore
  },
}
vim.keymap.set('n', '<leader>ft', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

-- ====================
--  Autocompletion Setup
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
vim.keymap.set('n', 'gr', builtin.lsp_references, { noremap = true, silent = true })

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
--vim.o.background = 'dark'
--vim.cmd.colorscheme "github_dark_high_contrast"
vim.cmd("colorscheme cyberdream")
require("cyberdream").setup({
  borderless_telescope = false
})

-- ====================
--  Indentation for All Files
-- ====================
vim.opt.tabstop = 2      -- Number of spaces a <Tab> counts for
vim.opt.shiftwidth = 2   -- Number of spaces used for autoindent
vim.opt.expandtab = true -- Convert tabs to spaces

-- ====================
--  Leader Key Split Remap
-- ====================
local opts = { noremap = true, silent = true }

-- Navigation between splits
vim.keymap.set('n', '<leader>wh', '<C-w>h', opts) -- Move to left split
vim.keymap.set('n', '<leader>wj', '<C-w>j', opts) -- Move to bottom split
vim.keymap.set('n', '<leader>wk', '<C-w>k', opts) -- Move to top split
vim.keymap.set('n', '<leader>wl', '<C-w>l', opts) -- Move to right split

-- Split management
vim.keymap.set('n', '<leader>ws', '<C-w>s', opts) -- Split horizontally
vim.keymap.set('n', '<leader>wv', '<C-w>v', opts) -- Split vertically
vim.keymap.set('n', '<leader>wc', '<C-w>c', opts) -- Close current split
vim.keymap.set('n', '<leader>wo', '<C-w>o', opts) -- Close all other splits

-- Resize splits
vim.keymap.set('n', '<leader>w>', '<C-w>>', opts) -- Increase width
vim.keymap.set('n', '<leader>w<', '<C-w><', opts) -- Decrease width
vim.keymap.set('n', '<leader>w+', '<C-w>+', opts) -- Increase height
vim.keymap.set('n', '<leader>w-', '<C-w>-', opts) -- Decrease height
vim.keymap.set('n', '<leader>we', '<C-w>=', opts) -- Equalize split sizes

-- Rotate splits
vim.keymap.set('n', '<leader>wr', '<C-w>r', opts) -- Rotate splits clockwise
vim.keymap.set('n', '<leader>wR', '<C-w>R', opts) -- Rotate splits counter-clockwise

-- Swap splits
vim.keymap.set('n', '<leader>wt', '<C-w>T', opts) -- Break current split into a new tab
vim.keymap.set('n', '<leader>wx', '<C-w>x', opts) -- Exchange current split with the next

-- ====================
--  Diagnostics Keymaps
-- ====================
-- Neovim built-in LSP diagnostic navigation

vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { noremap = true, silent = true, desc = "Go to next diagnostic" })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { noremap = true, silent = true, desc = "Go to previous diagnostic" })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { noremap = true, silent = true, desc = "Open floating diagnostic" })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setqflist, { noremap = true, silent = true, desc = "Populate quickfix list with diagnostics" })

-- lualine setup
require('lualine').setup({
    options = {
        theme = 'auto',  -- Choose your preferred theme
        component_separators = '|',
        section_separators = '',
        globalstatus = false, -- Set this to true for a single statusline across splits
    },
    tabline = {
        lualine_a = { 'buffers' },       -- Show open buffers
        lualine_b = { 'branch' },        -- Show the current Git branch
        lualine_c = { 'filename' },      -- Show the current file name
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
})


