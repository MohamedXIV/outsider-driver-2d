# Routes P1 — Mid-trip Junction Reroute & Rider Preferences

> **Verified on October 16, 2026:** [#28](https://github.com/MohamedXIV/outsider-driver-2d/issues/28) builds directly on [Routes P0 #27](SANDBOX_ROUTES_P0.md). Green [Godot 4.7.2 CI #38809189586](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38809189586) on gameplay SHA `f17a4b4876190677b025d3d92b503c808a9f3522`: domain, historical P1/P2/S0–S3, Linux actual scene, Chromium real clicks, mid-trip save/reload, Linux/Web/Windows exports. **Windows execution and human gameplay/visual acceptance remain untested.** Documentation changes follow the tested gameplay head.

## Contract

- `SandboxWorld.queue_reroute(via)` validates a connected, simple **remaining path** starting at the NEXT physical junction (never from an imaginary instant jump). The active segment remains untouched. It rejects unreachable/cyclic/no-op routes and routes whose actual edge costs cannot be funded.
- `pending_route_nodes` is world-owned and snapshot-validated. On `_step_player_route`, the existing edge completes, incurs its actual toll/exposure once, then the queued suffix replaces the *remaining* route. `route_rerouted` records previous/new continuation. The route's original pickup/contract is still in its accepted offer and event history.
- One-step transport time is derived from the currently moving edge plus the queued continuation while pending. At each junction, the same authoritative state updates `route_nodes`, `route_segment`, `route_edge_elapsed`, and `remaining_minutes`; there is **no second journey clock or visual-only path**. Taxi presentation reads this route.
- `SandboxRiderRoutes` derives a single bounded route preference from the actual passenger's temperament and the authored road graph: cautious passengers prioritize lower checkpoint exposure, urgent passengers prioritize shorter trip time. If the driver has already selected a different path and an alternate remaining path exists, a passenger may ask. No hardcoded named passenger mission. The driver may **Honor** (queue passenger waypoint; trust +1) or **Refuse** (trust −1). All effects are traceable in the world event ledger and saved for subsequent relationships; deeper promises/memory remain #30.
- The taxi may traverse previous districts again as a legitimate physical detour, but each new remaining path must itself remain non-cyclic and fully connected. The **contracted destination never silently changes**: changing the actual passenger destination/fare contract requires a separately approved negotiation mechanic, not disguised mid-trip routing.
- If the speech language is not supported by S2's **current** comprehension model, the HUD shows a grounded **gesture pointing at a district**, not the untranslated reason or a free language-module unlock. Product binary language modules/localization still belong to #32–#33.
- The debug RoutePanel supports both user-chosen next-junction via and the separate passenger Honor/Refuse response, alongside the existing map pin. The queued route is highlighted differently, but UI and graphics remain provisional; no claim that the overlapping schematic layout is final.

## Supersession audit

**Reuse:** Existing `SandboxRoads` graph/edge weights and `SandboxWorld` source of truth, single farewell payment, S3 autonomous residents, S1 Ink acceptance and S2 historical knowledge proof.

**Replace:** Earlier 'waypoints only pre-acceptance' assumption. P1 adds an intentional pending-world state; it does NOT bring back the retired journey timer.

**Retire:** Nothing from historical clinic regression; it remains smoke-only. No premature language/romance/3D engine rewrite.

## Verification and known limits

- `tests/test_sandbox_reroute.gd`: 2 alternate genuine paths, next-junction application, no-op/cyclic rejection, funding, one-only fare, rider trust both ways, invalid snapshot rejection and same-state replay through save/load.
- `tests/test_sandbox_reroute_scene.gd`: actual native UI request→honor→save/reload→junction→arrival, with screenshots (`rider-reroute-queued.png`, `rider-reroute-junction.png`, `rider-reroute-arrived.png`).
- `tests/web_sandbox_reroute.cjs`: real Chromium map click to choose pre-trip Depot waypoint, accept real offer, honor gestured request, save/reload queued suffix, finish previous edge, follow actual replacement path and settle once. Screenshots (`rider-request-web.png`, `rider-queued-web.png`, `rider-junction-web.png`, `rider-arrived-web.png`).
- [Passing CI #38809189586](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38809189586) artifacts: **12007083688** (Linux/Windows/Web playtest exports) and **12007203747** (native/browser visual evidence), generally retained 21 days. Screenshots inspected and confirm HUD request, queued path, actual next-junction continuation and completion. No runtime Windows verification.
- **Not in P1:** traffic/road congestion AI, re-negotiating the destination or fare, relationship promises tracked across days, voiceover/glyph translators, live pedestrian navigation or final close-follow illustrated camera. The player's non-passenger **reposition** still uses a temporary atomic move.

**Next ready dependencies:** [#29 NPC-to-NPC witnessed interactions](https://github.com/MohamedXIV/outsider-driver-2d/issues/29), then [#30 personal memory/recognition](https://github.com/MohamedXIV/outsider-driver-2d/issues/30). Reevaluate next gameplay priorities from live issues before creating competing work.
