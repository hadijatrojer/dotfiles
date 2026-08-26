# ChatGPT RPM

This Stow module installs `chatgpt-rpm` under `~/.local/bin`. The helper manages
OpenAI's official ChatGPT RPM on Fedora Atomic systems.

```bash
stow chatgpt
chatgpt-rpm install
```

The RPM configures OpenAI's signed package repository. Later system upgrades
update ChatGPT along with the rest of the rpm-ostree deployment:

```bash
chatgpt-rpm update
```

Both operations may stage a deployment that requires a reboot.
