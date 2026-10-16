class_name SandboxLocalPedestrianTrip
extends RefCounted

# A genuine resident's local errand belongs to SandboxWorld. Godot agents own
# visible movement; the world validates and records intent and arrival once.
# This bounded experiment does not change city-wide taxi offer/route semantics.
const PATCHWORKS_PARTS: String = "patchworks:parts_counter"

static func begin(world: SandboxWorld, npc_id: String, site: String) -> bool:
	if site != PATCHWORKS_PARTS:
		return false
	var npc: Dictionary = world.resident(npc_id)
	if npc.is_empty() or str(npc.get("location", "")) != "garage":
		return false
	if not npc.get("local_pedestrian_trip", {}).is_empty():
		return false
	# A nearby service errand does not erase the resident's independent long
	# distance need or authorize the player to accept a licensed taxi fare.
	npc["local_pedestrian_trip"] = {"site": site, "status": "walking", "started": world.minute}
	world._record("local_pedestrian_departed", npc_id, {"from": "garage", "site": site})
	return true

static func arrive(world: SandboxWorld, npc_id: String, site: String) -> bool:
	var npc: Dictionary = world.resident(npc_id)
	if npc.is_empty():
		return false
	var trip: Dictionary = npc.get("local_pedestrian_trip", {})
	if trip.get("site", "") != site or trip.get("status", "") != "walking":
		return false
	# This counter is a local site inside the garage's coarse world location.
	# It does not teleport an NPC between dispatch/region graph nodes.
	trip["status"] = "arrived"
	trip["arrived"] = world.minute
	npc["local_pedestrian_trip"] = trip
	world._record("local_pedestrian_arrived", npc_id, {"site": site})
	return true
