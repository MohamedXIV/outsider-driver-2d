extends SceneTree

# R05 #51: a physical, slower Outer Margin approach to Upper Terraces.
# No extra passenger, fabricated World time, or presentation-only shortcut.
func _initialize() -> void:
    assert(SandboxCityData.REGIONS.size() == 6)
    assert(SandboxCityData.STOPS.size() == 10)
    assert(SandboxRoads.LINKS.size() == 30)

    var ramp: Array[String] = ["cut", "east_service", "east_ramp_foot",
        "east_ramp_top", "upper_bend", "terraces"]
    assert(SandboxRoads.valid_path(ramp))
    assert(not SandboxRoads.connected("cut", "upper_bend"),
        "Map crossings never invent an unmarked junction")
    assert(not SandboxRoads.connected("east_ramp_foot", "upper_bend"),
        "The 180m climb requires the real graded ramp and crest")
    for i in range(ramp.size() - 1):
        var from: String = ramp[i]
        var to: String = ramp[i + 1]
        assert(SandboxRoads.connected(from, to) and SandboxRoads.connected(to, from))
        assert(not SandboxRoads.edge_data(from, to).is_empty())
        assert(SandboxRoads.edge_metres(from, to) > 1000.0)
        assert(SandboxRoads.sample_edge(from, to, 0.0).is_equal_approx(SandboxRoads.map_position(from)))
        assert(SandboxRoads.sample_edge(from, to, 1.0).is_equal_approx(SandboxRoads.map_position(to)))
    var ground: Vector3 = SandboxRoads.map_position("east_ramp_foot")
    var crest: Vector3 = SandboxRoads.map_position("east_ramp_top")
    assert(ground.y == 0.0 and crest.y == 180.0)
    assert(crest.y / (Vector2(crest.x - ground.x, crest.z - ground.z).length()) < 0.06,
        "Service ramp must have a real, bounded road grade")
    for sample in range(11):
        var at: Vector3 = SandboxRoads.sample_edge("east_ramp_foot",
            "east_ramp_top", float(sample) / 10.0)
        assert(at.y >= ground.y and at.y <= crest.y)

    var direct: Array[String] = SandboxRoads.path("garage", "terraces")
    var service: Array[String] = SandboxRoads.path("garage", "terraces", "east_ramp_foot")
    assert(SandboxRoads.valid_path(direct) and SandboxRoads.valid_path(service))
    assert(service != direct and service.has("east_service")
        and service.has("east_ramp_top") and service.has("upper_bend"))
    assert(not direct.has("east_ramp_foot"))
    var service_metres: float = SandboxRoads.path_metres(service)
    var service_minutes: int = SandboxRoads.path_minutes(service)
    assert(service_metres > 12000.0 and service_minutes > 20)
    assert(SandboxRoads.path_expense(service) == 0)
    assert(SandboxRoads.path("terraces", "garage", "east_ramp_foot").has("east_service"))

    # Player relocation is an actual World route with the same costs, clock,
    # persistence and full trace as any other city journey.
    var world: SandboxWorld = SandboxWorld.new(8)
    var original_credits: int = world.credits
    assert(world.reposition("terraces", "east_ramp_foot"))
    assert(world.route_nodes == service and world.remaining_minutes == service_minutes)
    assert(world.credits == original_credits - maxi(1, ceili(service_metres / 5000.0)))
    assert(world.advance(2))
    var restored: SandboxWorld = SandboxWorld.new()
    assert(restored.restore_snapshot(world.snapshot()))
    assert(restored.snapshot() == world.snapshot())
    assert(world.advance(world.remaining_minutes))
    assert(restored.advance(restored.remaining_minutes))
    assert(world.snapshot() == restored.snapshot())
    assert(world.player_district == "terraces" and not world.is_travelling())
    var completed: int = 0
    for event in world.events:
        if event["kind"] == "route_segment_completed":
            completed += 1
    assert(completed == service.size() - 1)
    assert(not world.events.any(func(event: Dictionary) -> bool:
        return event["kind"] == "fare_settled"), "Empty relocation cannot invent a fare")
    print("CITY_EAST_SERVICE_PASS ", JSON.stringify({
        "direct_nodes":direct, "direct_minutes":SandboxRoads.path_minutes(direct),
        "direct_metres":SandboxRoads.path_metres(direct),
        "service_nodes":service, "service_minutes":service_minutes,
        "service_metres":service_metres, "segment_events":completed
    }))
    quit()
