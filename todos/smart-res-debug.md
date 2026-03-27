# Smart Res Not Working — Debug Guide

## Problem
User (Mistweaver Monk) reports clicking a dead party member's frame with a heal binding tried to cast the heal instead of the res spell.

## Current State (2026-03-27)
- Smart Res is enabled: mode = "normal" (Res + Mass)
- Spells detected: Resuscitate (normal), Reawaken (mass), no combat res
- Macro IS being generated with smart res line:
  ```
  /cast [@mouseover,help,exists,dead,nocombat] Resuscitate; [@mouseover,exists,nodead] Vivify
  ```
- So the feature appears to be wired up correctly. Needs retesting with a dead target.

## Known Issue: Mass Res Timing Bug
- The macro uses `Resuscitate` (single) instead of `Reawaken` (mass) despite both being available
- Likely cause: `C_SpellBook.IsSpellInSpellBook` returns false for Reawaken when bindings are first built on login (spellbook not fully loaded yet)
- `/dfccglobal smartres` run later shows both spells available — confirms timing issue
- Potential fix: listen for `SPELLS_CHANGED` event and rebuild macro map

## Debug Commands
1. `/dfccglobal smartres` — shows current mode, detected res spells, and sample macro parts
2. `/dfccglobal bindings` — hover over a DF frame first, shows frame attributes including macrotext (we added macrotext printing)
3. `/dfccglobal apply` — force reapply all bindings
4. `/dfccres` — shows resurrection spell detection and existing res bindings
5. `/dfccglobal debug` — toggle debug output, then `/reload` to see all macros printed at build time

## Debug Steps for Next Test
1. `/reload` to ensure fresh binding build
2. `/dfccglobal smartres` to verify spells detected (check if Reawaken shows up)
3. Hover over a DF party frame, `/dfccglobal bindings` to verify macrotext contains the res line
4. Find/create a dead party member (dungeon, test mode, etc.)
5. Click the dead player's frame with the heal binding (e.g. Right Click for Vivify)
6. Observe: does it cast Resuscitate/Reawaken or Vivify?
7. If it casts the heal: the macro conditions aren't matching. Check if `help`, `exists`, `dead`, `nocombat` all apply to the dead unit.

## Code References
- `GetSmartResurrectionParts()` — `ClickCasting/Bindings.lua:1829`
- `GetPlayerResurrectionSpells()` — `ClickCasting/Bindings.lua:1727`
- `BuildMacroTextForBinding()` smart res injection — `ClickCasting/Bindings.lua:1975-1984`
- `BuildCombinedMacroForBindings()` smart res injection — `ClickCasting/Bindings.lua:2188-2207`
- Smart Res dropdown UI — `ClickCasting/UI/Main.lua:437-591`
- Debug command handler — `ClickCasting/UI/Dialogs.lua:2634-2659`

## Changes Made This Session
- Added macrotext printing to `/dfccglobal bindings` debug output (`ClickCasting/UI/Dialogs.lua:2564-2567`)
