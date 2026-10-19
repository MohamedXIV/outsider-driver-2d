class_name SandboxSave
extends RefCounted

const PATH: String = "user://outsider_driver_sandbox_v12.json"
const VERSION: int = 12


static func save_world(world: SandboxWorld, file_path: String = PATH, dialogue: Dictionary = {}, presentation: Dictionary = {}) -> bool:
	# Do not overwrite a recoverable save with a native view missing an active
	# resident's physical state. Loading it would otherwise rewind that body.
	if not SandboxLocalPedestrianTrip.valid_presentation(world,presentation.get("street_state",{})) \
			or not SandboxPassengerAlight.valid_presentation(world,presentation.get("alight_state",{})) \
			or not _valid_taxi_heading(presentation): return false
	var stored_presentation: Dictionary=presentation.duplicate(true)
	if stored_presentation.has("clock_fraction"):
		var fraction: Variant=stored_presentation["clock_fraction"]
		if not (fraction is float or fraction is int) or not is_finite(float(fraction)) \
				or float(fraction)<0.0 or float(fraction)>=1.0: return false
		# Both JSON formatting and Godot's number parser can round a valid
		# fraction one ULP below 1 up to 1. Keep a one-picosecond presentation
		# margin; never change the authoritative World minute/event ledger.
		stored_presentation["clock_fraction"]=minf(float(fraction),0.999999999999)
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": VERSION, "world": world.snapshot(), "dialogue": dialogue, "presentation": stored_presentation}))
	file.close()
	return true


static func load_bundle(file_path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	# The world ledger uses integer ticks, money, IDs and counters. JSON's
	# decoder materializes numeric literals as float, so restore canonical
	# integral values before replaying or comparing deterministic state.
	value = _canonical_json_numbers(value)
	if not (value is Dictionary) or int(value.get("version", -1)) != VERSION:
		return {}
	if not (value.get("world") is Dictionary) or not (value.get("dialogue") is Dictionary):
		return {}
	var world: SandboxWorld = SandboxWorld.new()
	if not world.restore_snapshot(value["world"]):
		return {}
	var presentation: Variant=value.get("presentation",{})
	if not (presentation is Dictionary): return {}
	if not ["en","ar"].has(presentation.get("locale","en")) or not (presentation.get("reduced_motion",false) is bool): return {}
	var zoom: Variant=presentation.get("camera_zoom",2.6)
	if not (zoom is float or zoom is int) or not is_finite(float(zoom)) or float(zoom)<1.25 or float(zoom)>4.0: return {}
	if not SandboxLocalPedestrianTrip.valid_presentation(world,presentation.get("street_state",{})) \
			or not SandboxPassengerAlight.valid_presentation(world,presentation.get("alight_state",{})) \
			or not _valid_taxi_heading(presentation): return {}
	var fraction: Variant=presentation.get("clock_fraction",0.0)
	if not (fraction is float or fraction is int) or not is_finite(float(fraction)) or float(fraction)<0 or float(fraction)>=1: return {}
	return {"world": world, "dialogue": value["dialogue"], "presentation":presentation}


static func _valid_taxi_heading(presentation: Dictionary) -> bool:
	# Optional for previous experimental saves; never trust forged NaN/rotation.
	if not presentation.has("taxi_heading"): return true
	var value: Variant = presentation["taxi_heading"]
	return (value is float or value is int) and is_finite(float(value)) \
			and float(value) >= -PI and float(value) <= PI


static func load_world(file_path: String = PATH) -> SandboxWorld:
	var bundle: Dictionary = load_bundle(file_path)
	return bundle.get("world") as SandboxWorld


static func _canonical_json_numbers(value: Variant) -> Variant:
	if value is float and value == floorf(value):
		return int(value)
	if value is Array:
		var values: Array = []
		for item in value:
			values.append(_canonical_json_numbers(item))
		return values
	if value is Dictionary:
		var values: Dictionary = {}
		for key in value:
			values[key] = _canonical_json_numbers(value[key])
		return values
	return value
