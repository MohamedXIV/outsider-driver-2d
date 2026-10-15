class_name SandboxSave
extends RefCounted

const PATH: String = "user://outsider_driver_sandbox_v1.json"


static func save_world(world: SandboxWorld, file_path: String = PATH) -> bool:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(world.snapshot()))
	file.close()
	return true


static func load_world(file_path: String = PATH) -> SandboxWorld:
	if not FileAccess.file_exists(file_path):
		return null
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if not (value is Dictionary):
		return null
	var world: SandboxWorld = SandboxWorld.new()
	if not world.restore_snapshot(value):
		return null
	return world
