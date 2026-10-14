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

## Acceptance

- Parse and run the authored Ink story with both choices.
- Validate tags `fact:docks-route` and `suspicion:1`.
- Godot 4.7.2 import, real scene, Linux release and single-threaded Web release.
- Chromium browser must report `INK_READY` from inside the Godot runtime, not merely load a blank canvas.
- The taxi must continue moving while the player sees the dialogue.

Do not count this as the **full P1 ride**. Pickup/drop-off, saving, fares and consequences are explicitly next.
