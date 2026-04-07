# Fork Changes

[Compare upstream and fork](https://github.com/DanderBot/DandersFrames/compare/main...andybergon:DandersFrames:main)

All changes made in this fork (`andybergon/DandersFrames`) relative to upstream (`DanderBot/DandersFrames`).

| Feature | Status | Upstream | Fork | Notes |
|---------|--------|----------|------|-------|
| Fix deficit abbreviation | Brought Upstream | [PR #22](https://github.com/DanderBot/DandersFrames/pull/22) — merged 2026-04-03 | — | Our PR merged via `8a6fe74` along with PR #29 |
| Fix aura click-through in combat | Brought Upstream | v4.1.9-alpha.1 (2026-03-27) | — | Upstream implemented full fix independently via configure-once pattern + pre-warm |
| Show macrotext in /dfccglobal debug | Fork-only | — | [`1708127`](https://github.com/andybergon/DandersFrames/commit/1708127) (2026-03-27) | Prints `macrotext` attributes in click-cast debug output |

## Upstream highlights since last sync (v4.1.10 → v4.2.5-alpha.1)

Major upstream changes pulled in this final sync (59 commits, 2026-04-03 to 2026-04-06):
- **Full localization system** — AceLocale-3.0, CurseForge auto-upload, all UI strings localized
- **Debug console redesign** — collapsible category sections, per-category logging gates, RAIDPOS diagnostics
- **Bug fixes** — click casting on pinned frames, dispel overlay "All Dispellable" mode, health bar darkening from non-dispellable debuffs, raid group CENTER alignment positioning

This file and `CLAUDE.md` are also fork-only (project docs for Claude Code).
