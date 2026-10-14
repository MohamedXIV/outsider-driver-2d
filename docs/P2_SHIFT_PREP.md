# P2.0 — Starter device preparation

## Playable slice

The opening **dockside garage prep panel** asks the player to choose **exactly one** working device before taking the clinic passenger. Pickup stays disabled until a valid choice. The choice cannot be swapped after commitment; **R** restarts the shift and clears it.

- **GPS** -> `map:inspection-arch`: a map reveals the inspection arch on the direct road; it does not magically know safe detours.
- **Translator** -> `translation:clinic-token`: decodes printed information on the visitor's clinic token, not all spoken languages by default.
- **Radio** -> `radio:two-local-languages`: exposes two alien-language stations and music, **not** English dialogue or illicit human stations.

A short contextual clue is visible in the HUD during the ride, so the choice changes the information the *player* receives now, not just an invisible future stat. The original authored passenger Ink choice can still add the distinct `docks-route` fact or suspicion independently. The equipment choice stays in the authoritative `GameSession`, not Ink or presentation nodes; the chosen fact and device survive save/reload. Double-selection, invalid gear and missing facts reject consistently.

## Persistence & tests

Fresh save schema is **v2** (`user://outsider_driver_ride_v2.json`); no migration from v1 was required. Tests cover all three device facts, one-time choice, forced preparation before pickup, invalid restore, preserved device across restored native/Web mid-ride and completed states, plus first-reveal HUD and true exported browser button input.

The existing Godot 4.7.2 native/Web test flow remains the release gate. Downloadable playtest builds from the new gate include this slice when the run succeeds. **Do not confuse an export or automated screenshot with a real human playtest.**

## Explicitly not included in P2.0

The physical walkable garage/apartment, recurring jobs, shift returns, repair costs and daily expenses belong to later P2 increments tracked in [P2 Issue #11](https://github.com/MohamedXIV/outsider-driver-2d/issues/11). The existing P1 human playtest [Issue #3](https://github.com/MohamedXIV/outsider-driver-2d/issues/3) remains open. No additional dialogue line has been authored in Ink for the devices yet; this slice gives player-visible information and persisted knowledge, not a new mission branch.
