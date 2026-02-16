## 2024-10-24 - Drag-and-Drop Feedback
**Learning:** `onDrop` modifier's `isTargeted` binding is crucial for providing visual feedback when dragging files over a drop zone. Without it, users are unsure if the drop will be accepted.
**Action:** always bind `isTargeted` to a state variable in `onDrop` and use it to highlight the drop target (e.g., border color, opacity).
