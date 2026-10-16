# Integrated city and player experience

Authority: the user's Autonomous Playability Reboot brief, 2026-10-16; issues #48–52. Architectural scope, inline implementation explicitly authorized without intermediate design approvals.

## Outcome
Launch in Player Mode at the inhabited Outer Margin garage. Discover genuine nearby demand, speak to a resident, accept an accessible fare, choose a route, observe smooth taxi travel through a recognizable curved multi-level city, converse during travel, arrive and settle exactly once. Debug Mode is a reversible presentation of the same world.

## Design
Reuse SandboxWorld, population, dispatch, social provenance, meetings, equipment, Ink and save validation. Separate region names, pickup/service stops and road junctions. Keep existing stop IDs where they still describe locations. Author shared metric Curve2D centerlines; derive time from sampled length and street speed. Use weighted shortest paths and explicit graph ramps. Visual crossings create no junction. NPC alternative trips use the same geometry.

Maintain the existing clock rate (one world minute per real second), improve route resolution to one minute, retain ten-minute population cadence. City scale and route alternatives create duration variation. Taxi relocation also traverses routes. Pending Ink survives arrival; an engaged pickup speaker does not abandon a conversation merely because the player reads slowly, while other NPCs continue.

Keep the debug scene/controller as an inspection adapter. Add a cohesive Player UI with compact status, contextual request/route/service/contact panels, shared controls and commands, passenger portrait, dialogue below the world, EN/Arabic and reduced motion. Render a 2D close-follow city with six distinct neighborhood palettes, harbor infrastructure, inhabited housing, landmarks, supported bridge decks and explicit ramps. No duplicate simulation.

## Reuse / replace / retire
Reuse domain services, once-only economics, causal NPC memory, glyph/translation rules, physical shops, knowledge-only AR, meetings, deterministic persistence. Replace five district-node geography, equal hop duration, instant reposition, schematic default view and fixed screen-coordinate Web tests. Retire old experimental save compatibility (new schema). Archived P0–P2 fixtures stay technical regression only.

## Evidence and delivery
Tests cover connectivity, curve distance/time, nonjunction crossings, ramps, physical taxi/NPC progress, reroute, replay, world preservation across mode toggle, Player fare and service flows, layout bounds, Arabic, readable travel Ink and safe arrival. Capture actual Linux and Web images, export Linux/Web/Windows, review branch diff, commit checkpoints, open PR, report engineering completion separately from human acceptance. No human acceptance invented.
