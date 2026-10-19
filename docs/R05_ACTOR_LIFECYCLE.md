# R05 actor handoff continuity

A real garage-road departure unloads the bounded native street presenter at
its existing neighborhood threshold. Previously `_draw_people` also suppressed
all offscreen local pedestrians. This produced no representation at all until
native reentry. On local arrival the generic district marker could instead
appear at the garage node, away from the actual parts counter. Clinic alighting
had the same missing far representation.

`SandboxActorLifecycle.pose` is a read-only resolver for these existing resident
IDs. The far presenter and native reentry share the same event-owned route,
physical handoff anchor and offset merge. The city paints exactly one of the
native or far representations. A completed local errand remains at its authored
counter while the resident remains in that district; later independent transport
supersedes it. Clinic arrival enters the building, while later shuttle travel is
again rendered. No fade, replacement resident or settlement is introduced.

Alight handoffs now retain x/y in the World trip and handoff event. Restore
validates the anchor against the authored sidewalk, progress and event history.
Older version-12 handoffs without x/y retain their previous center-path fallback.
The native reentry samples the same fractional pose as the far renderer before
resuming the existing World trip. Native positions still determine genuine
local arrival; distant completion still uses the existing World minute policy.

## Evidence and checks

- `test_actor_lifecycle_scene`: real native motion, actual garage → margin gate →
  market route and existing unload threshold, exact physical anchor continuity,
  five sequential frames, World restore and fractional native reentry.
- `test_actor_lifecycle_pose`: two real seeded residents, distinct slots, anchors,
  interpolation, restore and counter arrival; population remains nine.
- `test_passenger_alight`: genuine completed medical fare, retained alight anchor,
  restored pose and rejected anchor forgery, exactly-once arrival/settlement.
- `test_actor_boundary_visual_scene`: controlled inspection at minimum supported
  zoom of the same genuine resident and authored road threshold. The five-frame
  [before](evidence/r05-2026-10-19/actor-before) and
  [after](evidence/r05-2026-10-19/actor-after) sequences share the same World minute,
  ID, handoff and camera. Baseline is `2dfbca5`; the center is empty before and the
  resident persists after. This controlled visual fixture does not claim a native
  collision-body trajectory; the separate scene test supplies that check.
- Web `actorLifecycle` is read-only JSON of IDs, World/render/viewport positions,
  presentation authority and visibility. Existing real-route Web captures retain
  this trace and reject duplicate identities/nonfinite coordinates.

## Authority and remaining scope

World remains the sole owner of identities, local trip transitions, event
provenance, economic route duration and settlements. Native actors execute
nearby walking; far views only sample those existing trips. No HUD files change.

This change resolves demonstrated pedestrian/alight representation gaps. It does
**not** implement the requested integrated World-owned native taxi/shuttle
collision corridor. Those vehicles retain their prior lane projections and
crossing reservations. No general physical delay contract, new junction
reservation policy or native shuttle body is claimed. Full R05 completion and
human driving/visual acceptance remain outstanding; #67/#68 stay open.
