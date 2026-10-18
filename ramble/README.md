# ramble

Config for [ramble](https://github.com/martintrojer/ramble), the terminal markdown reader (`m` in zsh). It lives at `ramble/.config/ramble/config.toml` and holds only what differs from ramble's defaults.

- No `[[lsp.server]]`: pages use ramble's built-in mdroots for links, backlinks, notes, search and tags. Editors that need mdroots as a language server (nvim) run `mdroots lsp` themselves; see `nvim/.config/nvim/init.lua`.
- `sidebar.show = "always"`: the sidebar stays visible (`<leader>e` hides it); `sidebar.default = "split"` shows files and outline together.
- Review comments, `<leader>rr` send (to the clipboard) and the mouse stay on by default. `<leader>o` opens `$VISUAL` (nvim) at the current line.

`ramble --init-config --config /tmp/ramble.toml` writes the full commented default list to compare against.
