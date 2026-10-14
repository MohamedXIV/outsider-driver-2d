class_name RideSave
extends RefCounted

const SAVE_PATH: String = "user://outsider_driver_ride_v3.json"
const VERSION: int = 3


static func save(session: GameSession, ink: Dictionary, path: String = SAVE_PATH) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"schema_version": VERSION,
		"game": session.snapshot(),
		"ink": ink
	}))
	file.close()
	return true


static func load(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		return {}
	if data.get("schema_version", 0) != VERSION 			or not (data.get("game", null) is Dictionary) 			or not (data.get("ink", null) is Dictionary):
		return {}
	return data
