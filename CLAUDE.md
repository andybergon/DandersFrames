# DandersFrames - Custom Party/Raid Frames for WoW

Customizable party and raid frame addon for World of Warcraft: Midnight (12.0). External repo owned by DanderBot. We contribute via fork.

## Git Workflow (Fork + PR)

- `origin` = `andybergon/DandersFrames` (our fork, full push access)
- `upstream` = `DanderBot/DandersFrames` (upstream, read-only)

**Development happens on `main`.** Push freely to `origin/main` -- it's our fork.

### Opening a PR to upstream

Each PR branch must contain **only the commits for that feature** -- never include unrelated commits from our `main` (like CLAUDE.md or other features).

1. Fetch upstream: `git fetch upstream`
2. Create a branch off **upstream's** main: `git checkout -b feat/my-feature upstream/main`
3. Cherry-pick only the relevant commit(s) from main: `git cherry-pick <hash>`
4. Push the branch to our fork: `git push -u origin feat/my-feature`
5. Open PR: `gh pr create --repo DanderBot/DandersFrames --head andybergon:feat/my-feature --base main`

**Never push `main` directly to a PR branch** -- `main` has fork-only commits (CLAUDE.md, etc.) that shouldn't go upstream.

### Syncing with upstream

Use `/fork-sync` skill. Rebase rewrites fork commit hashes, so push requires `--force-with-lease`.

## Parallel Feature Development (Worktrees)

Multiple features can be developed in parallel using `claude -w <branch>`. Each session gets its own worktree and works independently without interfering with other sessions.

**Am I on `main` or in a worktree?** Check the current working directory -- worktrees live under `.claude/worktrees/` inside the repo. If you're in the primary repo root, you're on `main`.

**Only one branch can be tested at a time** if the repo uses a symlink/junction for live loading. Re-point the link to the worktree you want to test.

## Fork Changes Tracking

All fork changes are tracked in [`FORK_CHANGES.md`](FORK_CHANGES.md). **Always update it as part of every commit** — not as an afterthought. Include it in the same commit.

## PR Conventions

This is an external repo -- always preview PR title/body for user review before submitting. Keep tone casual and human.

## Project Structure

- **Language:** Lua (WoW addon)
- **Build/Package:** `.pkgmeta` for CurseForge/Wago packaging
- **TOC:** `DandersFrames.toc` - load order and metadata (Interface 120000/120001)
- **SavedVariables:** `DandersFramesDB_v2`, `DandersFramesClickCastingDB`, `DandersFramesCharDB`

### Key Files

- `Core.lua` - Main addon logic (~206K, largest file)
- `Config.lua` - Configuration/defaults (~108K)
- `Popup.lua` - Popup wizard system (v4.1.8+)
- `WizardBuilder.lua` - Wizard builder framework (v4.1.8+)
- `Profile.lua` - Profile import/export
- `API.lua` - External API for Wago UI Packs etc.
- `DandersFrames.xml` - XML frame templates

### Modules

| Directory | Purpose |
|-----------|---------|
| `Frames/` | Frame creation, updating, positioning, colors, bars, icons |
| `Features/` | Auras, dispel, highlights, range, health fade, sort, targeted spells |
| `AuraDesigner/` | Aura configuration UI and engine |
| `AuraBlacklist/` | Aura filtering |
| `ClickCasting/` | Click-cast binding system with UI |
| `GUI/` | Shared GUI components (icon lib, color picker) |
| `Options/` | Settings panels, auto-profiles |
| `TestMode/` | In-game test mode for configuration |
| `Debug/` | Debug console, aura debugging, profiler, atlas browser |
| `Libs/` | Bundled libraries (LibStub, Ace, LibDBIcon, etc.) |
| `Media/` | Textures, fonts, icons |

## Syntax Check

```bash
find . -name '*.lua' -not -path './.git/*' -not -path './.claude/*' -not -path './Libs/*' -exec luac -p {} +
```

**Known false positive:** `Features/Search.lua` has a UTF-8 BOM (upstream) that `luac -p` reports as a syntax error. WoW's Lua engine handles BOMs fine — ignore this.
