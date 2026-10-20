# Genuine Main clinic arrival — Native

Runtime source: `e0ef24cfa0a8413cb76ef18060cc02a596c8f91c`, Godot
4.7.2 official Linux, actual `scenes/sandbox.tscn`, automatic corridor enabled.
The observer selects seed9, accepts its existing garage medical offer through
World, and then lets Main's normal real-time processing run. It does not inject
residents, fares, money or route cursor values. Nine residents, one settlement.

Six raw viewport PNGs show departure, approach, curb/rider transfer, reload,
walking and intake. Matching JSON contains read-only World snapshots, canonical
and render poses, loaded real vehicle IDs and alight identity/position. The
observer also asserts immediate pre/post Load taxi and walker equality. Source
is retained as `.gd.txt` so the evidence observer cannot alter production startup.

The old source geometry placed the walker 43.3316 pixels away from the incoming
lane endpoint. New physically executed arrivals first reach the authored clinic
curb; the walker starts 14 pixels outside that stopped vehicle centre, clearing
both footprints, and walks to intake. There is no fade or fabricated settlement.

This sequence verifies the taxi/medical-rider clinic boundary. It does not prove
all shuttle arrival boundaries, camera thresholds, or full R05 acceptance. Full
Domain passed on this source head; full Native exposed the separate historical
planned-duration assumption in integration_actor_lifecycle (recorded as FAIL,
subsequently corrected to wait for genuine bounded World delay). Chromium 6/6
passed on the earlier automatic-corridor head 94f1f72; these images are not a
substitute for Chromium verification of the curb changes.
