extends SceneTree
func _initialize() -> void:
	var graph: Dictionary=SandboxCityData.EDGES.duplicate(true)
	var supports: Array[Dictionary]=SandboxBridgePresentation.supports("bridge_east","bridge_west")
	assert(supports.size()>=3,"The elevated span needs visible structural support")
	for station in supports:
		assert(station["height"]>=80.0)
		for foot in station["feet"]:
			assert(SandboxBridgePresentation.footing_clear(foot),"No footing may obstruct the underpass carriageway")
	assert(SandboxBridgePresentation.thickness(0.0)==0.0)
	assert(SandboxBridgePresentation.thickness(160.0)==6.0)
	assert(not SandboxRoads.connected("basin_turn","bridge_east"))
	assert(SandboxCityData.EDGES==graph,"Presentation cannot invent a road connection")
	print("BRIDGE_STRUCTURE_PASS supported span, unobstructed ground carriageways, tapered ramp and graph preservation")
	quit()
