# P2.1 — Bounded walkable garage

The player's first shift now starts **inside one authored 2D isometric garage**. The existing P0 street scene and P1 Ink ride still run after departure. This is not an open-world navigation feature or a walkable city.

## Play

- Use **WASD / arrow keys** for small, discrete on-foot steps inside the garage. R still restarts the current slice.
- Walk to the **workbench** and choose exactly one starter device (GPS, Translator, Radio); options become available only when nearby, and lock after choice.
- Walk to the **shift notice** and press **E** to read the inspection-hours warning. The fact is added once to authoritative knowledge and survives fresh saves.
- Walk to the **taxi door** with starter equipment prepared and press **E** or use **Pick up visitor**. The taxi route and Ink arrival then play as before.

Position, station distances and knowledge are authoritative in `GameSession`. `GarageView` contains only authored placeholder vector art and player representation; it does not decide whether an interaction is possible. Save schema moves to v3 (fresh saves only; no old-save migration).

P2.2 still needs **return to garage, repairs/upkeep and another shift**. P2.1 is not a complete day loop. P1 human pacing and real Windows gameplay acceptance remain pending.

## Extra persistence and camera checks

The garage walkthrough now saves after reading the notice and committing GPS, reloads the actual exported Web page, verifies the same noticeboard position and facts, then walks to the parked taxi. On departure the follow camera cuts immediately to the route's starting taxi rather than easing in from the room origin. P1 Ink mid-ride save/reload and completion remain part of the same browser gate.

## Validation evidence — October 15, 2026

- [Successful Godot 4.7.2 cross-platform CI #38650014827](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38650014827), gameplay head `40af8da8d7fbb864d8b5e03802e18413777701d1`. Editor import/parse, Ink compiler parity, native session + garage tests, Linux scene/export/boot, Windows export, real visible Linux native ride and Chromium Web gameplay all passed.
- Exported browser drove real WASD keys to each interactive station, selected GPS, read notice with E, saved while standing at the notice, reloaded the page, restored the *same garage position*, drove to taxi, and completed/loaded the original Ink ride. Web screenshots `garage-workbench.png`, `garage-notice.png`, `restored-garage.png`, `garage-taxi.png`, `ride-with-passenger.png` inspected.
- Action artifacts: **playable-ride-evidence** (screenshots), **outsider-driver-playtest-builds** (Windows x86_64, Linux x86_64, Web; 21-day retention).
- This is **functional technical/visual evidence** for a placeholder room, not a claim of finished character art, lived-in environmental richness, human pacing acceptance, or tested Windows execution. Issue #3 remains open.
