# Actual exported route — 64e941f

Captured by the unmodified real two-fare workflow in `web_city_routes.cjs`,
with its new read-only actor trace. Source/runtime HEAD:
`64e941f21f2614faac7570e77eca77d3d537569e`.
Pinned Godot 4.7.2; Playwright 1.56.0 / Chromium build 1194.

The three screenshot/JSON samples are chronological, not adjacent render frames.
They record World minutes 497, 499 and 501 on the genuine first fare. `npc:02`
is native in sample 0 and the same World-owned far walker in samples 1/2;
all samples have nine residents. `visible` means inside the viewport rectangle,
not an assertion about occlusion by the HUD or buildings.

The separate native lifecycle scene regression checks adjacent handoff/reentry
pose equality. These Web images supply actual exported-route observations;
they do not alone establish full-suite PASS or human visual acceptance.

This evidence-only branch adds no runtime changes above the recorded head.
The final full-suite status is reported in Draft PR #73.
