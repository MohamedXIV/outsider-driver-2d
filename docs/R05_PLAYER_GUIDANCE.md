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
