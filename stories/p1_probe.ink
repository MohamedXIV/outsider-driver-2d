// Small authored P1.1 gate: a real Ink story, not an emulated dialogue table.
// Effect tags are information for GameSession. Ink does not mutate game state.
The visitor boards with a worn clinic token. "Night clinic, please. Do you know the road that avoids the inspection arch?"
* [Ask which service road the locals use.]
    # fact:docks-route
    "Northern service road. The clinic checkpoint gets quiet after shift change." The visitor studies your mirror. "You are new here, right?"
    -> END
* [Nod confidently and keep driving.]
    # suspicion:1
    "Quiet driver." The visitor studies your empty dashboard. "I hope you know where you are going."
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
