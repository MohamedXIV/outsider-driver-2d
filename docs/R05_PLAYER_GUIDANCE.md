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
