-- Minimal Neovim 0.12 config: vim.pack + built-ins. See ~/dotfiles/nvim/README.md

-- Options ------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
for _, p in ipairs({ "node", "perl", "python3", "ruby" }) do
  vim.g["loaded_" .. p .. "_provider"] = 0
end

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.mouse = "a"
o.clipboard = "unnamedplus"
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.splitbelow = true
o.splitright = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.winborder = "rounded"
o.laststatus = 3
o.completeopt = "menuone,noselect,popup,fuzzy"

-- Plugins ------------------------------------------------------------
local gh = function(x) return "https://github.com/" .. x end
vim.pack.add({
  { src = gh("catppuccin/nvim"), name = "catppuccin" },
  gh("echasnovski/mini.nvim"),
  gh("ibhagwan/fzf-lua"),
  gh("stevearc/oil.nvim"),
  gh("tpope/vim-fugitive"),
  gh("neovim/nvim-lspconfig"), -- server configs only (lsp/*.lua)
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
})

-- Catppuccin Mocha matches foot/tmux/btop.
require("catppuccin").setup({ flavour = "mocha" })
vim.cmd.colorscheme("catppuccin")

require("mini.icons").setup()
require("mini.statusline").setup()
require("mini.surround").setup()
require("mini.pairs").setup()
local clue = require("mini.clue")
clue.setup({
  triggers = {
    { mode = "n", keys = "<leader>" },
    { mode = "n", keys = "g" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "z" },
  },
  clues = {
    clue.gen_clues.g(),
    clue.gen_clues.square_brackets(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
    { mode = "n", keys = "<leader>f", desc = "+find" },
    { mode = "n", keys = "<leader>s", desc = "+search" },
    { mode = "n", keys = "<leader>g", desc = "+git" },
  },
  window = { delay = 300 },
})

require("fzf-lua").setup({ "default-title" })
require("fzf-lua").register_ui_select()

require("oil").setup({
  default_file_explorer = true,
  columns = { "icon", "permissions", "size", "mtime" },
  keymaps = { ["<C-h>"] = false, ["<M-h>"] = "actions.select_split" },
  view_options = { show_hidden = true },
})

-- Treesitter: highlight when a parser exists; :TSInstall <lang> adds one.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
})

-- LSP ----------------------------------------------------------------
-- Enable only servers whose binary is on PATH (install via mise/uv/npm).
vim.lsp.config("lua_ls", {
  settings = { Lua = { workspace = { library = { vim.env.VIMRUNTIME } } } },
})
-- mdroots finds note roots itself; one client serves all markdown.
vim.lsp.config("mdroots", {
  cmd = { "mdroots", "lsp" },
  filetypes = { "markdown" },
  workspace_required = false,
})
local servers = {
  mdroots = "mdroots",
  lua_ls = "lua-language-server",
  bashls = "bash-language-server",
  ty = "ty",
  ruff = "ruff",
  rust_analyzer = "rust-analyzer",
  ts_ls = "typescript-language-server",
  gopls = "gopls",
}
for name, bin in pairs(servers) do
  if vim.fn.executable(bin) == 1 then vim.lsp.enable(name) end
end

vim.diagnostic.config({ virtual_text = true, float = { border = "rounded" } })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc }) end
    map("gd", "<cmd>FzfLua lsp_definitions<cr>", "Definition")
    map("gr", "<cmd>FzfLua lsp_references<cr>", "References")
    map("<leader>cf", vim.lsp.buf.format, "Format")
  end,
})

-- Keymaps ------------------------------------------------------------
-- 0.12 defaults already give: K, grn, gra, gri, grt, gO, [d/]d, gc, gx.
local map = vim.keymap.set
map("n", "<esc>", "<cmd>nohlsearch<cr>")
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
map("n", "<leader><space>", "<cmd>FzfLua files<cr>", { desc = "Find files" })
map("n", "<leader>/", "<cmd>FzfLua live_grep<cr>", { desc = "Grep" })
map("n", "<leader>,", "<cmd>FzfLua buffers<cr>", { desc = "Buffers" })
map("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Files" })
map("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Recent files" })
map("n", "<leader>f.", "<cmd>FzfLua resume<cr>", { desc = "Resume picker" })
map("n", "<leader>sg", "<cmd>FzfLua live_grep<cr>", { desc = "Grep" })
map("n", "<leader>sw", "<cmd>FzfLua grep_cword<cr>", { desc = "Grep word" })
map("n", "<leader>sh", "<cmd>FzfLua help_tags<cr>", { desc = "Help" })
map("n", "<leader>sk", "<cmd>FzfLua keymaps<cr>", { desc = "Keymaps" })
map("n", "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Diagnostics" })
map("n", "<leader>ss", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "Symbols" })
map("n", "<leader>gg", "<cmd>Git<cr>", { desc = "Fugitive" })
map("n", "<leader>gb", "<cmd>Git blame<cr>", { desc = "Blame" })
map("n", "<leader>gs", "<cmd>FzfLua git_status<cr>", { desc = "Status (fzf)" })
map("n", "<leader>gl", "<cmd>FzfLua git_commits<cr>", { desc = "Log" })

-- Commands / autocmds -----------------------------------------------
vim.api.nvim_create_user_command("PackUpdate", function() vim.pack.update() end, {})
vim.api.nvim_create_autocmd("TextYankPost", { callback = function() vim.hl.on_yank() end })
