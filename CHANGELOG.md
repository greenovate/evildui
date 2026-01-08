# Changelog

All notable changes to evildui will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.3] - 2026-01-07

### Added
- Layout Manager - save, share, and import complete UI layouts
- Layout history with auto-save before loading
- Export/import layouts as shareable strings
- Favorite layouts for quick access
- Welcome screen with changelog on updates
- Reload prompt when settings require it

### Changed
- Renamed addon display to "evildUI" consistently
- Added custom logo to addon

## [0.0.2] - 2026-01-07

### Added
- Custom UI Panels system - create resizable backdrop panels for custom layouts
- Panel customization: background color, border color, border size, strata, level
- Minimap settings: square/round shape, rotation (north lock), scale, zone text position
- Menu Bar settings with drag-to-reorder and visibility toggles
- Data Bars module for XP/Rep/Honor bars
- Buff/debuff tooltips on unit frames
- Button press visual feedback on action bars
- Minimap coordinates display

### Fixed
- Keybind text overflow on action bars (proper abbreviations)
- Action bar icon brightness (proper draw layer)
- Micro button positioning and movement

### Changed
- Improved settings panel with scroll support
- Better keybind abbreviations (MwU, MwD, etc.)

## [0.0.1] - 2026-01-06

### Added
- Initial release
- 5 customizable action bars with SecureActionButtonTemplate
- Frame mover system with visual overlays
- Mouseover keybind system
- Profile management with create/copy/delete
- Profile import/export via Base64 encoded strings
- Comprehensive settings panel
- Slash commands: /evildui, /edui
- Combat lockdown protection for secure frame modifications

### Technical
- No external library dependencies
- Compatible with The War Within (Interface 110207)

---

**Created by evild @ Mal'Ganis**

[0.0.3]: https://github.com/greenovate/evildui/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/greenovate/evildui/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/greenovate/evildui/releases/tag/v0.0.1
