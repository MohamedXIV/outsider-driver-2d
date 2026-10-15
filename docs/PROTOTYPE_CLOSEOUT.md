# P0–P2 Prototype Closeout — archived technical proofs

**October 15, 2026. Scope closure, not production/gameplay acceptance.**

## What was actually proven

| Proof | Evidence | Status |
| --- | --- | --- |
| P0 axonometric 2D / bridge / ramp / correct above-vs-below and camera rendering | [P0 proof](P0_VALIDATION.md) | Technical proof passed; vector placeholder art |
| P1 compiled Ink, authored text/choice/tags, saved frames, clock and safe arrival/drop-off, passenger UI | [P1 ride proof](P1_RIDE.md) | Godot/Linux + exported Chromium Web technical checks passed |
| P1 native Web/Linux exported gameplay and save/reload | [P1 playtest](P1_PLAYTEST.md) | Automated checks passed; no human playtest |
| P2.0 starter GPS / Translator / Radio distinct knowledge | [Shift prep](P2_SHIFT_PREP.md), [PR #12](https://github.com/MohamedXIV/outsider-driver-2d/pull/12) | Technical slice passed |
| P2.1 bounded garage movement/proximity, notice and taxi interaction, preserved position | [Garage](P2_GARAGE.md), [PR #13](https://github.com/MohamedXIV/outsider-driver-2d/pull/13) | Web/Linux technical checks passed |
| P2.2 repeated fixed taxi ride, once-only 18-credit fare/6-credit service and persistent state | [Daily loop](P2_DAILY_LOOP.md), [PR #14](https://github.com/MohamedXIV/outsider-driver-2d/pull/14) | Web/Linux two-loop automated validation passed |

Final existing **green** technical gate: [GitHub Actions #38652590394](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38652590394), gameplay commit `3c02a6fa399031730efde5708dbed38aa261e4a2`, before docs-only closeout. Editor import, pure-GDScript Ink, native tests, real Linux window screenshots, Chromium keyboard/pointer/save-reload flow, Linux boot/export, Windows **export** all passed. Screenshot artifact `playable-ride-evidence` and downloadable `outsider-driver-playtest-builds` are subject to GitHub's 21-day retention. **No new runtime code or test runs were added for closeout.**

## Important limits: NOT verified, NOT passed

- Actual human pacing, reading comfort, taxi/camera feel, UX discoverability, visual quality and intended *sandbox fun*.
- Actual Windows native execution. Generating an .exe does NOT establish Windows runtime gameplay.
- A living city, autonomous population, generated mobility demand, multiple offers/dispatch, systemic day economy or independently behaving NPCs.
- Semantic Ink binding from dynamic NPC contexts, typed commands or optional LLM surface realization. The current Ink bridge only returns authored text/choices/tags + flow/save commands.
- The 18/6 credit constants, one clinic client and fixed route are **test-fixture values**, not canon/game balance.
- The native instant skip to arrival does not prove natural camera pacing.

## Closing policy and migration

- Archive P1 [#3](https://github.com/MohamedXIV/outsider-driver-2d/issues/3) and P2 [#11](https://github.com/MohamedXIV/outsider-driver-2d/issues/11) as **superseded prototype scope (not_planned)**, even though technical subgates passed. Leave unchecked human and expanded-P2.3 checks *unchecked*, with explanation, not fictitious PASS.
- The verified rendering/Ink/persistence work can be reused or refactored. No deletions or resets needed for scope closure.
- The old scene, clinic story and tests remain available as a **frozen regression fixture**, not the sandbox gameplay roadmap. Do not continue P2.3 as "repeat this same ride N times."
- Move human/Windows runtime and semantic/systemic acceptance under the future modular sandbox milestone [#15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15). Evaluate human UI on the *new* sandbox, and if reusing a legacy subsystem do small focused runtime checks rather than testing the old prototype endlessly.
- Update [Game DNA](SANDBOX_GAME_DNA.md) first, then create lean contracts for systemic world, population, mobility/dispatch and dialogue before additional gameplay.

**Status:** Legacy technical prototype frozen. Sandbox product not yet implemented.
