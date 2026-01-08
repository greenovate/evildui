# evildUI

[![GitHub release](https://img.shields.io/github/v/release/greenovate/evildui)](https://github.com/greenovate/evildui/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A clean, lightweight UI addon for World of Warcraft focused on questing and PVP. Built by **evild on Mal'Ganis**. evildUI provides powerful customization without the bloat - clean action bars, intuitive movers, mouseover keybinds, custom UI panels, and easy profile management.

## Features

### 🎮 Clean Action Bars
- 5 fully customizable action bars using SecureActionButtonTemplate
- Per-bar settings: enable/disable, buttons per row, button size, spacing
- Combat-safe with proper taint prevention
- Optional fade out of combat for a cleaner look

### 📐 Frame Movers
- Drag any UI element to reposition it
- Visual overlay shows movable frames
- Positions saved per-profile
- Reset individual frames or all at once

### ⌨️ Mouseover Keybinds
- Hover over any action button and press a key to bind it
- Optional mouseover activation mode
- Easy keybind management panel
- Clear individual or all keybinds

### 👤 Profile System
- Create unlimited profiles
- Copy settings between profiles
- Per-character or account-wide profiles
- Import/Export profiles as text strings for easy sharing

### 🎯 Unit Frame Controls
- Toggle visibility of any Blizzard unit frame
- Scale adjustment for all unit frames
- Supports: Player, Target, Focus, Pet, Party, Boss, Arena, ToT, Cast Bar, Buffs

## 📥 Download

### [⬇️ Download Latest Release (v0.0.2)](https://github.com/greenovate/evildui/releases/latest)

Click the link above, then download `evildui-v0.0.2.zip` from the Assets section.

## Installation

1. Download `evildui-vX.X.X.zip` from [Releases](https://github.com/greenovate/evildui/releases)
2. Extract the `evildui` folder to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload`
4. Type `/evildui` to open settings

## Usage

### Slash Commands
| Command | Description |
|---------|-------------|
| `/evildui` or `/edui`/pui` | Open settings panel |
| `/edui move` | Toggle mover mode |
| `/edui kb` | Toggle keybind mode |
| `/edui reset` | Reset all frame positions |

### Quick Start
1. Type `/evildui` to open the settings panel
2. Navigate categories using the sidebar
3. Enable/configure action bars in "Action Bars"
4. Use "Toggle Movers" to reposition frames
5. Use "Toggle Keybinds" to set up your bindings

## Screenshots

*Coming soon*

## Configuration

### General Settings
- **Global Scale**: Adjust overall UI scale
- **Fade Out of Combat**: Reduce bar opacity when not in combat
- **Show Keybind Text**: Display keybind labels on action buttons
- **Show Macro Text**: Display macro names on action buttons

### Action Bar Settings
Each of the 5 action bars can be configured with:
- Enable/Disable toggle
- Buttons per row (1-12)
- Button size (24-64 pixels)
- Button spacing (0-10 pixels)

### Profile Management
- Create new profiles for different specs/activities
- Copy settings from existing profiles
- Export profiles to share with friends
- Import profiles from text strings

## Requirements

- World of Warcraft: The War Within (11.0+)
- No external library dependencies

## FAQ

**Q: Is this compatible with other action bar addons?**
A: evildui replaces Blizzard's default action bars. It may conflict with other action bar addons like Bartender or Dominos.

**Q: Does this work with other UI addons?**
A: evildUI replaces core UI elements. It may conflict with addons that modify the same frames.

**Q: Why can't I move frames in combat?**
A: WoW's secure frame system prevents modifications during combat to prevent exploits. Wait for combat to end.

**Q: How do I share my profile?**
A: Go to Profiles > Export Profile, copy the text string, and share it. Others can import using Profiles > Import Profile.

## Support & Bug Reports

Found a bug or have a feature request?

- 🐛 [Report a Bug](https://github.com/greenovate/evildui/issues/new?labels=bug&template=bug_report.md)
- 💡 [Request a Feature](https://github.com/greenovate/evildui/issues/new?labels=enhancement&template=feature_request.md)
- 📋 [View All Issues](https://github.com/greenovate/evildui/issues)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Created by evild @ Mal'Ganis**
