local addonName, DF = ...
DF.BUILD_DATE = "2026-03-20T13:42:15Z"
DF.RELEASE_CHANNEL = "alpha"
DF.CHANGELOG_TEXT = [===[
# DandersFrames Changelog

## [4.1.3] - 2026-03-17

### New Features
* (Aura Designer) **Show When Missing** — per-indicator toggle that inverts visibility: shows the indicator when the aura is absent, hides when present. Supports all indicator types except bars. Icons support a "Desaturate When Missing" sub-option.
* (Aura Designer) **Show When Missing + Expiring** — when both are enabled, the indicator stays hidden while the buff is active, appears during the expiring window, then shows with normal appearance once the buff drops off
* (Auras) **Growth Direction Control** — replaced the single growth dropdown with a three-part control (Orientation, Wrap, Direction) for clearer configuration
* (Aura Designer) **Sound Alerts** — per-indicator sound alerts that play when an aura appears, expires, or is missing. Supports all LibSharedMedia sounds, adjustable volume, loop/one-shot modes, and a global "Mute All Sound Alerts" toggle in the Aura Designer banner. Includes a searchable sound dropdown picker.

### Bug Fixes
* (Raid Frames) **Major fix** for raid frames jumping/shifting position when players join, leave, or when loading into LFR/BGs — completely reworked the reposition pipeline to batch all updates into a single authoritative reposition, with a settling debounce for instance loading
* (Flat Raid Frames) Fixed flat raid frames flickering between party and raid settings during group transitions
* (Flat Raid Frames) Fixed flat raid frame positioning breaking after layout or roster changes
* (Position) Fixed mover handles for both party and raid staying visible after switching group type
* (Auto Layouts) Fixed several issues with switching between flat and grouped layouts — duplicate frames, hidden groups reappearing after combat, and layout not updating after mid-fight settings changes
* (Aura Designer) Fixed grouped layout preview not rendering correctly after the growth direction overhaul — indicators were stacking on top of each other instead of spreading out
* (Aura Designer) Fixed custom border indicators not showing on the frame preview
* (Aura Designer) Fixed indicators appearing on disabled pinned frames
* (Aura Designer) Fixed several Show When Missing visual issues — out-of-range alpha, transparent frames, stale duration text, pulsate animation not stopping, and indicators not appearing in test mode
* (Sound Alerts) Fixed sound engine not finding raid frames when using flat layout
* (Sound Alerts) Sound-only auras now correctly tracked for buff bar dedup
* (Sorting) Fixed secret string taint in cross-realm name caching

### Improvements
* (Debug Console) Added comprehensive debug logging across roster updates, header visibility, flat raid operations, frame positioning, and frame layout — helps diagnose frame issues in the field

## [4.1.2] - 2026-03-16

### New Features
* (Health Text) **Hide % Symbol** — new checkbox to remove the percent sign from health percentage text
* (Pinned Frames) **Growth direction anchoring** — Frame Growth and Column Growth now support Start, Center, and End options, controlling which edge stays fixed as frames are added (e.g. "Start" grows rightward/downward, "End" grows leftward/upward)
* (Pinned Frames) **Reset Position button** — resets a pinned frame set to the center of the screen if it gets lost off-screen

> **Note:** Pinned frame positions may have shifted slightly due to the new anchoring system. Use the Reset Position button or reposition frames if needed.

### Bug Fixes
* (Auras) Fixed buff/debuff borders staying visible even when disabled — operator precedence bug caused the buff border check to fire regardless of aura type
* (Aura Designer) Fixed stack count text bleeding onto adjacent icons when auras reorder in a layout group
* (Defensive Icons) Fixed 2nd+ defensive bar icons always showing tooltip and ignoring tooltip settings, anchor position, and click-through configuration
* (Resource Bar) Fixed resource bar being 2px too wide when "Match Width" is enabled and a frame border is active
* (Status Icons) Fixed leader icon not hiding in combat when "Hide in Combat" is enabled
* (Pinned Frames) Fixed error when OnDragStop fires without a matching OnDragStart on pinned frame movers

## [4.1.1] - 2026-03-15

### Bug Fixes
* (Position) Lowered permanent mover frame strata from HIGH to MEDIUM so it no longer covers other UI elements
* (Defensive Icons) Fixed double-scaled positioning offsets causing defensive icons to stack vertically instead of horizontally
* (Defensive Icons) Reduced raid frame defensive icon defaults (size 20, scale 1.0, max 3) to fit narrower raid frames
* (Pinned Frames) Fixed aura designer indicators (borders, defensives, dispels) leaking onto disabled pinned frame sets
* (Aura Designer) Fixed border indicator pandemic state using the regular border alpha instead of the configured expiring alpha
* (Aura Designer) Declassified Beacon of Virtue as non-secret — spell ID 200025 is on Blizzard's whitelist and readable via standard API

## [4.1.0] - 2026-03-14

### New Features
* (Position) **Permanent Mover handle** — a small always-visible drag handle on frames for repositioning without unlocking, with customizable position, size, offset, colors, show-on-hover with fade animation, hide-in-combat option, and red combat indicator
* (Position) **Permanent Mover quick actions** — left-click, right-click, shift+left-click, and shift+right-click can be bound to 13 preset actions including open settings, quick switch profile/click-cast profile, cycle profiles, toggle test mode, unlock frames, toggle solo mode, ready check, pull timer, reset position, and reload UI
* (Position) **Permanent Mover attach to unit** — handle can be attached to the container, first visible unit, or last visible unit so it follows the group size
* (Position) **Hide drag overlay** checkbox in the unlock panel to hide the blue drag area while keeping frames draggable
* (Dispel Overlay) **Color Name Text** — optional checkbox to color the unit's name text with the dispel type color when a dispellable debuff is present
* (Aura Designer) **Expiring pulsate for icon, square, and health bar indicators** — borders and fills can now pulse when an aura is about to expire
* (Aura Designer) **Expiring whole alpha pulse** — entire icon/square pulses its alpha when expiring
* (Aura Designer) **Expiring bounce animation** — icon/square bounces up and down when expiring
* (Aura Designer) **Hide duration text above threshold** — duration text can be hidden when the remaining time is above a configurable seconds threshold (icon, square, and bar types)
* (Aura Designer) **Expiring threshold in seconds** — expiring indicators can now trigger based on remaining seconds as well as remaining percentage
* (Aura Designer) **Trigger operator (ANY / ALL)** — indicators with multiple trigger spells can now require all triggers to be active (AND mode) or just one (OR mode, default)
* (Aura Designer) **Duration priority (Highest / Lowest)** — expiring indicators on multi-trigger spells can track the highest or lowest remaining duration buff
* (Aura Designer) **Custom border mode** — border indicators can now use an independent overlay per aura, so multiple border indicators can be visible at the same time
* (Aura Designer) **Settings grouped in containers** — all indicator settings panels and global defaults are now organized with bordered section containers
* (Aura Designer) **Earthliving Weapon** added as a trackable Restoration Shaman aura
* (Aura Designer) **Sense Power** added as a trackable Augmentation Evoker secret aura
* (Aura Designer) **Ebon Might self-buff tracking** — Augmentation Evoker's caster self-buff (395296) is now tracked on the player via fingerprint disambiguation, with correct tooltip and buff bar dedup
* (Aura Designer) **Symbiotic Relationship linked aura system** — Restoration Druid's caster buff is detected on the player and mirrored as an indicator onto the target's frame, with OOC target resolution, tooltip-based fallback, recast detection, and buff bar dedup
* (Aura Designer) **Ancestral Vigor** added as a trackable Restoration Shaman aura
* (Aura Blacklist) **Expanded blacklist coverage** — added Rogue poisons, Shaman weapon imbuements, Blessing of the Bronze (all class variants), Paladin rites, Mage Icicles, Hunter Tip of the Spear, and Shaman Reincarnation
* (Debug) **Script Runner** — multiline Lua script input in the debug console with persistent text across sessions

### Bug Fixes
* (Position) Fixed nudge buttons causing the blue drag area to vanish
* (Auras) **Fixed taint errors from secret value comparisons** — duration hide, expiring indicators, and color curves now correctly pipe secret values through secret-aware APIs only

## [4.0.16] - 2026-03-11

### Bug Fixes
* (Click Casting) **Fixed binding tooltip vanishing when pressing modifier keys** — modifier format mismatch caused all bindings to be filtered out
* (Pet Frames) Fixed taint error from secret boolean in pet range checking
* (Fading) **Fixed name and health text alpha resetting to 1.0** on zone change, combat res, vehicle exit, and test mode exit
* (Aura Designer) **Fixed secret auras not appearing immediately on cast in combat** — inline fingerprint matching eliminates race condition between detection and rendering
* (Aura Designer) Fixed Verdant Embrace tooltip incorrectly showing Upheaval

### New Features
* (Aura Designer) **Secret aura tracking** — tracks auras that WoW hides behind secret spell IDs using signature-based fingerprinting (credit to Harrek for the technique and aura data from Advanced Raid Frames)
* (Aura Blacklist) **Combat / out-of-combat controls** — per-spell checkboxes to blacklist auras only in combat, only out of combat, or both
* (Aura Blacklist) Redesigned blacklist UI as a single unified spell list with inline toggle and checkboxes

### New Trackable Auras (Aura Designer)
* **Preservation Evoker:** Time Dilation, Rewind, Verdant Embrace
* **Restoration Druid:** Ironbark
* **Discipline Priest:** Pain Suppression, Power Infusion
* **Holy Priest:** Guardian Spirit, Power Infusion
* **Mistweaver Monk:** Life Cocoon, Strength of the Black Ox
* **Restoration Shaman:** Hydrobubble
* **Holy Paladin:** Blessing of Protection, Holy Armaments, Blessing of Sacrifice, Blessing of Freedom, Dawnlight, Beacon of Virtue

### Improvements
* (Aura Designer) Spell cards now show WoW spell tooltips on hover
* (Aura Designer) Secret auras shown in a distinct section with visual styling to differentiate from regular auras
* (Aura Designer) Added "unsupported spec" message when viewing a non-healer spec
* (Aura Designer) **Class color border** on preview frame window showing the current spec's class
* (Aura Designer) **Class-colored spec dropdown** — each spec name colored by class for clarity
* (Aura Designer) **Customise button** on layout group members — jumps directly to that aura's effects settings
* (Aura Designer) Fixed page scrolling — only the right settings panel scrolls now, preview stays in view
* (Auras) Added **Raid In Combat** debuff filter option — matches the existing buff filter for better debuff coverage
* (Click Casting) Renamed "Mouseover" fallback to "Global" for clarity
* (Click Casting) "Does not work with action bar binds" warning now highlighted in red

## [4.0.15] - 2026-03-10

### Bug Fixes
* (Fading) **Fixed combat stutter when leaving combat**
* (Fading) **Fixed false out-of-range on units that were actually in range**
* (Fading) **Fixed everyone always showing as in-range** — re-added polling timer as a safety net alongside event-driven updates
* (Fading) **Fixed player frame being affected by out-of-range fading**
* (Aura Designer) **Fixed indicators ignoring their configured alpha**
* (Pet Frames) Fixed taint error when pet frame style changes during combat
* (Aura Blacklist) Fixed Harrier's Exhaustion not being filterable
* (Click Casting) Fixed binding tooltip showing wrong modifier
* (Aura Designer) Fixed health text showing in indicator preview when disabled

### New Features
* (Fading) **Hybrid range checking** — range now uses both instant events and a configurable polling timer for maximum reliability
* (Fading) **Missing health bar out-of-range alpha** — new element-specific alpha slider for the missing health (damage) portion of the health bar

## [4.0.14] - 2026-03-08

### Bug Fixes
* (Fading) **Fixed power/resource bar not fading when out of range**
* (Fading) **Fixed name text and health text not fading when out of range or dead/offline** in element-specific alpha mode
* (Fading) **Fixed debuff borders staying visible when faded**
* (Fading) Fixed defensive icons not fading when using Direct API mode with multiple defensives
* (Fading) Fixed name text flickering or staying at full alpha after switching specs
* (Fading) Fixed range checking not updating after changing talents
* (Missing Buff) Fixed missing buff indicator incorrectly showing on NPC followers in follower dungeons
* (API) Fixed external API functions not returning arena frames — `GetFrameForUnit()`, `GetAllFrames()`, and `IterateFrames()` now work correctly inside arenas
* (Side Menu) Improved hiding of Blizzard's raid/party side menu when disabled in settings
* (Raid Frames) **Fixed hidden groups reappearing on roster changes**
* (Raid Frames) **Fixed frames snapping to random positions on roster changes**
* (Raid Frames) **Fixed group order resetting on roster changes**
* (PvP) **Fixed health bars showing 100% in Battlegrounds**
* (PvP) Fixed self-healing cooldown not resetting on zone transitions
* (Test Mode) Fixed group visibility setting not applying in raid test mode
* (Test Mode) Fixed custom group display order not applying in raid test mode
* (Test Mode) Fixed "Columns Grow From" and "Reverse Order" dropdowns not updating flat raid test frames
* (Test Mode) Fixed layout settings not refreshing test frames when changed

### New Features
* (Range) **Range check fallback** — added a fallback for classes without friendly range check spells so out-of-range fading now works for all classes
* (Aura Designer) **Strata and frame level controls** — indicators can now be placed on different frame strata with a configurable default frame level
* (Test Mode) **Aura Designer support in test mode** — Aura Designer indicators now render on test frames
* (Aura Designer) **Out of range alpha** — new element-specific alpha slider for Aura Designer indicators (icons, squares, bars)

### Improvements
* (Test Mode) Redesigned test mode panel with collapsible sections, active count badges, and settings page quick-links

## [4.0.13] - 2026-03-08

### Bug Fixes
* (Click Casting) **Fixed keyboard click-cast bindings randomly stopping mid-hover** — keyboard-bound spells would sometimes stop working until the mouse left and re-entered the frame
* (Click Casting) Fixed spell transform procs (e.g. Flash of Light → Benediction) causing "Spell not Learned" errors
* (Click Casting) Fixed left-click casting randomly failing on some party/raid frames
* (Aura Blacklist) Fixed class dropdown overlapping text and not updating when selecting a different class
* (Auto Layouts) Fixed Aura Designer changes not saving when editing an auto layout a second time
* (Aura Designer) Fixed override indicators incorrectly appearing on internal proxy settings
* (Aura Designer) Fixed crash caused by corrupted saved data
* (Aura Designer) Fixed crash when swapping to a profile without Aura Designer settings

### Improvements
* (Missing Buff Icon) **Missing buff icons now work in combat** — previously they would disappear when entering combat
* (Missing Buff Icon) Added support for talent variant spell IDs (Mark of the Wild, Arcane Intellect)
* (Missing Buff Icon) Improved Blessing of the Bronze detection to cover all Evoker variants
* (Debug Console) Export now respects current severity and category filters
* (Aura Designer) Increased all X/Y offset slider ranges to -150 to 150
* (Aura Designer) Grouped layout spacing slider now allows negative values for overlapping indicators
* (Aura Designer) Added "Reset to Global" button when editing auto layout overrides
* (Aura Designer) Editing banner no longer overlaps page controls

## [4.0.12] - 2026-03-06

### New Features
* **Multi-trigger frame effects** (Aura Designer) — a single frame effect (border, health bar color, etc.) can now trigger on any of multiple auras (e.g. show a border if Rejuvenation OR Regrowth OR Lifebloom is active)
* **Layout groups** (Aura Designer) — group placed indicators at a shared anchor with automatic flow positioning; when an aura is inactive, grouped indicators collapse without gaps
* **Spec-scoped aura configs** (Aura Designer) — configurations are now saved per-spec, so shared buffs like Prayer of Mending can have different indicator setups on each spec
* **Preview click-to-select** (Aura Designer) — left-click any indicator on the frame preview to jump to its settings; right-click to remove it
* **Duration and Stack text color** (Aura Designer) — new color pickers with alpha for duration text and stack text on icon and square indicators, available as both global defaults and per-indicator overrides
* **Hide Icon (Text Only)** (Aura Designer) — new checkbox on icon and square indicators that hides the icon visual while keeping duration and stack text visible
* **Cancel Targeting option** (Click Casting) — new per-binding checkbox in advanced settings that adds /stopspelltarget to the macro, preventing the blue targeting hand on certain spells. Disabled by default so spells like Rescue work correctly

### Bug Fixes
* (Frames) Fixed buff/debuff/defensive tooltips not showing when hovering aura icons
* (Frames) Fixed defensive bar icons not receiving hover events for tooltips
* (Frames) Fixed aura icons created during combat permanently losing tooltip hover after combat ends
* (Click Casting) Fixed smart resurrection not working on non-English WoW clients
* (Click Casting) Fixed click-casting "Spell not Learned" errors after talent changes
* (Click Casting) Fixed all click-casting bindings failing on non-English WoW clients

## [4.0.11] - 2026-03-03

### Bug Fixes
* Fixed target/focus/aggro highlights not showing on arena frames
* Fixed Aura Designer stack count font and outline settings not applying
* Fixed buff/debuff tooltips permanently breaking after combat until reload
* Fixed empty Buff Filters, Debuff Filters, and Defensives group containers showing when using Blizzard (default) aura mode
* Fixed Aura Designer health bar color overlay not restoring the correct color when the tracked buff expires
* Fixed Aura Designer health bar color overlay not matching the health bar texture
* Fixed Aura Designer health bar color not restoring correctly on login when a buff is already active
* Fixed party frames showing empty when loading into a follower dungeon
* Fixed Beacon of Virtue not available in the Aura Designer — it can now be configured with its own independent indicators
* Fixed Aura Designer spell icons changing when talent choice nodes replace a spell (e.g. Beacon of Light showing Beacon of Virtue's icon)

### Improvements
* Improved click-casting debug logging to help diagnose intermittent binding failures
* Added horizontal scrollbars to Aura Designer trackable auras and active effects strips

## [4.0.10] - 2026-03-02

### Bug Fixes
* Fixed addon managers (Wago, CurseForge) constantly prompting for updates due to stale version in TOC file — version is now updated as part of every release
* Fixed Aura Designer tracking buffs from other players instead of only your own casts

### New Features
* **Auto layout Copy To** — duplicate an auto layout (with all overrides) to any content type section, including same-section copying for different size ranges
* **Only My Buffs filter** — new toggle in Direct API buff filters that restricts all buff filters to player-cast buffs only (enabled by default); removes the now-redundant My Buffs sub-filter

## [4.0.9] - 2026-03-02

### Bug Fixes
* Fixed imported and duplicated profiles resetting to Default on reload/relog due to per-character SavedVariable not being synced

### New Features
* **Direct API buff filters** — added Not Cancelable, Big Defensives, and External Defensives as toggleable filter options
* **Additive filter logic** — enabled filters now use OR logic so selecting multiple categories shows the union (e.g. Raid In Combat + Big Defensives shows both) instead of requiring auras to match all selected filters
* **Defensive icon scanning** — defensive icon now detects both Big Defensives and External Defensives (e.g. Pain Suppression, Blessing of Sacrifice)
* **Filter tooltips** — hover any filter checkbox to see a description of what that category includes
* **Defensive bar spacing** — icon spacing slider now supports negative values for overlapping icons
* **Updated filter defaults** — buff filters default to Raid In Combat + Big Defensives + External Defensives; debuff filters default to Raid Debuffs + Crowd Control + Important Spells (migrated for existing users)

## [4.0.8] - 2026-03-01

### New: Aura Designer
Visual indicator system for tracking buffs, debuffs, and auras on your frames.
* **8 indicator types** — 3 placed indicators (Icon, Square, Bar) that occupy anchor points on the frame, plus 5 frame effects (Border, Health Bar Color, Name Text Color, Health Text Color, Frame Alpha) that affect the entire frame
* **Drag-to-place** — drag auras from the spell list onto any of 9 anchor points (corners, edges, center) with X/Y offset adjustment
* **Icon indicators** — spell icon with cooldown swipe, duration text, and stack count display
* **Square indicators** — colored square with cooldown swipe, duration text, and stack count
* **Bar indicators** — progress bar showing remaining duration with horizontal/vertical orientation, match-frame-width option, fill color, background color, and bar-color-by-time gradient
* **Border frame effect** — 5 styles: Solid, Animated, Dashed, Glow, and Corners Only with configurable thickness and color
* **Health Bar Color frame effect** — Replace or Tint mode with adjustable blend strength
* **Name/Health Text Color frame effects** — override unit name or health text color when an aura is active
* **Frame Alpha frame effect** — adjust entire frame transparency based on aura presence
* **Expiring system** — all 8 indicator types support an expiring color that activates below a configurable remaining-duration threshold, fully combat-safe
* **Priority stacking** — configurable priority per aura (1-20); frame effects only show the highest-priority active aura, placed indicators coexist on separate anchors
* **Buff coexistence** — standard buff icons can display alongside Aura Designer indicators, with a popup to choose when enabling AD
* **Global defaults** — configure default icon size, scale, duration/stack font, font scale, and outline style; new indicators inherit these automatically with per-indicator overrides available
* **Live preview** — indicators render on the frame preview in the options panel with adjustable zoom (0.75×–2.5×)
* **Per-spec aura lists** — curated aura lists for 8 healer and augmentation specs, auto-refreshes when switching specs

### New: Auto Layouts (Raid Only)
Automatically switches your raid frame layout based on content type and raid size. Does not apply to party, solo, or arena.
* **Three content categories** — Instanced/PvP (raids, dungeons, battlegrounds), Mythic (fixed 20-player), and Open World (world bosses, outdoor groups)
* **Per-size-range profiles** — create multiple layouts per content type, each covering a custom player range (e.g., 1-10, 11-20, 21-40). Mythic is a single fixed layout for 20 players
* **Automatic switching** — monitors group roster, zone changes, and instance type; applies the matching layout on-the-fly when content or raid size changes
* **Override-only storage** — each layout stores only the settings that differ from your global profile; everything else is inherited automatically
* **Full settings coverage** — overrides can include frame size, growth direction, groups per row, group visibility, bar colors, text settings, aura filters, icon toggles, pinned frame configuration, and more
* **Live editing** — click "Edit Settings" to enter editing mode with live frame preview; every change is tracked as an override with visual indicators showing which settings are modified vs global
* **Override indicators** — green checkmark for global values, orange star with reset button for modified values, per-tab override counts
* **Non-destructive** — your global profile is never modified; exiting editing mode restores your base settings cleanly
* **Crash recovery** — if editing is interrupted, the next login detects and restores your base settings
* **Status display** — shows current content type, instance name, raid size, active layout, and override count
* **Export/import support** — auto layout configurations included in profile exports

### New: Aura System Improvements
* **Direct Aura mode** — optional mode that gives full control over which buffs and debuffs appear using filter categories (Player, Raid, Big Defensive, etc.). Configure in Auras > Aura Filters
* **All Buffs / All Debuffs toggles** — master toggles to quickly show all buffs or all debuffs without configuring individual filters
* **Important Spells filter** — checkbox to show Blizzard's curated list of important buffs and debuffs
* **Buff deduplication** — buffs already displayed by the Defensive Bar or Aura Designer are automatically hidden from the buff bar. Enabled by default, toggle in Buffs tab
* **Multi-defensive icons** — Defensive Bar now shows all active big defensives simultaneously (up to configured max), not just one
* **Defensive bar compound growth** — growth direction now supports two-axis layouts (e.g., RIGHT_DOWN, LEFT_UP) with configurable wrap count
* Max buff and debuff icon count increased from 5 to 8

### New Features
* Health fade system — fades frames above a configurable health threshold, with option to cancel fade when a dispellable debuff is active (contributed by X-Steeve)
* Class power pips — Holy Power, Chi, Combo Points, etc. displayed on the player frame as colored pips with configurable size, position, anchor, color, vertical layout, and role filter options (contributed by X-Steeve)
* "Sync with Raid/Party" toggle per settings page (contributed by Enf0)
* Per-class resource bar filter toggles
* Click-cast binding tooltip on unit frame hover — shows active bindings with usability status (contributed by riyuk)
* Health gradient color mode for missing health bar (contributed by Enf0)
* Click-cast binding tooltip moved to main Tooltip settings with full anchor and position controls
* Debug Console — in-game debug log viewer (`/df debug` to toggle, `/df console` to view)

### Bug Fixes
* Fix click-casting "script ran too long" error when many frames are registered (ElvUI, etc.)
* Fix health fade errors caused by Blizzard's protected health values
* Fix health fade not working correctly on pet frames, in test mode, and during health animation
* Fix profiles not persisting per character — each character now remembers their own active profile
* Fix pet frames vanishing after reload
* Fix pet frame font crash on non-English clients
* Fix party frame container not repositioning when dragging width or height sliders
* Fix resource bar border, color, and width issues after login/reload/resize
* Fix heal absorb bar showing smaller than actual absorb amount
* Fix absorb bar not fading when unit is out of range
* Fix name text truncation not applied to offline players
* Fix summon icon permanently stuck on frames after M+ start or group leave
* Fix icon alpha settings (role, leader, raid target, ready check) reverting to 100% after releasing slider
* Fix click-casting not working when clicking on aura/defensive icons
* Fix click-casting "Spell not learned" when queuing as different spec
* Fix DF click-casting not working until reload when first enabled
* Fix Clique compatibility — prevent duplicate registration, defer writes, commit all header children
* Fix aura click-through not updating safely on login
* Fix leader icon not updating on first leader change (contributed by riyuk)
* Fix Lua errors during Blizzard frame registration (contributed by riyuk)
* Fix missing raid groups when reloading UI during combat
* Fix duration text showing on permanent buffs
* Fix defensive icons showing stale data after entering/exiting vehicles
* Fix unit name getting stuck to the vehicle name after exiting a vehicle
* Fix follower dungeon only showing 2-3 party members until /reload
* Fix click-casting reload popup appearing on every login when the Clicked conflict warning is set to Ignore
* Fix dispel overlay sometimes treating all debuffs as dispellable
* Fix non-defensive buffs appearing in the Defensive Bar when units are out of range
* Fix raid mover frame (orange anchor) not resizing when frame settings change
* Fix group labels anchoring to the wrong player when sorting is enabled

## [4.0.6] - 2026-02-15

### Bug Fixes
* `/df resetgui` command now works — was referencing wrong frame variable, also shows the GUI after resetting
* Settings UI can now be dragged from the bottom banner in addition to the title bar
* Fix party frame mover (blue rectangle) showing wrong size after switching between profiles with different orientations or frame dimensions
* Fix Wago UI pack imports overwriting previous profiles — importing multiple profiles sequentially no longer corrupts the first imported profile
* Fix error when duplicating a profile

## [4.0.5] - 2026-02-14

### Bug Fixes
* Raid frames misaligned / anchoring broken
* Groups per row setting not working in live raids
* Arena/BG frames showing wrong layout after reload
* Arena health bars not updating after reload
* Leader change causes frames to disappear or misalign
* Menu bind ignores out-of-combat setting
* Boss aura font size defaulting to 200% instead of 100%
* Click casting profiles don't switch on spec change
* Clique not working on pet frames
* Absorb overlay doesn't fade when out of range
* Heal absorb and heal prediction bars don't fade when out of range
* Defensive icon flashes at wrong opacity when appearing
* Name text stays full opacity on out-of-range players
* Health text and status text stay full opacity on out-of-range players
* Name alpha resets after exiting test mode
* Glowy hand cursor after failed click cast spells
* Macro editing window gets stuck open when reopened
* Flat raid unlock mover sized incorrectly
* Fonts broken on non-English client languages

### New Features
* Click casting spec default profile option
* Group visibility options now available in flat raid mode
* Slider edit boxes accept precise decimal values for fine-tuned positioning and scaling
]===]
