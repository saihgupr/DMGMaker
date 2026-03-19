# DMG Maker Specification

## Vision
A "cheap and cheerful" DMG creator that prioritizes ease of use over complex features.

## Core Mechanics
- **Interaction**: Drag-and-drop focused.
- **Inputs**: 
    1. The `.app` bundle (required).
    2. A background image (optional, with a "nice" default).
- **Output**: A launchable `.dmg` file revealed in Finder.
- **Technology**: Native macOS App (Swift / SwiftUI).
- **Architecture**:
    - **Engine**: Local execution of `create-dmg` via `Process`.
    - **Sandbox**: Disabled (to allow file system access and shell command execution).
    - **Persistence**: `UserDefaults` to remember the last used background.

## User Interface (UX)
- **Layout**: Two dashed rounded-corner squares.
    - Square 1: Drop zone for the App.
    - Square 2: Drop zone for the Image.
- **Iconography**: A `+` symbol between the two squares.
- **Action**: A prominent "Create" button.
- **Completion**: Reveal the created DMG in Finder.

## Implementation Details
- The app will check for `create-dmg` in standard paths (`/usr/local/bin`, `/opt/homebrew/bin`).
- Default background will be a premium-looking gradient or generated asset.
