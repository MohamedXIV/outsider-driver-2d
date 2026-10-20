# Genuine Main public shuttle continuation — Native

Runtime `df0b2c3468f2d9288300c30b7d29ade4e5c6ed90`, pinned Godot 4.7.2,
actual Main scene with automatic corridor. The observer selects seed9 and issues
one legitimate player reposition to the clinic. It leaves Main's ordinary real-
time processing running while the independent city creates the actual municipal
shuttle. No offer, resident, fare, cash or route progress is injected.

The six unedited viewport PNGs and corresponding full read-only World/pose JSON
show player departure, public shuttle approach, rider exit, immediate reload,
empty return and the real rider reaching intake. The same original shuttle
identity is asserted before/after passenger arrival; immediate Save/Load body and
resident poses are equal. The empty continuation adds no player fare settlement,
changes no player credits, and retains the nine existing residents. Source
observer is `.gd.txt`, outside production startup.

This source's full suites were not accepted: Domain exposed new event-float JSON
round-trip typing; Native exposed the same equality issue in peer-scene reload.
Those repros led to typed exact World serialization, retaining a checked readable
JSON copy, on the follow-up. A separate follow-up adds exclusive arrival-bay
admission; this quiet real-time sequence does not establish contested arrival
admission or exported Chromium acceptance. The wider city remains outside this
single authored clinic curb/empty-return slice.
