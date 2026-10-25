extends SceneTree

# Golden snapshot harness (Epic R01). Behaviour-preserving refactors must keep
# these hashes byte-identical. Regenerate ONLY for an intentional behaviour
# change: GOLDEN_UPDATE=1 godot --headless --script res://tests/test_golden_world.gd
const GOLDEN_PATH: String = "res://tests/golden/world_hashes.json"
const SEEDS: Array[int] = [1, 8, 9]
const OFFSETS: Array[int] = [0, 600, 6000]

var _failed: bool = false


static func world_hash(world: SandboxWorld) -> String:
	return JSON.stringify(world.snapshot(), "", true, true).sha256_text()


func _initialize() -> void:
	var update: bool = OS.get_environment("GOLDEN_UPDATE") == "1"
	if update and not OS.get_environment("CI").is_empty():
		_fail("GOLDEN_UPDATE refused in CI")
		return
	var actual: Dictionary = {}
	for seed_value in SEEDS:
		var world: SandboxWorld = SandboxWorld.new(seed_value)
		var elapsed: int = 0
		for offset in OFFSETS:
			if offset > elapsed:
				if not world.advance(offset - elapsed):
					_fail("advance refused seed %d to %d" % [seed_value, offset])
					return
				elapsed = offset
			actual["seed%d@%d" % [seed_value, offset]] = world_hash(world)
	var scripted: SandboxWorld = _scripted_scenario()
	if scripted == null:
		return
	actual["scenario8"] = world_hash(scripted)
	if not _round_trip(scripted, actual):
		return
	if update:
		var out: FileAccess = FileAccess.open(GOLDEN_PATH, FileAccess.WRITE)
		out.store_string(JSON.stringify(actual, "\t", true))
		out.close()
		print("GOLDEN_UPDATED %d hashes" % actual.size())
		quit(0)
		return
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	if not expected is Dictionary:
		_fail("missing golden file; run with GOLDEN_UPDATE=1")
		return
	for key in actual:
		if not expected.has(key):
			_fail("golden missing key %s" % key)
			return
		if expected[key] != actual[key]:
			_fail("hash drift at %s" % key)
			return
	if expected.size() != actual.size():
		_fail("golden has stale keys")
		return
	print("PASS golden world")
	quit(0)


func _scripted_scenario() -> SandboxWorld:
	var w: SandboxWorld = SandboxWorld.new(8)
	var chosen: Dictionary = {}
	for offer in w.open_offers():
		if offer["origin"] == w.player_district and offer["channel"] != "official":
			chosen = offer
			break
	if chosen.is_empty() or not w.accept(str(chosen["id"])):
		_fail("scenario: no accessible local offer")
		return null
	var trip: int = SandboxRoads.travel_minutes(str(chosen["origin"]), str(chosen["destination"]))
	if not w.advance(trip):
		_fail("scenario: trip advance refused")
		return null
	if w.offer_by_id(str(chosen["id"]))["status"] != "completed":
		_fail("scenario: fare not settled")
		return null
	var target: String = "market" if w.player_district != "market" else "docks"
	if not w.reposition(target):
		_fail("scenario: reposition refused")
		return null
	w.advance(SandboxRoads.travel_minutes(w.player_district, target))
	for offer in w.open_offers():
		if w.decline(str(offer["id"])):
			break
	for language in SandboxKnowledge.MODULE_PRICES:
		if w.buy_language_module(language):
			w.install_language_module(language)
			break
	w.advance(600)
	return w


func _round_trip(w: SandboxWorld, actual: Dictionary) -> bool:
	var path: String = "user://golden-round-trip.json"
	if not SandboxSave.save_world(w, path):
		_fail("round trip: save failed")
		return false
	var restored: SandboxWorld = SandboxSave.load_world(path)
	if restored == null:
		_fail("round trip: load failed")
		return false
	if world_hash(restored) != world_hash(w):
		_fail("round trip: restored hash differs")
		return false
	w.advance(600)
	restored.advance(600)
	if world_hash(restored) != world_hash(w):
		_fail("round trip: continued play diverged")
		return false
	actual["scenario8+600"] = world_hash(w)
	return true


func _fail(message: String) -> void:
	_failed = true
	print("FAIL golden world: %s" % message)
	quit(1)
