// Small authored P1.1 gate: a real Ink story, not an emulated dialogue table.
// Effect tags are information for GameSession. Ink does not mutate game state.
The passenger watches the harbor lights.
* [Ask about the docks]
    # fact:docks-route
    The clinic checkpoint is safest from the northern service road.
    -> END
* [Keep driving quietly]
    # suspicion:1
    Quiet driver. I like that.
    -> END

// The player opts into this authored exit after arrival. Never interrupt a live line.
=== arrival ===
The taxi idles outside the night clinic. The visitor looks toward the entrance.
# arrival:offer
* [We've arrived.]
    # arrival:complete
    "Thank you, driver. The quiet road was a kindness."
    -> END
* [Take your time.]
    # arrival:complete
    "Just one more breath. All right. Thank you."
    -> END
