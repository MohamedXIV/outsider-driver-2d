# Technical Architecture — New 2D Baseline

## Stack

- Godot 4.7.2 stable, Compatibility renderer, Web and desktop targets from one project.
- Typed GDScript for gameplay and orchestration.
- `Node2D` / `Camera2D` / `TileMapLayer` (as useful), Godot `Control` UI.
- Simple sprite/spritesheet passenger animation using built-in Godot 2D APIs.
- Authored Ink. Integration selection and web compatibility are an **early validation gate**, not a proven dependency.
- JSON/Godot Resources for content; stable IDs and build-time/content-load validation.
- C++ through GDExtension only if profiling reveals a real CPU bottleneck **and** Web compatibility is proven. No native dependency in P0.

## Ownership

```
Authored content (Ink, catalogs, sprite atlases)
          |
          v
GameSession / domain (time, passengers, claims,
relationships, suspicion, economy, routes)
          |
          +--> narrative adapter --> passenger/choice UI
          |
          +--> world presentation adapter --> isometric scenes, taxi, camera
          |
          +--> persistence --> versioned new-game saves
```

Domain logic is independent of `Node2D`, camera, sprites and UI layout. The view reads state and user actions become explicit game commands. Ink writes consequences through an adapter, not directly to visual nodes. Do not carry the former project's save migrations into the new game without an actual compatibility requirement.

## Deferred decisions

- Ink Godot adapter choice must pass compile/play/choice + Web export check before extensive authored content integration.
- Sprite animator begins with atlas frame/expression selection; new modes may plug into the same presenter interface later, with **no bespoke puppet runtime now**.
- Elevation authoring may use Godot 2D scenes and curated road pieces; reject a generic procedural road editor until repeated production work justifies it.

## Validation

At each playable increment: script/parser smoke, deterministic domain tests, one real Godot scene run and Web+desktop export smoke whenever export toolchains are available. A screenshot/visual review is required for compositing/depth claims. CI must be modest; avoid spending GitHub Actions minutes when local/headless checks suffice.
