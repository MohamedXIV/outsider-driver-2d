# Engineering Rules

> **Active design now:** [sandbox DNA](SANDBOX_GAME_DNA.md), [foundation #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15); prototype [P0–P2 closed as scope](PROTOTYPE_CLOSEOUT.md). The following rules apply to sandbox work, not new scripted clinic content.

1. **Playable systemic value every milestone.** Ship small, actually interactive world-simulation loops; do not create a feature checklist by extending the frozen first clinic ride, nor abstract framework without a running test case.
2. **One authoritative GameSession.** Rendering/UI/narrative present and invoke commands; they do not own game truth.
3. **Typed GDScript by default.** Favor small cohesive files; neither giant monoliths nor one file per trivial helper.
4. **Stable IDs and meaningful domain boundaries.** Persist NPCs, mobility demands, offers, routes, economic and law consequences as data with validated references. No authored passenger-scenario scheduler masquerading as a sandbox. Ink handles grounded interaction policies and fallback expression, not city state.
5. **No premature C++ or custom puppet engine.** Profile first; Web is a required export target.
6. **No lock-in to old saves.** The old 3D repo is reference material, not a compatibility burden.
7. **Real visual acceptance.** Passing unit tests does not prove camera, occlusion or enjoyable play.
8. **Editor-friendly and agent-friendly.** Commit readable scenes/scripts/content; document headless checks. Do not hide important gameplay logic solely in opaque editor state.
9. **Small reversible steps.** Prefer short, reviewable PRs and avoid unrelated changes to the prior repository.
10. **Do not expand scope by implication.** Isometric does not automatically enable open-world walking or free driving.

Implementation can change when real playtesting shows a problem; do not revisit settled direction without that evidence. Keep GitHub Actions usage minimal.
