# Engineering Rules

> **Active design now:** [sandbox DNA](SANDBOX_GAME_DNA.md), [foundation #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15); prototype [P0–P2 closed as scope](PROTOTYPE_CLOSEOUT.md). The following rules apply to sandbox work, not new scripted clinic content.

1. **Playable systemic value every milestone.** Ship small, actually interactive world-simulation loops; do not create a feature checklist by extending the frozen first clinic ride, nor abstract framework without a running test case.
2. **One authoritative current sandbox world.** `SandboxWorld` owns persistent game truth; cohesive domain services calculate transformations and the UI/Ink/camera only present state and submit validated commands. The archived `GameSession` exists for frozen P1/P2 regression proofs and must not become a parallel live world authority.
3. **Typed GDScript by default.** Favor small cohesive files; neither giant monoliths nor one file per trivial helper.
4. **Stable IDs and meaningful domain boundaries.** Persist NPCs, mobility demands, offers, routes, economic and law consequences as data with validated references. No authored passenger-scenario scheduler masquerading as a sandbox. Ink handles grounded interaction policies and fallback expression, not city state.
5. **No premature C++ or custom puppet engine.** Profile first; Web is a required export target.
6. **No lock-in to old saves.** The old 3D repo is reference material, not a compatibility burden.
7. **Real visual acceptance.** Passing unit tests does not prove camera, occlusion or enjoyable play.
8. **Editor-friendly and agent-friendly.** Commit readable scenes/scripts/content; document headless checks. Do not hide important gameplay logic solely in opaque editor state.
9. **Small reversible steps.** Prefer short, reviewable PRs and avoid unrelated changes to the prior repository.
10. **Do not expand scope by implication.** Isometric does not automatically enable open-world walking or free driving.

11. **Mandatory supersession audit before every implementation PR.** Check [Current vs Superseded Contracts](SUPERSESSION_REGISTER.md), the latest accepted user decisions and live code/PRs. Mark old behavior **Reuse / Replace / Retire**, identify stale tests, and prevent two competing sources of truth. A green historical test does **not** require retaining superseded gameplay.
12. **Decision authority is explicit.** A newer user decision can replace an older idea even without a playtest. Distinguish **approved**, **recommended/pending**, **historical proof**, **current runtime**, and **future work**. Never implement a merely proposed starter loadout as if approved. Preserve useful engine correctness evidence while rewriting obsolete feature expectations.
13. **Document conflict resolution.** If a current issue/test/document demands incompatible behavior, update/replace it in the same PR; don't quietly retain two systems or claim both are canonical.

Implementation can change when new user direction or playtesting shows a better course. Do not reopen settled choices without a concrete reason. Keep GitHub Actions usage minimal.
