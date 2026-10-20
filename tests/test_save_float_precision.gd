extends SceneTree

func _initialize() -> void:
	# A real sub-tick value can be only one representable float below 1.
	# Short JSON formatting rounds it to 1.0, which Load rightly rejects.
	var fraction: float=1.0
	fraction-=0.0000000000000001
	assert(fraction<1.0 and fraction>0.0)
	var world: SandboxWorld=SandboxWorld.new(8)
	var path: String="user://r05_float_precision_regression.json"
	assert(SandboxSave.save_world(world,path,{},
			{"clock_fraction":fraction,"taxi_heading":PI}))
	var loaded: Dictionary=SandboxSave.load_bundle(path)
	assert(not loaded.is_empty(),"A valid sub-tick save must not become invalid through JSON rounding")
	assert(float(loaded["presentation"]["clock_fraction"])<1.0)
	assert(absf(float(loaded["presentation"]["clock_fraction"])-fraction)<=0.000000000001)
	assert(absf(float(loaded["presentation"]["taxi_heading"])-PI)<0.000000000001)
	assert(loaded["world"].snapshot()==world.snapshot())
	assert(not SandboxSave.save_world(world,path,{}, {"clock_fraction":1.0}),
			"Invalid fractions must still be rejected, not normalized into valid saves")
	for phase in [0.0,.123456789012345,fraction]:
		var moving: SandboxWorld=SandboxWorld.new(9)
		moving.vehicle_fraction=phase
		assert(moving.reposition("clinic"))
		assert(SandboxVehicleExecution.bind(moving,"player",phase))
		assert(SandboxSave.save_world(moving,path))
		var restored: SandboxWorld=SandboxSave.load_world(path)
		assert(restored!=null,"The authoritative fraction and sourced departure must survive JSON")
		assert(absf(restored.vehicle_fraction-phase)<=.000000000001)
		assert(restored.snapshot()==moving.snapshot(),"Source clock types and fractional values must round-trip")
		assert(restored.events==moving.events and restored.residents==moving.residents)
	var legacy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	legacy.erase("world_exact")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(legacy))
	assert(SandboxSave.load_world(path)!=null,"Previous JSON-only v12 saves remain readable")
	assert(SandboxSave.save_world(world,path))
	var inconsistent: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	inconsistent["world"]["extra_unmatched_field"]=true
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(inconsistent))
	assert(SandboxSave.load_bundle(path).is_empty(),"The exact copy must never override altered JSON silently")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SAVE_FLOAT_PRECISION_PASS bounded sub-tick/heading precision, strict invalid rejection, unchanged World provenance")
	quit()
