# Agent Skills

Shared agent skills following the [Agent Skills standard](https://agentskills.io).

## Distribution

Two paths:

- **Universal path (Codex, OpenCode, Pi, Cursor, Amp, Cline, Warp, OpenClaw, generic):** `./dotfiles-sync --apply` symlinks each `<name>/` into `~/.agents/skills/<name>`. All these agents read that path natively. Edits propagate live (symlink, not copy).
- **Claude Code:** the same `skills/` tree is bundled into the dotfiles Claude plugin. Install via `claude plugin marketplace add martintrojer/dotfiles && claude plugin install mtrojer@dotfiles`. Re-run `claude plugin install mtrojer@dotfiles` after each push to refresh — `./dotfiles-sync --apply` prints these commands as a closing hint.

Skills are auto-discovered and can be invoked explicitly with `/skill:name` or loaded automatically when the agent detects a matching task.

## Skills

> `avoid-ai-writing` is vendored from
> [conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing)
> (MIT, v3.10.0 @ `6e1369d`) — `SKILL.md` plus the zero-dependency `detector/`
> engine (`node detector/patterns.js`).
> Keep edits to vendored skills minimal so they stay easy to re-sync against upstream.

### Writing

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/skill:avoid-ai-writing` | "remove AI-isms", "clean up AI writing", "make this sound less like AI" | Audit/rewrite text to strip AI writing patterns. Detect, rewrite, and edit-in-place modes; optional voice profiles; bundled deterministic `detector/patterns.js` |

### Multi-Agent

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/skill:council` | "council", "debate", "weigh options" | Multi-agent collaborative-adversarial debate with visible transcripts |
