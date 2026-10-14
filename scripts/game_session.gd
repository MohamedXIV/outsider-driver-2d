class_name GameSession
extends RefCounted

# Canonical P1 ride state. UI, camera and Ink are consumers, never authorities.
enum RidePhase { WAITING, TRAVELING, ARRIVED, COMPLETED }

const PASSENGER_ID: String = "passenger:docks-visitor"
const JOB_ID: String = "job:docks-night-clinic"
const ROUTE_ID: String = "route:docks-clinic-overpass"
const FARE_CREDITS: int = 18
# Starter equipment provides one source of information, never an automatic translation
# of the city's foreign-language conversations.
const STARTER_FACTS: Dictionary = {
	"gps": "map:inspection-arch",
	"translator": "translation:clinic-token",
	"radio": "radio:two-local-languages"
}
const START_MINUTE: float = 8.0 * 60.0
# Coordinates are local to one small garage floor, not city navigation.
const GARAGE_START: Vector2 = Vector2(-0.6, 1.5)
const GARAGE_STEP: float = 0.65
const GARAGE_MIN: Vector2 = Vector2(-3.3, -2.7)
const GARAGE_MAX: Vector2 = Vector2(3.3, 2.7)
const INTERACT_RADIUS: float = 1.08
const WORKBENCH: Vector2 = Vector2(-2.3, -1.45)
const NOTICEBOARD: Vector2 = Vector2(0.1, -2.25)
const TAXI_DOOR: Vector2 = Vector2(2.45, 1.25)

var phase: RidePhase = RidePhase.WAITING
var starter_device: String = ""
var garage_position: Vector2 = GARAGE_START
var world_minutes: float = START_MINUTE
var credits: int = 0
var suspicion: int = 0
var known_facts: Array[String] = []
var applied_story_events: Array[String] = []
var ride: TaxiRide


func _init() -> void:
	ride = _create_ride()


func _create_ride() -> TaxiRide:
	var route: Array[Vector3] = [
		Vector3(-10, 0, 0), Vector3(-2, 0, 0), Vector3(3, 0, 0),
		Vector3(10, 0, 0), Vector3(10, 0, 6), Vector3(7, 0, 9),
		Vector3(3, 0, 9), Vector3(2, 1, 6), Vector3(2, 1, -6)
	]
	return TaxiRide.new(route)


func move_in_garage(direction: Vector2) -> bool:
	if phase != RidePhase.WAITING or not direction.is_finite():
		return false
	var next: Vector2 = garage_position + direction.limit_length(1.0) * GARAGE_STEP
	garage_position = next.clamp(GARAGE_MIN, GARAGE_MAX)
	return true


func near_garage_station(station: String) -> bool:
	if phase != RidePhase.WAITING:
		return false
	match station:
		"workbench":
			return garage_position.distance_to(WORKBENCH) <= INTERACT_RADIUS
		"noticeboard":
			return garage_position.distance_to(NOTICEBOARD) <= INTERACT_RADIUS
		"taxi":
			return garage_position.distance_to(TAXI_DOOR) <= INTERACT_RADIUS
	return false


func nearest_garage_station() -> String:
	# Interactions do not overlap at the authored stations.
	for id in ["workbench", "noticeboard", "taxi"]:
		if near_garage_station(id):
			return id
	return ""


func read_garage_notice() -> bool:
	if not near_garage_station("noticeboard"):
		return false
	if not known_facts.has("notice:inspection-shift"):
		known_facts.append("notice:inspection-shift")
	return true


func select_starter_device(device_id: String) -> bool:
	if not near_garage_station("workbench") or not starter_device.is_empty() \
			or not STARTER_FACTS.has(device_id):
		return false
	starter_device = device_id
	known_facts.append(str(STARTER_FACTS[device_id]))
	return true


func pickup() -> bool:
	if not near_garage_station("taxi") or starter_device.is_empty():
		return false
	phase = RidePhase.TRAVELING
	return true


func advance(delta: float) -> void:
	var elapsed: float = maxf(0.0, delta)
	# Conversation never stops city time; only the taxi stops at arrival.
	world_minutes += elapsed
	if phase == RidePhase.TRAVELING:
		ride.advance(elapsed)
		if ride.is_finished():
			phase = RidePhase.ARRIVED


func apply_story_tags(event_id: String, tags: Array) -> void:
	if event_id.is_empty() or applied_story_events.has(event_id):
		return
	applied_story_events.append(event_id)
	for tag in tags:
		var value: String = str(tag)
		if value.begins_with("fact:"):
			var id: String = value.trim_prefix("fact:")
			if not id.is_empty() and not known_facts.has(id):
				known_facts.append(id)
		elif value.begins_with("suspicion:"):
			suspicion = maxi(0, suspicion + int(value.trim_prefix("suspicion:")))


func drop_off() -> bool:
	if phase != RidePhase.ARRIVED:
		return false
	phase = RidePhase.COMPLETED
	credits += FARE_CREDITS
	return true


func snapshot() -> Dictionary:
	return {
		"passenger_id": PASSENGER_ID,
		"job_id": JOB_ID,
		"route_id": ROUTE_ID,
		"starter_device": starter_device,
		"garage_position": [garage_position.x, garage_position.y],
		"phase": int(phase),
		"world_minutes": world_minutes,
		"credits": credits,
		"suspicion": suspicion,
		"known_facts": known_facts.duplicate(),
		"applied_story_events": applied_story_events.duplicate(),
		"ride": ride.snapshot()
	}


func restore_snapshot(value: Dictionary) -> bool:
	if value.get("passenger_id") != PASSENGER_ID 			or value.get("job_id") != JOB_ID or value.get("route_id") != ROUTE_ID:
		return false
	var restored_phase: int = int(value.get("phase", -1))
	if restored_phase < 0 or restored_phase > int(RidePhase.COMPLETED):
		return false
	var gear_id: String = str(value.get("starter_device", ""))
	if (not gear_id.is_empty() and not STARTER_FACTS.has(gear_id)) \
			or (restored_phase != int(RidePhase.WAITING) and gear_id.is_empty()):
		return false
	var garage: Variant = value.get("garage_position", null)
	if not (garage is Array) or garage.size() != 2:
		return false
	var pos: Vector2 = Vector2(float(garage[0]), float(garage[1]))
	if not pos.is_finite() or pos != pos.clamp(GARAGE_MIN, GARAGE_MAX):
		return false
	var fresh_ride: TaxiRide = _create_ride()
	if not fresh_ride.restore_snapshot(value.get("ride", {})):
		return false
	if not value.get("known_facts", null) is Array 			or not value.get("applied_story_events", null) is Array:
		return false
	if not gear_id.is_empty() and not value["known_facts"].has(str(STARTER_FACTS[gear_id])):
		return false
	ride = fresh_ride
	phase = restored_phase as RidePhase
	starter_device = gear_id
	garage_position = pos
	world_minutes = float(value.get("world_minutes", START_MINUTE))
	credits = maxi(0, int(value.get("credits", 0)))
	suspicion = maxi(0, int(value.get("suspicion", 0)))
	known_facts.clear()
	for item in value["known_facts"]:
		known_facts.append(str(item))
	applied_story_events.clear()
	for item in value["applied_story_events"]:
		applied_story_events.append(str(item))
	return true
