# Engineering Rules

1. **Playable value every milestone.** Ship a route, conversation, meaningful choice, interaction or location each time—not just framework.
2. **One authoritative GameSession.** Rendering/UI/narrative present and invoke commands; they do not own game truth.
3. **Typed GDScript by default.** Favor small cohesive files; neither giant monoliths nor one file per trivial helper.
4. **Stable content IDs and validated references.** Keep scripts generic, content authored in catalogs and Ink.
5. **No premature C++ or custom puppet engine.** Profile first; Web is a required export target.
6. **No lock-in to old saves.** The old 3D repo is reference material, not a compatibility burden.
7. **Real visual acceptance.** Passing unit tests does not prove camera, occlusion or enjoyable play.
8. **Editor-friendly and agent-friendly.** Commit readable scenes/scripts/content; document headless checks. Do not hide important gameplay logic solely in opaque editor state.
9. **Small reversible steps.** Prefer short, reviewable PRs and avoid unrelated changes to the prior repository.
10. **Do not expand scope by implication.** Isometric does not automatically enable open-world walking or free driving.

Implementation can change when real playtesting shows a problem; do not revisit settled direction without that evidence. Keep GitHub Actions usage minimal.
