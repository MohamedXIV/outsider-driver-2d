# Integrated city playtest — October 16, 2026

This is one integrated build for human evaluation. Player Mode is the default.
Human pacing, comfort and visual appeal are **not accepted** by automated checks.
Windows is exported, not runtime tested.

## Play

- Linux: extract the build, keep the `.pck` beside the executable, then run `./outsider-driver.x86_64`. If needed, `chmod +x outsider-driver.x86_64`.
- Windows x86_64: keep the `.exe` and `.pck` together, launch the executable. Actual Windows gameplay remains unverified.
- Web: serve the `web` directory (`python3 -m http.server 8765 --directory web`), then open `http://localhost:8765/index.html` in a WebGL-capable browser. Opening the HTML as a file does not work.
- GitHub run: download **outsider-driver-integrated-builds** for all three platforms; **city-playability-evidence** contains actual native/Web screenshots and logs. Retention is 21 days.

## First shift

You live at Patchworks Garage in the inhabited Outer Margin. A real seeded resident may be hailing locally. **Street → Speak to the resident → ask/request Common or accept**. Common is preinstalled; Local and Cant remain alien scripts without their installed modules or that individual's explicit agreement to speak Common.

**Gear** offers one free GPS / Local module / Radio bonus. Market purchases require physically reaching Concourse Market during 06:00–20:00, sufficient money and remaining stock. Purchase and installation are separate actions. AR eyewear can show only acquired, sourced information, including explicitly uncertain hearsay.

Bright rings on the map show currently visible, accessible requests; licensed-only dispatch remains unavailable. Use **Map** to choose a destination or a waypoint for the selected fare. Routes use actual connected roads. During a fare, a new route is queued until the next junction; passenger preferences can be honored or refused. For empty relocation, add several waypoints in order and drive the resulting path. Invalid or unaffordable routes are rejected.

While driving, **Street → Talk to your passenger** opens reusable travel Ink. The city continues moving. Arrival settles the fare once and leaves the current conversation readable until you choose quiet. Other residents continue their own needs, work, contacts and travel. Repeated genuine trips can create recognition and optional appointments in **Contacts**.

**Options** contains EN/Arabic, reduced motion, Save and Load. Web persistence flushes asynchronously; allow about two seconds after Save before closing/reloading the page. Save includes fractional movement progress and an open Ink frame. Saves from older experimental schemas are intentionally not loaded.

**Debug / F3** switches presentation without changing the world. Existing seed/time/observe, route, equipment, provenance and social diagnostics remain available. The old dashboard is a developer view.

## City and pacing

Six separate regions, 27 physical road nodes, ten service stops and 32 explicit curved edges adapt the recovered charter-port foundation. Cargo routes connect the Docks and Worker Belt; Old Junction and its viaduct lead toward Civic Core and the more controlled Upper Terraces. Patchworks, Lantern Row and The Cut anchor the Outer Margin. District materials, building silhouettes, market awnings, water, grounded vehicles and supported decks are lightweight 2D placeholders.

Travel time is calculated from sampled curved metres and posted speeds (16–40 km/h), including vertical distance. The existing clock rate remains **one world minute per real second**; resolution is now one minute. Examples:

- Garage → Mutual Aid Hall: 9 minutes.
- Garage → Concourse Market: 6.49 km / 23 minutes, no toll.
- Garage → Concourse Market via Refit Depot: 28.16 km / 72 minutes, 3 credits tolls.
- Garage → Terrace Estate Gate: 22.1 km / 58 minutes.

World positions drive taxi and autonomous NPC presentation. Visual widths and building sizes are stylized for readability. Crossings do not create graph links; ramps explicitly connect ground and deck.

A route available through the multi-waypoint planner demonstrates ground → underpass → ramp → deck → descent:
`clinic → basin_turn → market → old_square → margin_gate → bridge_east → bridge_west → worker_gate → depot`.
Choose Refit Depot from Night Clinic, then add Cargo Basin Bend, Concourse Market, Patchworks Feeder, East Viaduct and West Viaduct in order. The graph and funds checks remain authoritative.

## Reproduce technical checks

Use Godot **4.7.2 standard**, matching Linux/Windows/Web export templates, InkJS 2.4.0 and Playwright 1.56.0.

```sh
GODOT_BIN=/path/to/godot python3 tests/run_city_gate.py
GODOT_BIN=/path/to/godot LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a python3 tests/run_city_gate.py --native
/path/to/godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8765 --directory build/web
# In another terminal, with Playwright available in NODE_PATH:
node tests/web_city_playability.cjs
```

The manually dispatched `.github/workflows/p1-ink.yml` runs these current gates, checks compiled Ink, exports Linux/Windows/Web and uploads builds/evidence. Earlier five-stop Web scripts and their old CI history remain historical evidence; this gate replaces their hardcoded dashboard coordinates and obsolete route assumptions. Frozen P0–P2 engine/Ink/session tests remain in the current VM gate.

## Evidence and remaining evaluation

VM domain/adapters: 25 scripts passed, including multi-seed idle-day replay, source-backed peers/AR, language purchases/install, returning passenger and meetings. Native rendered gate: 11 scripts, including the frozen ride fixture and all nine shared-controller sandbox scenes plus the integrated city capture. New Player checks cover reversible modes, unchanged world, touch targets, four viewport sizes, real meeting choices, malformed saves and fractional journey reload.

Native captures `01`–`11` include default Outer Margin, passenger, Debug, travelling, readable arrival, basin underpass, rising ramp, deck, connected descent, Worker Belt arrival and Arabic. Each has an adjacent JSON record of the authoritative position/route. Chromium also completed two genuine fares: 28.16 km / 72 minutes through the Depot and a 13.97 km / 35 minute Market-to-Depot ride, each with live travel Ink and once-only payment. Chromium exercises actual pointer input, browser reload, live travel dialogue and arrival, locale/mode switching, physical market purchases/install/AR, scrolling and a narrow layout. See the attached run logs for the exact build and results.

No user evaluation of this build has occurred. Please try one fare with passenger conversation and one longer route; report how the camera, reading time and controls feel. Nine persistent residents and placeholder art are a bounded city slice, not a finished populated metropolis. Broader content, production artwork, tuning and real Windows execution remain open.
