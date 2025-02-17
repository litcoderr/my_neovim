-- ====================
--  Basic Settings
-- ====================

vim.opt.guicursor = "n-v-c:block-blinkwait500-blinkon200-blinkoff150,i-ci-ve:ver25-blinkwait500-blinkon200-blinkoff150,r-cr:hor20,o:hor50"

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

  -- DAP
  use 'mfussenegger/nvim-dap'              -- Core DAP plugin
  use 'rcarriga/nvim-dap-ui'               -- DAP UI for interactive debugging
  use 'mfussenegger/nvim-dap-python'       -- Python-specific adapter
  use {
    'nvim-neotest/nvim-nio',               -- nvim-nio dependency
    requires = { 'nvim-lua/plenary.nvim' } -- Ensure plenary.nvim is installed
  }

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

  -- Scroll Bar
  use("petertriho/nvim-scrollbar")

  -- Smooth Scrolling
  use 'karb94/neoscroll.nvim'

  -- Themes
  use 'Mofiqul/vscode.nvim'
  use 'projekt0n/github-nvim-theme'
  use { "scottmckendry/cyberdream.nvim" }

  -- Obsidian
  use({
    "epwalsh/obsidian.nvim",
    tag = "*",
    requires = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("obsidian").setup({
        workspaces = {
          {
            name = "personal",
            path = "~/ObsidianVault",
            strict = true,
          },
        },
        notes_subdir = ".",
      })
    end,
  })
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
    'clangd',
  }
})

-- ====================
--  Neoscroll Setup
-- ====================
require('neoscroll').setup({
    easing_function = "quadratic",  -- Easing function for smooth scrolling
    hide_cursor = true,            -- Hide cursor while scrolling
})

-- Custom scroll mappings
local neoscroll = require('neoscroll')
local map = {}

map['<C-u>'] = {'scroll', {'-vim.wo.scroll', 'true', '150'}}
map['<C-d>'] = {'scroll', { 'vim.wo.scroll', 'true', '150'}}
map['<C-b>'] = {'scroll', {'-vim.api.nvim_win_get_height(0)', 'true', '200'}}
map['<C-f>'] = {'scroll', { 'vim.api.nvim_win_get_height(0)', 'true', '200'}}
neoscroll.setup({ mappings = map })

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

-- goto enclosing function or method
local function goto_enclosing_function_or_class()
  local ts_utils = require('nvim-treesitter.ts_utils')
  local node = ts_utils.get_node_at_cursor()

  -- Save current position for <C-o> to work
  vim.cmd("normal! m'")

  while node do
    local type = node:type()
    if type == "function_definition" or type == "class_definition" or
       type == "method_definition" or type == "struct_specifier" then
      local start_row, start_col, _, _ = node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
      return
    end
    node = node:parent()
  end

  print("No enclosing function or class found")
end

vim.keymap.set("n", "<leader>ce", goto_enclosing_function_or_class, { noremap = true, silent = true })


local lspconfig = require('lspconfig')

-- Python
lspconfig.pyright.setup({
  on_attach = on_attach,
  settings = {
    python = {
      pythonPath = vim.g.python3_host_prog,
      analysis = {
        typeCheckingMode = 'off',
      }
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

-- C++ (clangd) Setup
lspconfig.clangd.setup({
  on_attach = on_attach,
  cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
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
vim.keymap.set('n', '<C-t>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

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

-- ====================
--  Nvim Scrollbar Setup
-- ====================
require("scrollbar").setup()

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
require("cyberdream").setup({
  transparent = false,  -- Disable transparency to let Neovim handle the background
  borderless_pickers = false,
  colors = {
    bg = "#000000",  -- Set background to pure black
    -- Customize other colors as needed to match VSCode
  },
  overrides = function(colors)
    return {
      -- TODO override color to match vscode
    }
  end,
})
vim.cmd("colorscheme cyberdream")

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

-- DAP setup
local function get_python_path()
  -- Use the Python path defined in Neovim settings
  return vim.g.python3_host_prog or vim.fn.system("which python"):gsub("%s+", "")
end

-- Configure nvim-dap for Python
local dap = require('dap')
local dap_python = require('dap-python')
local dapui = require('dapui')

-- Setup dap-python with the correct interpreter
dap_python.setup(get_python_path())

-- Configure DAP UI
dapui.setup()

-- Automatically open/close DAP UI
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Debugging keymaps
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<F5>', dap.continue, opts)                 -- Start/continue debugging
vim.keymap.set('n', '<F10>', dap.step_over, opts)              -- Step over
vim.keymap.set('n', '<F11>', dap.step_into, opts)              -- Step into
vim.keymap.set('n', '<F12>', dap.step_out, opts)               -- Step out
vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, opts) -- Toggle breakpoint
vim.keymap.set('n', '<leader>dc', dap.clear_breakpoints, opts) -- Clear breakpoints
vim.keymap.set('n', '<leader>dr', dap.repl.open, opts)         -- Open DAP REPL
vim.keymap.set('n', '<leader>dl', dap.run_last, opts)          -- Run last debug session
vim.keymap.set('n', '<leader>du', dapui.toggle, opts)          -- Toggle DAP UI

-- Python debug configurations
dap.configurations.python = {
  {
    type = 'python',  -- Use the Python DAP
    request = 'launch',
    name = 'Launch file',
    program = '${file}',  -- Run the current file
    pythonPath = function()
      return get_python_path()
    end,
  },
}

-- code structure shortcuts
local function find_methods_or_functions()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local telescope = require("telescope.builtin")
  local node = ts_utils.get_node_at_cursor()

  if not node then
    print("No Treesitter node found.")
    return
  end

  -- Walk upward to locate a Python class definition.
  local current_node = node
  local class_node = nil
  while current_node do
    if current_node:type() == "class_definition" then
      class_node = current_node
      break
    end
    current_node = current_node:parent()
  end

  if not class_node then
    telescope.lsp_document_symbols({ symbols = { "Function", "Method" } })
    return
  end

  -- Helper: Extract method name from its identifier child.
  local function get_method_name(method_node)
    for child in method_node:iter_children() do
      if child:type() == "identifier" then
        return vim.treesitter.get_node_text(child, vim.api.nvim_get_current_buf())
      end
    end
    return vim.treesitter.get_node_text(method_node, vim.api.nvim_get_current_buf())
  end

  -- Recursively search for Python function definitions within the class.
  local methods = {}
  local function search_methods(node)
    for child in node:iter_children() do
      local child_type = child:type()
      if child_type == "function_definition" or child_type == "async_function_definition" then
        local start_row, _, _, _ = child:range()
        local method_name = get_method_name(child)
        table.insert(methods, { name = method_name, line = start_row + 1 })
      end
      search_methods(child)
    end
  end

  search_methods(class_node)

  if #methods == 0 then
    print("No methods found in class.")
    return
  end

  -- Capture the source buffer from which we want to pull content.
  local source_bufnr = vim.api.nvim_get_current_buf()
  local previewers = require("telescope.previewers")
  
  require("telescope.pickers").new({}, {
    prompt_title = "Methods in Class",
    finder = require("telescope.finders").new_table({
      results = methods,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
          lnum = entry.line,
        }
      end,
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, status)
        -- Retrieve all lines from the source buffer.
        local all_lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
        local total_lines = #all_lines

        -- Get the preview window height.
        local preview_win = status.preview_win
        local win_height = vim.api.nvim_win_get_height(preview_win)

        -- Center the snippet around the method's starting line.
        local target_line = entry.lnum -- (1-indexed)
        local half_height = math.floor(win_height / 2)
        local start_line = math.max(0, target_line - half_height - 1)  -- 0-indexed
        local end_line = math.min(total_lines, start_line + win_height)

        local snippet = {}
        for i = start_line, end_line - 1 do
          table.insert(snippet, all_lines[i + 1])
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, snippet)
        -- Set the filetype from the source buffer to trigger syntax highlighting.
        local ft = vim.api.nvim_buf_get_option(source_bufnr, "filetype")
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", ft)
        -- Clear any special buffer type to enable full highlighting.
        vim.api.nvim_buf_set_option(self.state.bufnr, "buftype", "")
        -- Force syntax to load by explicitly setting it.
        vim.cmd(string.format("setlocal syntax=%s", ft))

        -- Highlight the method's starting line within the snippet.
        local highlight_line = target_line - start_line - 1
        if highlight_line >= 0 and highlight_line < win_height then
          vim.api.nvim_buf_add_highlight(self.state.bufnr, -1, "Search", highlight_line, 0, -1)
        end
      end,
    }),
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
      end)
      return true
    end,
  }):find()
end

local function find_classes()
  require('telescope.builtin').lsp_document_symbols({
    symbols = { "Class", "Struct" }
  })
end
-- View Code Structure key binding
vim.keymap.set('n', '<leader>cs', ':Telescope lsp_document_symbols<CR>', { noremap = true, silent = true, desc = "View code structure" })
-- View method or function within cursor class or file
vim.keymap.set("n", "<leader>cm", find_methods_or_functions, { noremap = true, silent = true })
-- View all classes within this file
vim.keymap.set("n", "<leader>cc", find_classes, { noremap = true, silent = true })



-- Obsidian key binding
vim.opt.conceallevel = 1
vim.keymap.set("n", "<leader>on", function()
  local original_cwd = vim.fn.getcwd()  -- Save current working directory
  vim.cmd("lcd ~/ObsidianVault")        -- Switch to Obsidian vault
  vim.cmd("ObsidianNew")                -- Create a new note
  vim.cmd("lcd " .. original_cwd)       -- Restore original working directory
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ot", function()
  local date = os.date("%Y-%m-%d")
  local vault_path = os.getenv("HOME") .. "/ObsidianVault/daily/"
  local file_path = vault_path .. date .. ".md"

  -- Ensure the directory exists
  vim.fn.mkdir(vault_path, "p")

  -- Create the file if it doesn't exist
  if vim.fn.filereadable(file_path) == 0 then
    local file = io.open(file_path, "w")
    if file then
      -- Write Obsidian-style YAML front matter
      file:write("---\n")
      file:write("title: " .. date .. "\n")
      file:write("aliases: [\"" .. date .. "\"]\n")
      file:write("tags: [daily]\n")
      file:write("created: " .. os.date("%Y-%m-%dT%H:%M:%S") .. "\n")
      file:write("---\n\n")
      file:write("# " .. date .. "\n\n") -- Optional: Adds a title
      file:close()
    end
  end

  -- Open the file in the current Neovim buffer
  vim.cmd("edit " .. file_path)
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>of", "<cmd>ObsidianQuickSwitch<CR>", { noremap = true, silent = true }) -- Fuzzy find notes
vim.keymap.set("n", "<leader>ol", "<cmd>ObsidianFollowLink<CR>", { noremap = true, silent = true }) -- Follow link under cursor
vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { noremap = true, silent = true }) -- Show backlinks

