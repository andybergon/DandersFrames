# Fork Changes

[Compare upstream and fork](https://github.com/DanderBot/DandersFrames/compare/main...andybergon:DandersFrames:main)

All changes made in this fork (`andybergon/DandersFrames`) relative to upstream (`DanderBot/DandersFrames`).

| Feature | Status | Upstream | Fork | Notes |
|---------|--------|----------|------|-------|
| Fix deficit abbreviation | Pending Upstream | [PR #22](https://github.com/DanderBot/DandersFrames/pull/22) (2026-03-18) | `fix/deficit-abbreviation` branch | `C_StringUtil` always wins over `AbbreviateNumbers` in DEFICIT mode |
| Fix aura click-through in combat | Brought Upstream | v4.1.9-alpha.1 (2026-03-27) | — | Upstream implemented full fix independently via configure-once pattern + pre-warm |
| Show macrotext in /dfccglobal debug | Fork-only | — | [`eed101f`](https://github.com/andybergon/DandersFrames/commit/eed101f) (2026-03-27) | Prints `macrotext` attributes in click-cast debug output |

This file and `CLAUDE.md` are also fork-only (project docs for Claude Code).
