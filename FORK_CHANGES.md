# Fork Changes

[Compare upstream and fork](https://github.com/DanderBot/DandersFrames/compare/main...andybergon:DandersFrames:main)

All changes made in this fork (`andybergon/DandersFrames`) relative to upstream (`DanderBot/DandersFrames`).

| Feature | Status | Upstream | Fork | Notes |
|---------|--------|----------|------|-------|
| Fix deficit abbreviation | Pending Upstream | [PR #22](https://github.com/DanderBot/DandersFrames/pull/22) (2026-03-18) | `fix/deficit-abbreviation` branch | `C_StringUtil` always wins over `AbbreviateNumbers` in DEFICIT mode |
| [Fix aura click-through in combat](#fix-aura-click-through-in-combat) | Partially Upstream | v4.1.8 (2026-03-26) | `main` | Upstream adopted the approach but our fork has refinements (see detail section) |
| Show macrotext in /dfccglobal debug | Fork-only | — | [`78fbb07`](https://github.com/andybergon/DandersFrames/commit/78fbb07) (2026-03-27) | Prints `macrotext` attributes in click-cast debug output |

This file and `CLAUDE.md` are also fork-only (project docs for Claude Code).

---

### Fix aura click-through in combat

**Problem:** Aura icons on unit frames were blocking clicks from reaching the parent frame, breaking click-casting on frames with visible buffs/debuffs.

**Upstream status (v4.1.8):** Upstream independently adopted the same propagation API approach (`SetPropagateMouseMotion`, `SetPropagateMouseClicks`, `SetMouseClickEnabled`), guarded by `InCombatLockdown()`. Our fork still carries three refinements:

1. **`SetMouseClickEnabled(false)` outside combat guard** — This API is NOT protected (10.0.2+), so it works during combat. Upstream incorrectly puts it inside the `InCombatLockdown()` block, meaning icons created during combat don't get click-through until combat ends. Our fork calls it unconditionally.

2. **Removed `fixIconMouse` from Core.lua** — Upstream still has a 39-line `fixIconMouse` function in `PLAYER_REGEN_ENABLED` that re-applies mouse settings after combat. Our fork removes this because `UpdateAllAuras` already handles it, and the function is redundant when `SetMouseClickEnabled` is called unconditionally.

3. **`InCombatLockdown()` early return in `UpdateAuraClickThrough`** — Guards `Frames/Icons.lua:UpdateAuraClickThrough()` to prevent taint from protected calls during combat.

**Files changed:** `Frames/Create.lua`, `Frames/Icons.lua`, `Frames/Update.lua`, `AuraDesigner/Indicators.lua`, `Core.lua`.
