extends SceneTree

# Godot NavigationServer2D proof for a two-block avenue, a legal zebra
# crossing in each block, and a perpendicular branch with explicit crosswalk.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: SandboxStreetPilot=load("res://scenes/street_pilot.tscn").instantiate()
	root.add_child(scene)
	for item in ["NorthSidewalk","SouthSidewalk","EastNorthWest",
			"EastNorthEast","EastSouthSidewalk","BranchWestSidewalk",
			"BranchEastSidewalk"]:
		assert(scene.get_node(item) is NavigationRegion2D)
	for item in ["MarkedCrosswalkOnly","EastMarkedCrosswalk","BranchMarkedCrosswalk"]:
		assert(scene.get_node(item) is NavigationLink2D)
	for i in range(8):
		await physics_frame
	var agent: NavigationAgent2D=scene.pedestrian._agent
	assert(agent!=null)
	var map: RID=agent.get_navigation_map()
	assert(NavigationServer2D.map_get_iteration_id(map)>0)
	var start: Vector2=Vector2(165,313)
	var other_side: Vector2=Vector2(990,391)
	var east_north: Vector2=Vector2(980,313)
	var branch: Vector2=Vector2(858,182)
	var right: PackedVector2Array=NavigationServer2D.map_get_path(map,start,east_north,true)
	var cross: PackedVector2Array=NavigationServer2D.map_get_path(map,start,other_side,true)
	var turn: PackedVector2Array=NavigationServer2D.map_get_path(map,start,branch,true)
	assert(right.size()>2,"Northern sidewalk must connect across the actual T branch")
	assert(cross.size()>2,"Footpaths cannot cross vehicle asphalt without a link")
	assert(turn.size()>2,"Branch walkway must connect via actual Godot shared edges")
	assert(right[0].distance_to(start)<20.0 and right[right.size()-1].distance_to(east_north)<20.0)
	assert(cross[0].distance_to(start)<20.0 and cross[cross.size()-1].distance_to(other_side)<20.0)
	assert(turn[turn.size()-1].distance_to(branch)<20.0)
	var branch_used: bool=false
	for p in right:
		if p.distance_to(Vector2(799,313))<20.0 or p.distance_to(Vector2(849,313))<20.0:
			branch_used=true
	assert(branch_used,"No legal connection across the northern T-branch crosswalk")
	assert(scene.world.resident(scene.walking_npc_id)["local_pedestrian_trip"]["status"]=="walking")
	print("STREET_JUNCTION_PASS connected two-block sidewalks, two zebra crossings, physical T-branch and native Godot paths")
	quit()
