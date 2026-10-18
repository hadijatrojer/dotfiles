# Neovim

Single-file Neovim 0.12 config (`.config/nvim/init.lua`) using `vim.pack` and
built-ins. Modelled on martin-dotfiles' nvim, trimmed further: no starter
screen, tabline, tmux navigator, or custom keymap modules.

## Plugins

| Plugin | Why |
|--------|-----|
| catppuccin | Mocha, matching foot/tmux/btop |
| mini.nvim | icons, statusline, surround, pairs, clue |
| fzf-lua | picker + `vim.ui.select` |
| oil.nvim | `-` file explorer |
| vim-fugitive | `:Git` |
| nvim-lspconfig | server definitions only (`lsp/*.lua`), enabled via `vim.lsp.enable` |
| nvim-treesitter (main) | `:TSInstall` / `:TSUpdate` parsers |

Built-ins cover LSP, completion (`vim.lsp.completion`), commenting (`gc`),
`K`, `grn`/`gra`/`gri`/`grt`, `gO`, `[d`/`]d`, `gx`.

`nvim-pack-lock.json` pins plugin revisions; commit it after `:PackUpdate`.

## LSP servers

Servers are enabled only if their binary is on `PATH`: `mdroots`, `lua-language-server`,
`bash-language-server`, `ty`, `ruff`, `rust-analyzer`,
`typescript-language-server`, `gopls`.

Parser installs need the `tree-sitter` CLI (`mise use -g tree-sitter@latest`)
and a C compiler.

## Keys

| Key | Action |
|-----|--------|
| `<leader><space>` / `<leader>ff` | files |
| `<leader>/` / `<leader>sg` | live grep |
| `<leader>,` | buffers |
| `<leader>fr` | recent files |
| `<leader>f.` | resume picker |
| `<leader>sw` `sh` `sk` `sd` `ss` | grep word, help, keymaps, diagnostics, symbols |
| `<leader>gg` `gb` `gs` `gl` | fugitive, blame, status, log |
| `gd` / `gr` | definition / references (fzf) |
| `<leader>cf` | format |
| `-` | oil |
