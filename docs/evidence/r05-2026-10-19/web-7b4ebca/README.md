# Actual exported route after timestamp correction

Source/runtime: `7b4ebcaecc9d1b9f3ac73a33740720f99c1fe270`.
Godot 4.7.2, Playwright 1.56.0, Chromium build 1194.

Captured by the original real two-fare workflow with its condition-based
waypoint wait and read-only pose tracing. The actual two-fare/settlement case
PASSES; it retains all route, settlement and zero-browser-error assertions.

These three chronological samples show World minutes 497, 499 and 501.
`npc:02` is native first and the same World-owned far walker afterward; all
samples have nine residents. `visible` means inside the viewport rectangle,
not a claim about occlusion by the HUD or buildings. These samples are not
adjacent render frames; the native timestamped handoff regression checks the
exact boundary separately. The older 64e941f sequence remains separately labelled.
