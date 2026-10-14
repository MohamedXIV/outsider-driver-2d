# P1.1 — Ink integration gate

## Runtime decision

Use [inkgd](https://github.com/ephread/inkgd) **pure GDScript runtime only**, pinned to the `godot4` branch commit `fea9098ee18d6cdbe9a5e25f8f0296bcdf0fd96a` under `addons/inkgd`. The MIT license is preserved. No C# and no Ink reimplementation.

This upstream branch does not currently have an official stable release for Godot 4.7, so integration must be proven in actual Web **and** native exports. There has been an upstream report of InkPlayer failing in Web; we deliberately avoid InkPlayer's background/thread lifecycle by using the core `InkStory` synchronously behind a tiny `InkBridge`. This is a mitigation to test, not a guarantee.

## Authoring / compiling

- Source: `stories/p1_probe.ink`.
- Game/runtime reads compiled `stories/p1_probe.ink.json`.
- Compilation: `npx inkjs-compiler -o stories/p1_probe.ink.json stories/p1_probe.ink` (pinned `inkjs@2.4.0` in the validation job).
- Compiler output is a **generated artifact**, not handwritten Ink JSON. Commit the compiled output after verifying it so Godot can run directly after cloning, without a separate Node install.
- GameSession (P1 continuation) will consume text/tags and apply facts or suspicion; Ink does not own domain truth.

## Verified (2026-10-14)

[CI run #38622103611](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38622103611) **PASS**:
- Godot 4.7.2 import and typed GDScript parse of the vendored interpreter.
- `tests/test_ink.gd` executes actual compiled Ink JSON: two different choices, matching authored dialogue, effect tags, and story termination.
- Native Linux release export and headless startup.
- Single-threaded Web export, Chromium launch, DOM proof from inside Godot that Ink loaded, real mouse click on player choice, and proof that the handler executed.
- [Opening/choice screenshots](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38622103611/artifacts/11922383385) reviewed: same taxi continues driving between two screenshots as the passenger dialog changes.

### Integration findings
- The first Chromium run [#38621789336](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38621789336) exposed a real Godot scene lifecycle error: parent was busy registering children when the game tried to create the InkRuntime singleton.
- Fixed by scheduling `_start_ink()` after scene setup with `call_deferred`. No custom Ink parser or rewrite needed.
- Compiled `stories/p1_probe.ink.json` is now versioned alongside source. CI checks that compilation is byte-for-byte consistent after normalizing compiler BOM/newline.

**P1.1 is complete, not P1 as a whole.** The UI is a functional placeholder, *not* final character presentation. There is no GameSession consequence wiring, arrival-safe exit, fare settlement, persistence or authored passenger spritesheet yet.

## Acceptance

- Parse and run the authored Ink story with both choices.
- Validate tags `fact:docks-route` and `suspicion:1`.
- Godot 4.7.2 import, real scene, Linux release and single-threaded Web release.
- Chromium browser must report `INK_READY` from inside the Godot runtime, not merely load a blank canvas.
- The taxi must continue moving while the player sees the dialogue.

Do not count this as the **full P1 ride**. Pickup/drop-off, saving, fares and consequences are explicitly next.
