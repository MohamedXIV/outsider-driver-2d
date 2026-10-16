extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	var id: String=""
	for offer in world.open_offers():
		if offer["origin"]=="garage" and offer["channel"]!="official": id=offer["id"];break
	var pickup: SandboxConversation=SandboxConversation.new()
	assert(pickup.open(world,id,self))
	world.advance(60)
	assert(pickup.still_valid(world),"Reading protects only the engaged request")
	assert(world.accept(id))
	var talk: SandboxConversation=SandboxConversation.new()
	assert(talk.open(world,id,self),"Accepted fare opens travel Ink")
	var restored: SandboxConversation=SandboxConversation.new()
	assert(restored.restore(world,talk.snapshot(),self))
	assert(restored.current_frame()==talk.current_frame())
	world.advance(world.remaining_minutes)
	assert(talk.still_valid(world),"Arrival must leave readable choices")
	assert(talk.choose(2,world))
	assert(talk.is_finished())
	print("TRAVEL_DIALOGUE_PASS engaged pickup, inride Ink, restore, safe arrival")
	quit()
