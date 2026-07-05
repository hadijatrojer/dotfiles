# pi

Extensions for the [pi coding agent](https://buildwithpi.ai/).

Stowing this package symlinks each `*.ts` into `~/.pi/agent/extensions/`, where
pi auto-discovers extensions (with `/reload` support) — no manifest, no
`pi install`. Edits propagate live through the symlink.

Helper modules are top-level `*.ts` files with a safe default export (for
example `_lib.ts`), because pi may auto-load every top-level file while other
extensions import from it.

Several extensions originate from
[martintrojer/dotfiles](https://github.com/martintrojer/dotfiles), in turn
adapted from [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff).

## Extensions

- `_lib.ts` — shared helpers (fast-model fallback, transcript helpers, loop/watch
  command registration). No-op default export.
- `/loop` — re-send a prompt on a recurring interval within the session.
- `/watch` — like `/loop`, but only fires when a probe command's output changes.
- `/goal` — take turns autonomously until a checker model confirms a verifiable
  end condition.
- `/btw` — no-tools side thread with full session context that never pollutes
  main history.
- `/answer` (`Ctrl+.`) — walk through the agent's questions in a modal and send
  compiled answers back as one message.
- `/namesession` — generate a short `/resume` title with a small/fast model.
- `brave_search` — Brave LLM Context tools (`brave_search`, `brave_news_search`,
  `brave_image_search`, `brave_video_search`). Set `BRAVE_SEARCH_API_KEY` in the
  shell profile before starting pi.
- `modelbridge` — register models served by a local ModelBridge instance
  (`MODELBRIDGE_BASE_URL`, `MODELBRIDGE_API_KEY`).

`agent-attention` (tmux status signaling) is intentionally not vendored here
because this setup has no tmux module.
