# Mid-minute handoff comparison

Before renderer: `64e941f21f2614faac7570e77eca77d3d537569e`.
After renderer and snapshot producer: `dd248439473482d86e577976d1bdeba87b228061`.
The runtime code at `7b4ebca` is identical to dd24843; its extra change is a Web
fixture synchronization fix. Godot 4.7.2, native compatibility renderer.

The strengthened actual-route native test moves the genuine resident, departs
Garage through Margin Gate, unloads the body at fraction 0.6, and saves the World
snapshot here. That original nonzero-fraction position assertion FAILS on 64e941f
and PASSES after timestamping. It also verifies real Save/Load and native reentry.

For this controlled five-frame comparison, both renderers load the SAME captured
snapshot. The old renderer ignores its new handoff timestamp. The pink cross is
a debug reference for the saved native anchor, not another actor. The first far
frame is displaced 31.725 projected pixels before the fix and zero afterward.
Both sequences retain World minute 485, `npc:02`, the same anchor and nine
residents. Subsequent fractions are 0.65, 0.70, 0.75 and 0.80. Rendering never
mutates the snapshot. The observer source and JSON traces are retained; pass `--snapshot=/absolute/path/world.json` and `--out=/absolute/output/path` after Godot's `--` to replay them.

This isolates timestamp interpretation in the native renderer; it is not an
independent physics playthrough or human visual acceptance. Actual-route Web
frames and the earlier native unload evidence are in sibling folders.
