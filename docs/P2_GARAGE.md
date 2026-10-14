# P2.1 — Bounded walkable garage

The player's first shift now starts **inside one authored 2D isometric garage**. The existing P0 street scene and P1 Ink ride still run after departure. This is not an open-world navigation feature or a walkable city.

## Play

- Use **WASD / arrow keys** for small, discrete on-foot steps inside the garage. R still restarts the current slice.
- Walk to the **workbench** and choose exactly one starter device (GPS, Translator, Radio); options become available only when nearby, and lock after choice.
- Walk to the **shift notice** and press **E** to read the inspection-hours warning. The fact is added once to authoritative knowledge and survives fresh saves.
- Walk to the **taxi door** with starter equipment prepared and press **E** or use **Pick up visitor**. The taxi route and Ink arrival then play as before.

Position, station distances and knowledge are authoritative in `GameSession`. `GarageView` contains only authored placeholder vector art and player representation; it does not decide whether an interaction is possible. Save schema moves to v3 (fresh saves only; no old-save migration).

P2.2 still needs **return to garage, repairs/upkeep and another shift**. P2.1 is not a complete day loop. P1 human pacing and real Windows gameplay acceptance remain pending.
