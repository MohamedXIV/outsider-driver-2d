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
