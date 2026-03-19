# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2026-03-19

### Added
- **Bundled `create-dmg`**: The core utility is now integrated directly into the application.
- **Plug and Play Support**: Users no longer need to install Homebrew or the `create-dmg` package manually.

### Changed
- **Internal Engine**: Updated `DMGEngine` to prioritize the bundled `create-dmg` binary over system-wide installations.
- **Resource Management**: Optimized `Package.swift` to handle bundled scripts and support files.
- **Documentation**: Updated `README.md` to reflect the simplified installation requirements.

## [1.0.1] - 2026-03-19

### Changed
- **DMG Creation Logic**: Slight adjustments to how disk images are generated to improve reliability.

## [1.0.0] - 2026-03-18

### Added
- Initial release of DMG Maker.
- Live SwiftUI mesh gradient backgrounds.
- Glassmorphic UI design.
- "No-Halo" Applications link trick.
- Retina-ready high-DPI asset rendering.
