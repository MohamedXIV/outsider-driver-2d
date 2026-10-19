# Archived fixture canvas synchronization

At `4fb425b`, the unchanged archived ride test timed out waiting for `completed` after its second arrival choice. The first arrival path captures a screenshot before choosing; the second path sent the click immediately after the logical Ink flag. Godot publishes that flag before deferred VBox layout paints the replacement choice buttons.

The test now requires the visible two-choice arrival frame, waits two browser animation frames, then sends the same real click. All 15/60-second waits, fare/repair/persistence assertions and real input coordinates remain unchanged. No frozen fixture gameplay or HUD presentation code changed.

The focused complete two-shift fixture flow passed normally and with CDP CPU throttling set to 6 before the second arrival interaction. `stress.patch` records that diagnostic-only change. These are archived fixed-clinic fixture results; they are **not** evidence of the product's genuine two-resident fares. The original failed run is retained and must not be relabelled as a pass. A fresh immutable-head fixture gate is still required after this commit.

The earlier candidate CI run 39316433668 was cancelled after its Godot stage when this test correction became necessary. Its overall result is CANCELLED, not an accepted full gate.
