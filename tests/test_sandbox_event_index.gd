extends SceneTree

# The O(1) event indexes must always agree with a full scan of the ledger:
# after many autonomous ticks, after Save/Load, and after continuing to play.

func _initialize() -> void:
	var world: SandboxWorld = SandboxWorld.new(8)
	assert(world.event_count("fare_settled") == 0 and world.last_event("fare_settled").is_empty())
	assert(world.advance(6000))
	assert(world.events.size() > 100, "Need a non-trivial ledger to compare indexes against a scan.")
	_assert_matches_scan(world)

	var path: String = "user://sandbox-event-index.json"
	assert(SandboxSave.save_world(world, path))
	var restored: SandboxWorld = SandboxSave.load_world(path)
	assert(restored != null)
	assert(restored.events.size() == world.events.size())
	_assert_matches_scan(restored)

	# Indexes keep tracking events recorded after a restore, and stay in step with
	# a world that never went through Save/Load.
	assert(restored.advance(600) and world.advance(600))
	_assert_matches_scan(restored)
	_assert_matches_scan(world)
	assert(restored.events.size() == world.events.size())
	print("sandbox event index ok: %d events, %d kinds" % [
		world.events.size(), _kinds(world).size()])
	quit()


func _kinds(world: SandboxWorld) -> Dictionary:
	var kinds: Dictionary = {}
	for event in world.events:
		kinds[event["kind"]] = true
	return kinds


func _assert_matches_scan(world: SandboxWorld) -> void:
	var counts: Dictionary = {}
	var last: Dictionary = {}
	for event in world.events:
		var kind: String = str(event["kind"])
		counts[kind] = int(counts.get(kind, 0)) + 1
		last[kind] = event
		assert(world.event_by_id(str(event["id"])) == event)
	for kind in counts:
		assert(world.event_count(kind) == counts[kind])
		assert(world.events_of_kind(kind).size() == counts[kind])
		assert(world.last_event(kind) == last[kind])
	assert(world.event_count("no_such_kind") == 0)
	assert(world.last_event("no_such_kind").is_empty())
	assert(world.events_of_kind("no_such_kind").is_empty())
	assert(world.event_by_id("event:0").is_empty())
	assert(world.event_by_id("event:%d" % (world.events.size() + 1)).is_empty())
