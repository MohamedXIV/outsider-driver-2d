extends SceneTree

# A municipal shuttle is the actual alternative transit of an existing
# resident after an offer expires, never an extra fabricated taxi or NPC.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var selected: SandboxWorld=null
	var passenger_id: String=""
	# Let the real dispatch/autonomy ecology produce an expired offer and
	# independently choose a shuttle. No edits to population/trip fields.
	for seed in range(8,25):
		var candidate: SandboxWorld=SandboxWorld.new(seed)
		for step in range(95):
			assert(candidate.advance(1))
			for npc in candidate.residents:
				if str(npc.get("transit_method",""))=="shuttle" \
						and int(npc.get("transit_until",0))>candidate.minute:
					selected=candidate
					passenger_id=str(npc["id"])
					break
			if selected!=null: break
		if selected!=null: break
	assert(selected!=null,"Normal world economy never produced an independent shuttle trip")
	var passenger: Dictionary=selected.resident(passenger_id)
	assert(passenger["transit_method"]=="shuttle")
	var departures: int=0
	for event in selected.events:
		if event["kind"]=="npc_alternative_departed" \
				and event["subject"]==passenger_id \
				and event["detail"]["method"]=="shuttle" \
				and event["detail"]["offer_id"]==passenger["transit_from_offer"]:
			departures+=1
	assert(departures==1,"The rendered trip needs a real recorded shuttle departure")
	var pose: Dictionary=SandboxWorldTraffic.shuttle_pose(selected,passenger)
	assert(not pose.is_empty())
	assert(pose["resident_id"]==passenger_id)
	assert(pose["position"].is_equal_approx(selected.npc_position(passenger)))
	assert(pose["position"].y>=0.0)
	assert(pose["ahead"].distance_to(pose["position"])>0.001)
	assert(pose["source_offer"]==passenger["transit_from_offer"])
	var route: Array[String]=[]
	for node in passenger["transit_nodes"]: route.append(str(node))
	var route_duration: float=float(int(passenger["transit_until"])-
			int(passenger["transit_started"])-int(passenger.get("transit_pause_minutes",0)))
	var elapsed: float=float(selected.minute-int(passenger["transit_started"])-
			int(passenger.get("transit_pause_minutes",0)))
	assert(pose["render_position"].is_finite() and pose["render_ahead"].is_finite())
	assert(pose["render_position"].is_equal_approx(
			SandboxDirectedLanes.route_point_at_minutes(route,elapsed,route_duration)))
	assert(pose["render_ahead"].distance_to(pose["render_position"])>0.001,
			"Real shuttle needs a forward visual lane tangent")
	# Presentation interpolation is the real deterministic world path, not
	# a physically integrated speed or a second route clock.
	var interpolated: Dictionary=SandboxWorldTraffic.shuttle_pose(selected,passenger,0.5)
	assert(interpolated["position"].is_equal_approx(selected.npc_position(passenger,0.5)))
	assert(interpolated["position"].distance_to(pose["position"])>0.0001)
	assert(interpolated["render_position"].is_equal_approx(
			SandboxDirectedLanes.route_point_at_minutes(route,elapsed+0.5,route_duration)))
	assert(interpolated["render_position"].distance_to(pose["render_position"])>0.0001)
	var restored: SandboxWorld=SandboxWorld.new()
	assert(restored.restore_snapshot(selected.snapshot()),"A real active shuttle trip must survive save restore")
	var copied: Dictionary=SandboxWorldTraffic.shuttle_pose(restored,
			restored.resident(passenger_id),0.5)
	assert(copied["position"].is_equal_approx(interpolated["position"]))
	assert(copied["render_position"].is_equal_approx(interpolated["render_position"]))
	assert(copied["render_ahead"].is_equal_approx(interpolated["render_ahead"]))
	# A normal walking alternative is NOT drawn as a shuttle.
	var walking: Dictionary=passenger.duplicate(true)
	walking["transit_method"]="walking"
	assert(SandboxWorldTraffic.shuttle_pose(selected,walking).is_empty())
	# A real scene can render the same world-owned pose with no new
	# population record and no side effects on its saved simulation.
	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._city.world=selected
	var before: Dictionary=selected.snapshot()
	scene._city.visual_fraction=0.5
	scene._city.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(selected.snapshot()==before,"Drawing the active shuttle must not mutate the world")
	# The original autonomous route continues and terminates on schedule.
	var target: String=str(passenger["transit_to"])
	var until: int=int(passenger["transit_until"])
	assert(selected.advance(until-selected.minute))
	assert(selected.resident(passenger_id)["location"]==target)
	assert(str(selected.resident(passenger_id)["transit_method"]).is_empty())
	assert(SandboxWorldTraffic.shuttle_pose(selected,
			selected.resident(passenger_id)).is_empty())
	var arrivals: int=0
	for event in selected.events:
		if event["kind"]=="npc_alternative_arrived" and event["subject"]==passenger_id \
				and event["detail"]["offer_id"]==pose["source_offer"]:
			arrivals+=1
	assert(arrivals==1,"One passenger trip should have exactly one world-owned arrival")
	assert(SandboxWorld.new().restore_snapshot(selected.snapshot()))
	print("WORLD_SHUTTLE_VISUAL_PASS genuine NPC departure, independent moving vehicle, interpolation, single arrival and save provenance")
	quit()
