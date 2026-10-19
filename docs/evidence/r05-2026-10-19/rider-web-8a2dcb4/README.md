# Rider integration Web evidence

Runtime/source: `8a2dcb460d654ce2b82ba761e1255e77fe5571ca` (#75).
Pinned Godot 4.7.2, Playwright 1.56.0, Chromium build 1194.

The unchanged `tests/web_rider_initiative.cjs` passes against this head's fresh
Web export: actual seeded fare/passenger, pending question, IndexedDB Save/Load,
Arabic translation, real response button and once-only World answer. The focused
runner checks the immutable head and clean tracked tree before and after.
`verification.log` retains both completion markers. These three screenshots
show the English question, restored Arabic question and recorded answer.

This is the dedicated rider Web case, not a claim that all seven current-world
Web cases or CI have passed at this integration head. Full domain (43) and
native (41) suites pass separately. No HUD code is changed by this evidence.
