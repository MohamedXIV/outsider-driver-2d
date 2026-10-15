class_name SandboxSave
extends RefCounted

const PATH: String = "user://outsider_driver_sandbox_v6.json"
const VERSION: int = 6


static func save_world(world: SandboxWorld, file_path: String = PATH, dialogue: Dictionary = {}) -> bool:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": VERSION, "world": world.snapshot(), "dialogue": dialogue}))
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
	return {"world": world, "dialogue": value["dialogue"]}


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
