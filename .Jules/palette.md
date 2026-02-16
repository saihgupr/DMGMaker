## 2024-10-24 - Drag-and-Drop Feedback
**Learning:** `onDrop` modifier's `isTargeted` binding is crucial for providing visual feedback when dragging files over a drop zone. Without it, users are unsure if the drop will be accepted.
**Action:** always bind `isTargeted` to a state variable in `onDrop` and use it to highlight the drop target (e.g., border color, opacity).

## 2024-11-20 - Explicit Instructions & Portable Resources
**Learning:** Ambiguity in drag-and-drop interfaces can cause user hesitation. Also, hardcoded asset paths break portability.
**Action:** Add clear instructional text (e.g., "Drag to Applications") and always use `Bundle.module` for accessing bundled resources in Swift packages to ensure the UI renders correctly everywhere.
