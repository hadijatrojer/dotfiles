---
name: gws-modelarmor
description: "Google Model Armor: Filter user-generated content for safety."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws modelarmor --help"
---

# modelarmor (v1)

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

```bash
gws modelarmor <resource> <method> [flags]
```

## Discovering Commands

Before calling any API method, inspect it:

```bash
# Browse resources and methods
gws modelarmor --help

# Inspect a method's required params, types, and defaults
gws schema modelarmor.<resource>.<method>
```

Use `gws schema` output to build your `--params` and `--json` flags.

