# evildUI - Copilot Instructions

## Project Overview

This is **evildUI**, a World of Warcraft addon created by **evild @ Mal'Ganis**.

- **GitHub Repo**: `greenovate/evildui`
- **Interface Version**: 110207 (The War Within)
- **CurseForge Project ID**: 1423379

> **Note**: For detailed release processes, personal paths, and session logs, check the `docs/` directory (gitignored, local only).

## Folder Structure

```
PVPUI/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── workflows/
│   │   └── release.yml        # Auto-publishes to GitHub + CurseForge on tag
│   └── copilot-instructions.md
├── .pkgmeta                   # BigWigs packager config
├── Core/
│   ├── Init.lua               # Addon initialization, event handling, welcome splash
│   ├── Database.lua           # Default settings, DB management
│   ├── Config.lua             # Settings UI panel
│   ├── ActionBars.lua         # Custom action bars, UI scaling
│   ├── UnitFrames.lua         # Unit frame controls
│   ├── Movers.lua             # Frame positioning system
│   ├── Keybinds.lua           # Mouseover keybind system
│   ├── Minimap.lua            # Minimap customization
│   ├── Chat.lua               # Chat frame enhancements
│   ├── DataBars.lua           # XP/Rep/Honor bars
│   ├── Panels.lua             # Custom UI panels
│   ├── Layouts.lua            # Layout save/load/export/import
│   └── Profiles.lua           # Profile management
├── Locales/
│   ├── Locales.lua            # Localization setup
│   └── enUS.lua               # English strings
├── docs/                      # GITIGNORED - local planning, session logs, private notes
├── builds/                    # GITIGNORED - local build output
├── evildui.toc                # Addon manifest
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Release Process

The GitHub Actions workflow (`release.yml`) auto-publishes on tag push:
1. Update version in: `evildui.toc`, `CHANGELOG.md`, `Core/Init.lua` (ShowWelcomeSplash)
2. Commit and tag: `git commit -m "vX.X.X" && git tag vX.X.X && git push origin main --tags`
3. Workflow builds and uploads to GitHub Releases + CurseForge automatically

For manual release process or troubleshooting, see `docs/` directory.

## Development Workflow

Build and test locally:
```bash
# Copy to WoW AddOns folder, then /reload in game
```

Check for errors in-game: `/console scriptErrors 1`

Open settings: `/evildui` or `/edui`

## Code Conventions

### Lua Style
- Use `local` for all variables and functions where possible
- Addon namespace table: `E` (passed via `local addonName, E = ...`)
- SavedVariables: `evilduidb` (account-wide), `evilduichardb` (per-character)
- Use `SecureActionButtonTemplate` for action buttons
- Always check `InCombatLockdown()` before modifying secure frames

### Frame Naming
- Frames: `evildui_FrameName` or `EvilDUI_FrameName`
- Action bars: `EvilDUIActionBar1`, etc.
- Movers: `evildui_Mover_Name`

### Database Structure
```lua
evilduidb = {
    profiles = {
        ["ProfileName"] = {
            general = { uiScale = 1.0, ... },
            actionBars = { ... },
            unitFrames = { ... },
            minimap = { ... },
            chat = { ... },
            dataBars = { ... },
            panels = { ... },
        }
    },
    positions = { ... },        -- Mover positions
    layouts = { ... },          -- Saved layouts
    currentProfile = "Default",
    dbVersion = 4,
}
```

### Config Panel
- Uses custom dark theme (backdrop color: 0.1, 0.1, 0.1)
- Categories on left, settings on right
- Helper functions: `CreateSlider()`, `CreateCheckbox()`, `CreateDropdown()`, `CreateColorPicker()`

## Key Implementation Notes

### UI Scaling
Global scale uses `ScaleFromCenter()` helper in `ActionBars.lua`. Each frame is scaled individually and repositioned so its center stays at the same screen location. Do NOT use container-based scaling (scaling a parent moves children toward center).

### Movers
Movers are invisible anchor frames. Content frames attach via `SetAllPoints(mover)`. Positions saved relative to `UIParent`.

### Combat Lockdown
- Don't modify secure frames in combat
- Use `E:QueueForCombat(func, ...)` to defer changes
- `PLAYER_REGEN_ENABLED` event signals combat end

## Common Issues

### "Taint" errors
- Don't modify secure frames in combat
- Use `InCombatLockdown()` to check

### Action buttons not working
- Must use `SecureActionButtonTemplate`
- Set attributes before combat: `type`, `action`, `spell`, etc.
- Use `SetAttribute()` not direct table assignment

### Frame strata/layering
- BACKGROUND < LOW < MEDIUM < HIGH < DIALOG < FULLSCREEN < FULLSCREEN_DIALOG < TOOLTIP
- Use `SetFrameStrata()` and `SetFrameLevel()`

## Testing

1. Make changes in development folder
2. Build/copy to WoW AddOns folder
3. `/reload` in WoW
4. Check for lua errors: `/console scriptErrors 1`
5. Type `/evildui` to open settings
