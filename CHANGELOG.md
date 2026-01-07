# Changelog

All notable changes to evildui will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-07

### Added
- Initial release
- 5 customizable action bars with SecureActionButtonTemplate
- Frame mover system with visual overlays
- Mouseover keybind system
- Profile management with create/copy/delete
- Profile import/export via Base64 encoded strings
- Comprehensive settings panel with 6 categories:
  - General: UI scale, fade settings, keybind/macro text options
  - Action Bars: Per-bar configuration (enable, buttons/row, size, spacing)
  - Unit Frames: Toggle visibility for all Blizzard unit frames
  - Movers: Frame list with individual reset buttons
  - Keybinds: Binding management and mouseover toggle
  - Profiles: Full profile management and import/export
- Slash commands: /evildui, /pui
- Combat lockdown protection for secure frame modifications
- Uses modern WoW 11.0+ menu API (WowStyle1DropdownTemplate)

### Technical
- No external library dependencies
- Native Base64 encoding/decoding for profile export
- Compatible with The War Within (Interface 110207)

[Unreleased]: https://github.com/yourusername/evildui/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/evildui/releases/tag/v1.0.0
