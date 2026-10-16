# Execution ledger

- 1bf7687: live audit and preserved read-only PR84 design sources; integrated spec/plan.
- Task 2: graph test first failed for missing city/geometry API, then passed: six regions, 27 nodes, 22.1 km / 58 min long route versus 9 min short route. Physical journey test failed for absent movement API, then passed relocation, NPC co-movement, mid-edge deterministic replay and once-only fare.
- Task 3: Player Mode test first failed for missing adapter, then passed default Player Mode, reversible Debug Mode and unchanged world snapshot. Rendering/interaction evaluation in progress.
- Task 4: travel conversation test first failed because reading expired the pickup; passed after protected engagement and separate reusable travel Ink. Completed arrival preserves choices.

## Rulings

- User brief authorizes implementation without intermediate design approvals, superseding generic brainstorming approval gates. Sole implementer; no implementation subagents.
- Clock remains one world minute per real second; simulation resolution changed from ten to one minute. Residents retain ten-minute routine cadence.
- Legacy `player_district` / `DISTRICTS` names remain API compatibility names for physical road node / service stops. Regions are separately authored in SandboxCityData.
- Save schema 12 is intentionally incompatible with old experimental saves.
- Old five-node fixtures require deliberate geographic updates; retain tests for economics, provenance, knowledge and social causality.
- Xvfb installed into workspace by extracting a Debian package checked against signed apt metadata; no system modifications.

## Review and integrated verification

- Fresh read-only reviewer found: relocation ignored its previewed waypoint; Player meeting controls copied queued debug children; malformed save arrays and missing passenger tag needed rejection. Fixed with failing-then-passing focused tests; reviewer confirmed fixes and no remaining important finding in reviewed changes.
- Added explicit multi-waypoint planner and a playable clinic/basin/market/margin/ramp/deck/Worker Belt sequence. No inferred crossing links.
- Browser resizing exposed project-level fixed-aspect letterboxing. Disabled fixed canvas scaling so responsive Player controls retain actual window pixel sizes. Narrow pointer/Arabic check included in Web gate.
- UI refresh signatures now depend on the active panel's context; unrelated world ticks and background translation no longer rebuild map/settings controls mid-interaction.
- Current canonical gate: tests/run_city_gate.py (domain/adapters), same with --native (Xvfb rendered scenes), web_city_playability.cjs and web_city_routes.cjs. Original five-stop Web scripts are historical, not a gate for this new topology. No assertions about provenance, once-only money, language access or social memory were retired.
- Four Ink source/JSON pairs match pinned InkJS 2.4.0.
- VM: Linux and Windows exports succeeded; Linux exported executable booted. Windows runtime not attempted.

- Actual exported Chromium two-fare evidence: garage→market via depot, 28,155.83 m / 72 minutes; later genuine market→depot request, 13,966.37 m / 35 minutes. Both had travel Ink and settled once. NPCs did not generate a local fare while at work; the test used the real Wait command until a genuine available request emerged, rather than manufacturing demand.
- Visual review caught Player theme inheritance and Latin fallback defects despite the existing dialogue font tests. Added actual-control Arabic/Latin font regression and visually inspected a corrected 720×900 native frame.
- Native static scenery now uses retained CanvasItem layers with separate physical actor layers; draw ordering and world immutability regression passed. Reviewer found no important layer-init/depth issue. Contacts availability cache omission fixed after observed RED regression.

- Final targeted review found no remaining important issue; minor invalid map preview fallback corrected (invalid waypoint now highlights no unrelated route and Drive stays disabled).
- Travel speech refreshes the current region before a later choice, including after arrival; observed failing test then passed. Route preview graphics now use the same planned path as cost/time/command validation.
- Final native/domain gates: 25 domain/adapters plus 11 rendered scripts. Browser controls wait for actual engine action acknowledgments, including return from Debug Mode, rather than assuming a fixed frame delay.

## Final delivery

- Code frozen at `52fd490cf009d052ea2c1c3e16f68a319a504dfd`; PR #55 reviewed and left unmerged for final user review.
- Single final CI run 38919427433 PASS: all 36 scripts, four Ink/source pairs, both real Chromium suites, Linux/Windows/Web exports and Linux boot.
- Artifacts: integrated builds 12054755010 (80,574,159 bytes), evidence 12054118689 (3,886,802 bytes); downloaded package contents and source SHA verified. All 36 CI script logs contain completion markers and no script/error lines; actual narrow Arabic and deck PNGs inspected.
- Individual evidence comments posted to #49–52; #23 closed as completed engineering (all #32–34 already closed); #48/#15 updated and remain open. Original feedback remains unchanged and every FB status is ready for human check, not accepted.
- Local generated untracked Godot sidecars removed after verification. Final docs-only delivery commit follows the tested code; no second Actions run is needed for those links/status notes.
