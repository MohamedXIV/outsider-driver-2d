# P1.2 — Passenger presentation (minimal 2D spritesheet)

## Scope

The dialogue is a lightweight Godot HUD on top of the ongoing 2D taxi world. No 3D passenger plane, Live2D rig, C++ deformation code or new animation framework.

- Passenger `assets/passengers/docks_visitor.svg` is a 4-frame horizontal **placeholder spritesheet** (neutral / curious / uneasy / speaking), imported as a Godot Texture2D.
- `PassengerPresenter` crops the imported sheet via Godot `AtlasTexture` and swaps expression frames through a small API.
- Optional `taxi_seat_frame.svg` is a 2D layered cabin/seat backdrop behind the portrait.
- `CheckButton` labeled `Show taxi cabin frame` changes only the presenter; choices/narrative/game world do not depend on the preference.
- Preference persists through `ConfigFile` in `user://passenger_presentation.cfg`.
- `scripts/main.gd` sends a minimal expression hint based on the selected authored Ink tag. This is strictly visual; GameSession consequences are a later milestone.

## Design intention

This is a **layout and API proof**, not approved production character art. Replace placeholder SVG artwork later without touching Ink or GameSession contracts. Higher-fidelity sprite atlas animation can be attached to the same presenter if characters justify it.

## Verification

A targeted Godot 4.7.2 native/Web run must prove:
1. Project imports the vector textures correctly and loads the atlas.
2. The passenger renders while world/camera/road continue moving.
3. The optional seat is toggled off and back on by a *real Chromium pointer click*; browser screenshots confirm both views.
4. Clicking an Ink choice after toggling still executes the intended story.
5. No Web export or scene runtime errors.

P1 ride lifecycle, arrival, fare, authoritative suspicion/facts and save/load remain pending. Never conflate these with UI proof.

## Verified evidence — 2026-10-14

[CI run #38623106414](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38623106414): **PASS**, Godot 4.7.2 on Linux.

- Godot import/parser, authored Ink branch tests, headless scene, Linux x86_64 export/boot, and Web export/Chromium run passed.
- Godot rendered the SVG 4-frame atlas and illustrated cabin background. UI frames were inspected.
- Browser test clicked the actual `Show taxi cabin frame` control twice, saw the state change through the Godot UI callback, then clicked the first Ink dialogue option successfully.
- [Screenshots: framed, avatar-only, and first choice](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38623106414/artifacts/11921814853).
- Taxi visibly continues along route between the captured screens; panel position and portrait expression are legible.

The `ConfigFile` store is implemented but **persistence across a browser restart has not been acceptance-tested yet**. That is a UI settings durability check for a later pass, not a claim that this artifact proves restart persistence.

Art, styling, scaling on small screens and character catalog remain open production work. This milestone proves only **replaceable rendering with a working visual preference**, not the final passenger UI.
