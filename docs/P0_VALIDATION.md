# P0 Validation — evidence log

## First run — Godot source scene

[CI #38611865760](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38611865760), head `40412ac` **PASS**:
- Godot 4.6.3 editor import/parse.
- Focused projection, route progression and projected-overlap tests.
- Headless scene run and 360-frame Xvfb/OpenGL rendering. Screenshots reviewed.

## Second run — export attempts and visual correction

[CI #38612656327](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38612656327), head `62920f8`:
- Import, focused tests, headless scene, 2D screenshot capture **PASS**.
- Export and headless launch of **Linux desktop** binary **PASS**.
- **Web export FAILED**: CI had installed threaded `web_release.zip` instead of the `web_nothreads_release.zip` required by the deliberately single-threaded Web preset. This is a template selection/configuration failure, not a runtime/game-code finding.
- Screenshot at frame 67 showed a genuinely occluded taxi **disappearing entirely** under the opaque bridge: correct draw order, wrong tracking UX.

## Next run — targeted corrections

- Install correct `web_nothreads_debug.zip` and `web_nothreads_release.zip` templates and attempt Web export + Chromium run.
- Prevent generated screenshot evidence from entering the Godot source directory and exported PCK.
- Make elevated deck partially transparent only while it hides the player's ground taxi.
- Increase camera zoom for close-follow framing.
- Capture start, exact underpass, ramp, elevated and end. **These fixes are not accepted until new snapshots are reviewed.**

## Current acceptance state

- Godot import/tests/headless and Linux export: **PASS** on evidence above.
- Camera/underpass visibility and Web/browser runtime: **PENDING**.
- No final art or broader gameplay systems implemented yet.
- GitHub Actions used only for targeted Godot verification because there was no local Godot executable or connected ShellWarden tunnel.

See [Issue #1](https://github.com/MohamedXIV/outsider-driver-2d/issues/1).
