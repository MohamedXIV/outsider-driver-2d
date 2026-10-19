# R05 contextual Player Mode guidance (#50)

Independent UI-owned Draft PR, stacked on #75. **No** lane, road, World,
economic, shuttle, pedestrian or actor lifecycle files are modified.

One grounded, read-only next-step summary derives from actual visible fare,
conversation, pending rider question, travelling route and starter equipment.
It does not expose untranslated alien speech, inferred secrets, rank or fate.
A 44px tab action opens the relevant existing screen, not a new simulation.

At desktop sizes the panel occupies unused right-side screen space, underneath
the real passenger portrait. At compact sizes guidance is presented in the
Street panel rather than as an overlay obstructing the controls. Supports RTL
and keeps Debug Mode separate. Native scene regression covers real tabs,
locale, viewport, lack of hidden question content and immutable World state.

This is only a first design-and-implementation slice; full issue #50 requires
additional human visual review. Parallel Codex work remains exclusively in
#67/#68 driving and actor presentation. Do not merge until integrated gates
and human acceptance.

## Canvas input and parent-stack sync

The initial UI commit passed all 42 domain and 40 native tests but failed
exported Chromium `web_camera_zoom` at the **first world-space mouse wheel**
(`tests/web_camera_zoom.cjs:11`) even though the earlier base head passed.
The guidance frame and its descriptive VBox/Labels now ignore pointer hover
and wheel input, while the actual 44px navigation button remains interactive.
The native scene test asserts this exact unobstructed canvas wheel point and
that the camera zoom actually changes, in addition to UI affordance rules.
This stack now includes Codex's latest #75 actor-lifecycle dependency changes
without editing or altering any of those World/actor/physical files.

## Compact Street and dialogue follow-up

- Below 600px width, the scrollable Street panel becomes a fixed-height
  **bottom sheet** capped at 46% of viewport height. It leaves a meaningful
  exposed region of the real city between the tabs and controls, including
  during dialogue, and never changes height as NPC offers appear or expire.
- The real Wait action stays first in the requests sheet with a stable
  hit target; a selected resident's genuine Talk/Accept/Decline controls
  now appear before the potentially long autonomous offer list.
- During compact dialogue, omit redundant driving filler so source-owned
  Ink text and actual response buttons remain nearer each other.
- Compact current-fare prompts also skip verbose ambient route explanation;
  the existing Map remains available for route inspection.
- Native guidance regression checks bottom-sheet bounds, viewport and
  input stability; the existing two-fare Web gate and player layout gate
  remain authoritative integration regressions.

The current baseline's full native gate encountered a 90-second timeout
in Codex-owned `test_taxi_crossing_unload_scene` after the focused UI and
complete domain gates had passed. This separate actor-lifecycle issue must
be diagnosed through the owner track, not worked around by relaxing the UI
or modifying World-owned physical code here.

## Option popup lifecycle guard

For Map destination and waypoint selection, an open Godot `OptionButton`
popup retains its native input/focus ownership during an asynchronous
World-driven UI refresh. Existing `_sync_after_release` rebuilds only after
the native popup closes, avoiding loss of keyboard selection in Web. A new
Xvfb native regression opens the real via PopupMenu, triggers a forced UI
refresh, and asserts the original widget remains alive until selection or
closure. This does not change route data, selected waypoint semantics, or
relax `web_city_routes` assertions. A specific upstream Chromium failure
at its `selectedVia` assertion remains under exact-head verification.

## RTL modal-overlap diagnosis and fix

The exact-head `e60fc962` native/domain suites passed, but its Web
`web_city_playability` timed out at the genuine English language click
immediately following Arabic. Inspection of the **actual** CI artifact
`web-player-arabic.png` showed an RTL layout problem: Settings moved to
screen right, while the guidance card remained at its LTR screen-right
location, directly above Settings controls. This was a UI hit-testing bug,
not a simulation or Web-test defect.

The card now follows the opposite side of the real Player panel: **left in
Arabic/RTL, right in English/LTR**, and is visible only when its one-button
next-step navigation leads to a *different* tab. It takes only its content
minimum height, no longer a tall decorative overlay. The new native regression
checks real RTL Settings/card rectangles, no overlap, card height and a
physical Godot mouse press/release on English after switching into Arabic.
The original real-language-switch browser assertions are unchanged.

Synced onto the exact green rider-initiative parent `a272a0a2` including
its repaired `web_city_routes` via-selection test, with no modification to
World, traffic, actor lifecycle or the browser helper. Exact-head CI remains
required before marking the UI accepted.

## Bounded HUD overlay implementation detail

The first RTL-collision fix caught another genuine native regression:
`PanelContainer`'s content-size feedback expanded the non-modal card well
past 250 pixels in height (native focused test on `b198685e`). Replaced
this presentation-only container with a `Control` drawing the same theme
style and explicit **282 × 172** layout for a heading, a brief wrapped line
and the real 44px tab action. No World logic or autonomous interaction is
inside it. The native test now asserts exact bounded height.
