# evildUI - Copilot Instructions

## Project Overview

This is **evildUI**, a World of Warcraft addon created by **evild @ Mal'Ganis**.

- **GitHub Repo**: `greenovate/evildui`
- **Development folder**: `/Users/evilaptop/Documents/codework/Wow_Addons/PVPUI`
- **Live addon folder**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/evildui`
- **Interface Version**: 110207 (The War Within)

## Folder Structure

The development folder is named `PVPUI` but the addon is packaged/released as `evildui`.

```
PVPUI/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── workflows/
│       └── release.yml (DO NOT USE - broken, use manual process below)
├── Core/
│   ├── Init.lua          # Addon initialization, event handling
│   ├── Database.lua      # Default settings, DB management
│   ├── Config.lua        # Settings UI panel
│   ├── ActionBars.lua    # Custom action bars
│   ├── UnitFrames.lua    # Unit frame controls
│   ├── Movers.lua        # Frame positioning system
│   ├── Keybinds.lua      # Mouseover keybind system
│   ├── Minimap.lua       # Minimap customization
│   ├── Chat.lua          # Chat frame enhancements
│   ├── DataBars.lua      # XP/Rep/Honor bars
│   ├── Panels.lua        # Custom UI panels
│   └── Profiles.lua      # Profile management
├── Locales/
│   ├── Locales.lua       # Localization setup
│   └── enUS.lua          # English strings
├── PVPUI.toc             # Addon manifest (rename to evildui.toc when packaging)
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Release Process

### IMPORTANT: Do NOT use gh CLI, brew, or the GitHub Actions workflow. Use curl with the GitHub API directly.

### Step 1: Update Version Numbers

1. Update `PVPUI.toc`:
   - `## Version: X.X.X`

2. Update `CHANGELOG.md` with release notes

3. Update `README.md` download link version if needed

### Step 2: Commit and Tag

```bash
cd /Users/evilaptop/Documents/codework/Wow_Addons/PVPUI
git add -A
git commit -m "vX.X.X - Brief description"
git tag vX.X.X
git push origin main --tags
```

### Step 3: Create Release Zip

```bash
cd /Users/evilaptop/Documents/codework/Wow_Addons
mkdir -p release
rm -rf release/evildui
cp -r PVPUI release/evildui
rm -rf release/evildui/.git release/evildui/.gitignore
cd release
zip -r evildui-vX.X.X.zip evildui
```

### Step 4: Get GitHub Token

```bash
git credential fill <<< "protocol=https
host=github.com" 2>/dev/null | grep password | cut -d= -f2
```

Save this token for the next steps.

### Step 5: Create GitHub Release via API

```bash
curl -X POST https://api.github.com/repos/greenovate/evildui/releases \
  -H "Authorization: token YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "tag_name": "vX.X.X",
    "name": "vX.X.X",
    "body": "## Features\n- Feature 1\n- Feature 2\n\n## Fixes\n- Fix 1\n- Fix 2",
    "draft": false,
    "prerelease": false
  }'
```

Note the `id` from the response (e.g., `274996337`).

### Step 6: Upload Zip Asset

```bash
curl -X POST "https://uploads.github.com/repos/greenovate/evildui/releases/RELEASE_ID/assets?name=evildui-vX.X.X.zip" \
  -H "Authorization: token YOUR_TOKEN_HERE" \
  -H "Content-Type: application/zip" \
  --data-binary @/Users/evilaptop/Documents/codework/Wow_Addons/release/evildui-vX.X.X.zip
```

### Step 7: Copy to Live Folder

```bash
rm -rf "/Applications/World of Warcraft/_retail_/Interface/AddOns/evildui"
cp -r /Users/evilaptop/Documents/codework/Wow_Addons/release/evildui "/Applications/World of Warcraft/_retail_/Interface/AddOns/"
```

## Code Conventions

### Lua Style
- Use `local` for all variables and functions where possible
- Addon global table: `EvilDUI`
- Database: `EvilDUIDB` (saved variables)
- Use SecureActionButtonTemplate for action buttons
- Combat lockdown checks before modifying secure frames

### Frame Naming
- Frames: `EvilDUI_FrameName`
- Action bars: `EvilDUIActionBar1`, etc.
- Buttons: `EvilDUIActionButton1`, etc.

### Database Structure
```lua
EvilDUIDB = {
    profiles = {
        ["ProfileName"] = {
            actionBars = { ... },
            unitFrames = { ... },
            minimap = { ... },
            chat = { ... },
            dataBars = { ... },
            panels = { ... },
            movers = { ... },
        }
    },
    currentProfile = "Default",
    dbVersion = 4,
}
```

### Config Panel
- Uses custom dark theme (backdrop color: 0.1, 0.1, 0.1)
- Categories on left, settings on right
- Helper functions: `CreateSlider()`, `CreateCheckbox()`, `CreateDropdown()`, `CreateColorPicker()`

## Common Issues

### "Taint" errors
- Don't modify secure frames in combat
- Use `InCombatLockdown()` to check
- Queue changes for after combat with `PLAYER_REGEN_ENABLED` event

### Action buttons not working
- Must use `SecureActionButtonTemplate`
- Set attributes before combat: `type`, `action`, `spell`, etc.
- Use `SetAttribute()` not direct table assignment

### Frame strata/layering
- BACKGROUND < LOW < MEDIUM < HIGH < DIALOG < FULLSCREEN < FULLSCREEN_DIALOG < TOOLTIP
- Use `SetFrameStrata()` and `SetFrameLevel()`

## Testing

1. Make changes in PVPUI folder
2. Copy to live addon folder (or symlink)
3. `/reload` in WoW
4. Check for lua errors: `/console scriptErrors 1`
5. Type `/evildui` to open settings
