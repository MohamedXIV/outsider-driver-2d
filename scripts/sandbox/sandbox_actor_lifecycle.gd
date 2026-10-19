class_name SandboxActorLifecycle
extends RefCounted

# Read-only low-fidelity counterpart of a genuine native resident. The same
# ID and event-owned route survive removal of a proximity-loaded body.
static func pose(world: SandboxWorld, npc: Dictionary, fraction: float=0.0) -> Dictionary:
	var trip: Dictionary=npc.get("local_pedestrian_trip",{})
	var status: String=str(trip.get("status",""))
	if status in ["offscreen","arrived"] and npc.get("location","")=="garage" \
			and int(npc.get("transit_until",0))==0 and str(npc.get("taxi_offer","")).is_empty():
		var at: Vector2=SandboxLocalPedestrianTrip.offscreen_position(world,str(npc["id"]),fraction) \
				if status=="offscreen" else SandboxStreetModule.destination(int(trip.get("slot",0)))
		return {"id":str(npc["id"]),"kind":"local_pedestrian","position":
				SandboxStreetRouteBinding.street_transform()*at,"elevated":false,"slot":int(trip.get("slot",0))}
	var alight: Dictionary=npc.get("passenger_alight",{})
	if alight.get("status","")=="offscreen":

		return {"id":str(npc["id"]),"kind":"alight","position":SandboxPassengerAlight.offscreen_position(world,str(npc["id"]),fraction),
				"elevated":false,"slot":0}
	return {}
