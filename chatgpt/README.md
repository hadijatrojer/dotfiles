# ChatGPT RPM

This Fedora Stow module installs `chatgpt-rpm` under `~/.local/bin`. It is
included automatically by the repository-level Stow helper:

```bash
./stow-all.py --apply
chatgpt-rpm install
```

`chatgpt-rpm install` downloads OpenAI's current x64 RPM, checks its signing-key
ID, and stages it with `rpm-ostree`. If a local ChatGPT RPM is already layered,
the helper atomically replaces that package request with the downloaded version.
`chatgpt-rpm status` reports the current deployment and package.

The RPM configures OpenAI's signed package repository. Ongoing updates belong
to the repository's general maintenance command:

```bash
./stow-all.py --update
```

That command reapplies all relevant Stow packages, refreshes pinned plugins,
and runs `sudo rpm-ostree upgrade`, updating ChatGPT with the rest of the Fedora
Atomic deployment. Installation and updates may require a reboot.
