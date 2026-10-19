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
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SAVE_FLOAT_PRECISION_PASS bounded sub-tick/heading precision, strict invalid rejection, unchanged World provenance")
	quit()
