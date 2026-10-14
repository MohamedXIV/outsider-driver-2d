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

var phase: RidePhase = RidePhase.WAITING
var starter_device: String = ""
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


func select_starter_device(device_id: String) -> bool:
	if phase != RidePhase.WAITING or not starter_device.is_empty() \
			or not STARTER_FACTS.has(device_id):
		return false
	starter_device = device_id
	known_facts.append(str(STARTER_FACTS[device_id]))
	return true


func pickup() -> bool:
	if phase != RidePhase.WAITING or starter_device.is_empty():
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
