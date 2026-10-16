# Relationships P0 — Systemic Off-Duty Rendezvous (#31)

> Verified gameplay and technical acceptance on the tested head below. Human UX/visual feel remains unverified.

## Authority / supersession preflight

- **Main baseline:** `306f4284d65ab00f701232e4811dc9699e3fe155`; no competing open PR at implementation start.
- **Authority:** [#31](https://github.com/MohamedXIV/outsider-driver-2d/issues/31), [Living City Conclusions](LIVING_CITY_DESIGN_CONCLUSIONS.md), [Supersession Register](SUPERSESSION_REGISTER.md).
- **Reuse:** `SandboxWorld`'s event ledger, `SandboxPopulation` stable residents / work and rest, `SandboxDriverMemory` actual fare sources, `SandboxDispatch` NPC-generated demand, `SandboxRoads` district graph and `SandboxSave`/InkBridge. Existing S3/route tests remain applicable.
- **Replace:** `trust` plus recognition without an off-duty gameplay consequence is supplemented with a bounded relationship event and the possibility of an explicit commitment; no existing NPC identity/memory or journey mechanism is replaced.
- **Retire:** no extension to `GameSession`, scripted clinic passenger, fixed rides, unlimited waiting companion NPCs, universal unmasking, affection meter or automatic romance.
- **Pending/deferred:** physical art polish, visual/human pacing acceptance, binary Translator Modules and Basic Common default (#32), multilingual glyph/RTL (#33), AR (#34).

## Loop

1. Two **completed real offers from the same NPC** create two witnessed memories. `SandboxMeetings.propose` requires significance, individual willingness threshold, and an actual non-travelling position. Cautious residents require stronger trust; a generic affinity meter cannot force love.
2. The invitation references its actual last `fare_settled` event and a meeting spot at the resident's own district. The slot is a daytime, non-working period, not a summoned character or fixed named quest.
3. The player can **decline**, **accept** before the slot, or **ignore** until expiration. An accepted promise reserves NPC dispatch availability through the 40-minute appointment window. An NPC who independently becomes unavailable cancels rather than magically appearing.
4. The player must physically reach the stated map district (repositioning costs road time/credits, and active trips prevent attending), arrive while the actual NPC is co-present and available, and press **Meet at location**. A visible staged kiosk/bench encounter is rendered with both figures.
5. The same authored off-duty Ink speech-act scene gives **listen / brief / leave** choices. The world, not Ink, advances 10–20 real minutes and applies sourced trust deltas. Lateness reduces the positive result. Missing the deadline decreases trust; no double completion.
6. Save/Load restores invited, accepted, in-progress and terminal statuses from the single `SandboxWorld` snapshot. Ink in the first-step meeting reconstructs its same context/choices after load; there is no separate off-duty scheduler or hidden narrative truth.


## Actual completed execution — October 16, 2026

- **Latest gameplay/test head:** `2fb75b0dcc54d773937d37b1be65f7b6ff01bf43`.
- **[Godot 4.7.2 gate #38823128499](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38823128499): SUCCESS** including compiled Ink source parity, native import/typed script tests, previous P0–S3/route regressions, domain `SANDBOX_MEETING_DOMAIN_PASS`, visible native scene `SANDBOX_MEETING_SCENE_PASS`, and actual exported Chromium mouse-input `SANDBOX_MEETING_WEB_PASS`.
- **[Evidence artifact #12014295103](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38823128499/artifacts/12014295103)** includes native/Web screenshots; **[builds artifact #12014042988](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38823128499/artifacts/12014042988)** includes Linux, Windows and Web exports.
- GitGuardian check completed successfully on this gameplay head; Windows was **exported only**, not executed on Windows. Native Linux was executed; Web was executed through actual Chromium. Automated screenshot generation and interaction were verified, but independent human review of art, UX and pacing **was not performed**.
- Superseded S2 partial Translator is still historical experimental behavior, not the approved language-module successor; no Basic Common starting loadout selection was made in this slice.

## Proof gates

- Domain: `tests/test_sandbox_meeting.gd` checks two real fares, multiple seeds, replay, sourced invites, acceptance, late, decline, ignore, missed, in-progress and completed Save/Load, immutable one-time settlement and rejection of falsified provenance.
- Native: `tests/test_sandbox_meeting_scene.gd` operates actual Godot UI controls and captures the invitation, spot, staged encounter, mid-meeting reload and resolution.
- Web: `tests/web_sandbox_meeting.cjs` uses real pointer input against the exported Chromium scene with full sequence and screenshot proof.
- CI: `.github/workflows/p1-ink.yml` compiles the authored Ink, checks compiled JSON, runs Godot 4.7.2 and Linux/Windows/Web export proof (Windows export is **not** Windows runtime).

**Not asserted:** human gameplay feel, Windows runtime, final art, production language modules.
