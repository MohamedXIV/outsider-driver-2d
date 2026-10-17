# Sequential completion — October 17, 2026

Baseline: live main `05ea3fdd3c5a0484f2b2db7657a639ad919bff30`; open #55 head `e18aa0cd1444865f0ce7f669590df201ad8de36b`; draft #61 head `983ed8724baf936828bb620f270a387fcbd45b7a`. This implementation branch starts at #61 and targets it; neither existing PR is modified or merged.

## Camera #56

Reuse: one SandboxWorld, Camera2D, player Options, save presentation bundle, road topology and all Ink interactions.
Replace: per-frame fixed 2x camera with a 2.6x default, bounded 1.25–4x preference, exponential scale easing, wheel and keyboard +/- input, and translated 44px Options buttons including reset.
Retire: fixed zoom expectation only. No gameplay, clock, route or economy authority changes.
Reduced motion applies scale immediately and retains the existing no-lookahead behavior. Manual preference persists in the city save. GUI scroll handling takes precedence over wheel zoom. Invalid persisted scale is rejected.

Verification so far: observed failing closer-default regression, then passing focused Godot 4.7.2 headless and actual Mesa/X11 rendered regression; full native city presentation test passed. Broader tests and exported Chromium interaction evidence follow below. A pre-existing gate misclassified `test_world_shuttle_visual` as headless despite waiting on `frame_post_draw`; it now runs in the native set. The initial broad run timed out on that test after 32 other tests passed; that timeout is not a gameplay pass.

Human camera comfort, final art and actual Windows gameplay remain pending. Camera follow smoothing beyond the existing follow behavior is not claimed.

## NPC interpolation #57 follow-up

The parked-taxi correction already exists in #61. A remaining discontinuity was reproduced while the real taxi and a naturally generated resident shuttle concurrently yield: the controller forced the shared render fraction to zero, stepping unrelated NPCs once per tick. The shared clock now advances normally; `SandboxWorld.player_position` and `npc_position` already independently clamp held actors. The expanded real-scene concurrency regression failed before the correction and passes on native Godot 4.7.2 afterward, including stationary held vehicles, save/restore, body clearance and matched yield ledgers. No world simulation behavior changes.

## Player HUD #49 / #50 follow-up

The shipped Player Mode fare flow is retained. A new 390px regression reproduced clipped tabs and a panel wider than the screen. Tabs now wrap into a three-column grid on phones, the panel follows below them, labels release their previous desktop minimum width, and action text wraps while retaining 44px minimum height. Portrait artwork yields space to readable dialogue on phone widths. Existing desktop geometry is retained. Layout regression now passes from 390×844 through 1280×720. Exported camera testing also exposed wheel overscroll reaching world zoom; hovering GUI now suppresses wheel zoom even when a panel cannot scroll farther.

Actual exported Chromium full-fare regression PASS: live fare + Ink + midride IndexedDB reload + one arrival settlement, reversible modes, market/module/AR controls, scrolling and narrow Arabic. Native suite and domain/adapter suite PASS; independently rendered world-shuttle visual PASS after correcting its gate assignment. These are technical results, not human acceptance.

## Modular streets #58 partial extension

The existing straight/T module now connects to a native four-way module and a right-angle corner. Authored road, sidewalk, crossing and regular lot rectangles drive both drawing and Godot navigation. Four explicit crossing links retain separation between sidewalk surfaces and asphalt. New regression verifies paths from the existing east block through both vertical arms and around the corner, building setbacks, unchanged world snapshot, and rendered close/wide captures. Existing world road graph, legal ramps, elevation and the original taxi/shuttle zebra binding are unchanged.

This is a local ground-level kit extension, not citywide geometry replacement, intersection vehicle arbitration or improved bridge art. Existing single resident still has its original goal; the extension paths are native navigation proof. Multiple concurrent native residents (#59), multi-reservation junction traffic (#60) and better elevated bridge/ramp presentation (#58) remain technical work.
