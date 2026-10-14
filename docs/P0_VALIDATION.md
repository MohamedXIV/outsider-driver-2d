# P0 Validation — accepted technical proof (2026-10-14)

## Accepted CI evidence

- [Run #38611865760](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38611865760): Godot 4.6.3 import, typed GDScript parse, route/projection assertions, headless launch and actual software-OpenGL rendering **PASS**.
- [Run #38612656327](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38612656327): Linux release exported and executed **PASS**. Initial Web export failed because the workflow downloaded the *threaded* Web templates while the preset required `web_nothreads`; this CI setup was corrected, not concealed.
- **[Final run #38613477242](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38613477242): ALL STEPS PASS**: Godot 4.6.3 source import, deterministic core checks, headless scene, Xvfb/software-OpenGL render, correct export templates, Linux release export/execution, Web release export and Chromium browser canvas load/screenshot without captured page errors.

[Final six-image artifact](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38613477242/artifacts/11918288645) captures start, crossing from below, ramp, elevated deck, end, and real Chromium Web scene.

## Visual review

- The taxi visibly drives at ground level, climbs an authored ramp, then proceeds at elevation +1.
- The bridge occupies a distinct elevation and occludes the ground taxi. At the actual crossing the deck becomes translucent so the player can continue to track the vehicle.
- Camera uses close-follow, look-ahead and reduced zoom at the crossing/elevated road. The frame reflects taxi-centric travel rather than a distant builder overview.
- The bridge uses a minimal skirting/edge treatment. **These are intentionally basic vector placeholders**, *not* an approved art treatment, fully authored road asset pipeline or guarantee of general occlusion for every kind of geometry.

## Scope of evidence

**Verified:** Linux x86_64 desktop export/headless launch; exported Web content loaded in Chromium on Linux with Canvas rendered; scripted core checks; representative rendered camera/road/bridge frames.

**Not yet verified:** Windows/macOS native exports, user-device Safari/Android, long-running gameplay, input UX beyond simple automatic travel, performance with production art, arbitrary overlapping bridges, and Ink/portrait integrations. These are later target/content gates, not retroactive reasons to restart P0.

Targeted workflow is intentionally restricted to the original feature branch, or manual dispatch, to avoid routine GitHub Actions minute consumption after merge. Preserve the source and evidence; avoid re-running the full export/Chromium job for docs-only changes.

Next: **P1 — First Authentic Taxi Ride**.
