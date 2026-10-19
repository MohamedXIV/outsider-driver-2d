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
