# Fork Changes

[Compare upstream and fork](https://github.com/DanderBot/DandersFrames/compare/main...andybergon:DandersFrames:main)

All changes made in this fork (`andybergon/DandersFrames`) relative to upstream (`DanderBot/DandersFrames`).

| Feature | Status | Upstream | Fork | Notes |
|---------|--------|----------|------|-------|
| Fix deficit abbreviation | Pending Upstream | [PR #22](https://github.com/DanderBot/DandersFrames/pull/22) (2026-03-18) | `fix/deficit-abbreviation` branch | `C_StringUtil` always wins over `AbbreviateNumbers` in DEFICIT mode |
| [Fix aura click-through in combat](#fix-aura-click-through-in-combat) | Fork-only | — | `main` | Guard protected mouse APIs with `InCombatLockdown()`; remove redundant `fixIconMouse` |

This file and `CLAUDE.md` are also fork-only (project docs for Claude Code).

---

### Fix aura click-through in combat

**Problem:** Aura icons on unit frames were blocking clicks from reaching the parent frame, breaking click-casting on frames with visible buffs/debuffs. The upstream code used `EnableMouse(false)` on icons to make them click-through, but this also killed tooltips — you couldn't hover an aura to see what it was.

**Root cause:** The upstream approach toggled `EnableMouse()` on aura icons, which is an all-or-nothing switch: either the icon consumes all mouse events (blocking click-casts on the parent) or it ignores them all (no tooltips). There's also a `fixIconMouse` system that tried to re-apply mouse state after combat via `PLAYER_REGEN_ENABLED`, but it was redundant and fragile.

**Fix:** Replace `EnableMouse(false)` with the 10.0.2+ mouse propagation APIs:
- `SetPropagateMouseMotion(true)` — hover events pass through to parent (click-cast targeting works)
- `SetPropagateMouseClicks(true)` — click events pass through to parent (click-cast bindings work)
- `SetMouseClickEnabled(false)` — icon itself doesn't consume clicks

This gives us both: tooltips on hover AND click-through to the parent frame for bindings. Grid2 uses the same approach (`IndicatorMidnightTooltip.lua:EnableFrameTooltips`).

**Key gotcha:** `SetPropagateMouseMotion()` and `SetPropagateMouseClicks()` are **protected functions** — calling them during combat triggers `ADDON_ACTION_BLOCKED`. All call sites are guarded with `InCombatLockdown()`. Icons created before combat keep their full mouse setup (tooltips + click-through) throughout combat. Icons created *during* combat (rare — only when a brand new icon slot is needed for the first time) are click-through but won't show tooltips until combat ends, when `PLAYER_REGEN_ENABLED` → `UpdateAllAuras` applies the full setup. `SetMouseClickEnabled()` is NOT protected and works anytime.

**Files changed:** `Frames/Create.lua`, `Frames/Icons.lua`, `Frames/Update.lua`, `AuraDesigner/Indicators.lua`, `Core.lua` (removed `fixIconMouse`).
