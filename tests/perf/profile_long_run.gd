extends SceneTree

# #94 profiling harness (Epic #89, Phase 1). NATIVE ONLY: frame timings need a
# real renderer, so run under a display. Extends the #87 seed-8 matched-perf
# loop (same +6h command, same frame loop) instead of duplicating it.
#
#   OD2D_PERF_PROBE=1 OD2D_PERF_PHASE=ledger xvfb-run -a $GODOT --path . \
#     --audio-driver Dummy --script res://tests/perf/profile_long_run.gd
#
# OD2D_PERF_PHASE:
#   overhead  probe cost A/B (run with OD2D_PERF_PROBE UNSET)
#   ledger    frame cost vs event-ledger size, clock frozen (the hypothesis test)
#   long      scripted six-hour segments, one CSV row per wall-clock second
#   scan      domain-only: cost of the ledger scan for a stop never reached, by
#             ledger size (no rendering, so it separates ledger cost from content)
# OD2D_PERF_OUT: directory for the CSV (default user://).
# Output: PERF_ROW / PERF_SUMMARY JSON lines, then PERF_PASS or PERF_FAIL.

const SEED: int = 8
const LEDGER_TARGETS: Array[int] = [0, 1000, 2000, 5000, 10000]
const LEDGER_WINDOW_SECONDS: float = 10.0
const LONG_SEGMENTS: int = 4
const LONG_MINUTES_PER_SEGMENT: int = 360
const LONG_WINDOW_SECONDS: float = 10.0
const PREFILL_BATCH_MINUTES: int = 60
const PREFILL_MAX_STEPS: int = 200000
const OVERHEAD_ITERATIONS: int = 2000000


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var phase: String = OS.get_environment("OD2D_PERF_PHASE")
	if phase.is_empty():
		phase = "ledger"
	print("PERF_META ", JSON.stringify(_meta(phase)))
	var passed: bool = false
	match phase:
		"overhead":
			passed = _phase_overhead()
		"ledger":
			passed = await _phase_ledger()
		"long":
			passed = await _phase_long()
		"scan":
			passed = _phase_scan()
		_:
			print("PERF_FAIL unknown phase ", phase)
	print("PERF_PASS " if passed else "PERF_FAIL ", phase)
	quit(0 if passed else 1)


func _meta(phase: String) -> Dictionary:
	return {
		"phase": phase,
		"godot": Engine.get_version_info()["string"],
		"cpu": OS.get_processor_name(),
		"cores": OS.get_processor_count(),
		"display_driver": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"probe_enabled": PerfProbe.enabled,
		"os": OS.get_name(),
	}


func _make_scene() -> Node:
	root.size = Vector2i(1280, 720)
	var scene: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	var world: SandboxWorld = SandboxWorld.new(SEED)
	scene._world = world
	scene._city.world = world
	scene._vehicle_corridor.attach(world)
	return scene


# Advances the authoritative world only (no rendering, no native bodies), the
# same way the ledger hypothesis is specified in #94. Declines meetings that
# block time, which is what a player would have to do anyway.
func _prefill(world: SandboxWorld, target: int) -> bool:
	var steps: int = 0
	while world.events.size() < target:
		steps += 1
		if steps > PREFILL_MAX_STEPS:
			return false
		if world.meeting_in_progress():
			var meeting_id: String = ""
			for meeting in world.meetings:
				if meeting.get("status") == "in_progress":
					meeting_id = str(meeting.get("id", ""))
					break
			if meeting_id.is_empty() or not world.decline_meeting(meeting_id):
				return false
			continue
		if not world.advance(PREFILL_BATCH_MINUTES):
			return false
	return true


# Frame loop shared by all phases. delta 0.0 freezes the simulation clock, so
# the measured cost is presentation and per-frame scans, not world ticks.
# Returns frame-interval stats; optionally appends one CSV row per second.
func _measure_window(scene: Node, seconds: float, delta: float, csv_rows: Array) -> Dictionary:
	var world: SandboxWorld = scene._world
	PerfProbe.reset()
	var frames: Array = []
	var started: int = Time.get_ticks_usec()
	var last: int = started
	var second_frames: Array = []
	var next_second: float = 1.0
	var events_at_start: int = world.events.size()
	var minute_at_start: int = world.minute
	while float(Time.get_ticks_usec() - started) / 1000000.0 < seconds:
		PerfProbe.begin("frame.process")
		scene._process(delta)
		PerfProbe.end("frame.process")
		await process_frame
		var now: int = Time.get_ticks_usec()
		var interval_ms: float = float(now - last) / 1000.0
		frames.append(interval_ms)
		second_frames.append(interval_ms)
		last = now
		var elapsed: float = float(now - started) / 1000000.0
		if elapsed >= next_second:
			csv_rows.append({
				"t_s": snappedf(elapsed, 0.01),
				"minute": world.minute,
				"events": world.events.size(),
				"frame_mean_ms": _mean(second_frames),
				"frame_max_ms": _max(second_frames),
				"time_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				"time_physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			})
			second_frames.clear()
			next_second += 1.0
	var stats: Dictionary = _stats(frames)
	stats["events_start"] = events_at_start
	stats["events_end"] = world.events.size()
	stats["minute_start"] = minute_at_start
	stats["minute_end"] = world.minute
	stats["probe"] = PerfProbe.report()
	return stats


func _phase_ledger() -> bool:
	var scene: Node = await _make_scene()
	var world: SandboxWorld = scene._world
	var results: Array = []
	for target in LEDGER_TARGETS:
		if not _prefill(world, target):
			print("PERF_FAIL prefill could not reach ", target, " events; at ", world.events.size())
			return false
		var stats: Dictionary = await _measure_window(scene, LEDGER_WINDOW_SECONDS, 0.0, [])
		stats["target_events"] = target
		print("PERF_ROW ", JSON.stringify(stats))
		results.append(stats)
	print("PERF_SUMMARY ", JSON.stringify(results))
	return true


func _phase_long() -> bool:
	var scene: Node = await _make_scene()
	var world: SandboxWorld = scene._world
	var csv: Array = []
	var results: Array = []
	for segment in range(LONG_SEGMENTS):
		var manual_started: int = Time.get_ticks_usec()
		scene._advance_manual_time(LONG_MINUTES_PER_SEGMENT)
		var manual_ms: float = float(Time.get_ticks_usec() - manual_started) / 1000.0
		scene._render()
		var stats: Dictionary = await _measure_window(scene, LONG_WINDOW_SECONDS, 1.0 / 60.0, csv)
		stats["segment"] = segment
		stats["manual_six_hour_ms"] = manual_ms
		print("PERF_ROW ", JSON.stringify(stats))
		results.append(stats)
		if world.residents.size() != 9:
			print("PERF_FAIL resident count changed in segment ", segment)
			return false
	var path: String = _write_csv(csv)
	print("PERF_CSV ", path)
	print("PERF_SUMMARY ", JSON.stringify(results))
	return true


func _phase_overhead() -> bool:
	if PerfProbe.enabled:
		print("PERF_FAIL overhead must run with OD2D_PERF_PROBE unset")
		return false
	var sink: int = 0
	var started: int = Time.get_ticks_usec()
	for i in range(OVERHEAD_ITERATIONS):
		sink += 1
	var baseline_us: float = float(Time.get_ticks_usec() - started)
	started = Time.get_ticks_usec()
	for i in range(OVERHEAD_ITERATIONS):
		PerfProbe.begin("overhead.section")
		sink += 1
		PerfProbe.end("overhead.section")
	var probed_us: float = float(Time.get_ticks_usec() - started)
	var per_pair_ns: float = (probed_us - baseline_us) * 1000.0 / float(OVERHEAD_ITERATIONS)
	print("PERF_SUMMARY ", JSON.stringify({
		"iterations": OVERHEAD_ITERATIONS,
		"baseline_ms": baseline_us / 1000.0,
		"probe_disabled_ms": probed_us / 1000.0,
		"disabled_overhead_ns_per_begin_end_pair": snappedf(per_pair_ns, 0.1),
		"sink": sink,
	}))
	return sink == OVERHEAD_ITERATIONS * 2


func _write_csv(rows: Array) -> String:
	var directory: String = OS.get_environment("OD2D_PERF_OUT")
	var path: String = directory.path_join("perf-long.csv") if not directory.is_empty() else "user://perf-long.csv"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "UNWRITABLE " + path
	file.store_line("t_s,minute,events,frame_mean_ms,frame_max_ms,time_process_ms,time_physics_ms,nodes,objects")
	for row in rows:
		file.store_line("%s,%s,%s,%.3f,%.3f,%.3f,%.3f,%s,%s" % [
			row["t_s"], row["minute"], row["events"], row["frame_mean_ms"], row["frame_max_ms"],
			row["time_process_ms"], row["time_physics_ms"], row["nodes"], row["objects"]])
	file.close()
	return ProjectSettings.globalize_path(path)


func _stats(frames: Array) -> Dictionary:
	var sorted: Array = frames.duplicate()
	sorted.sort()
	return {
		"frames": sorted.size(),
		"p50_ms": _percentile(sorted, 0.50),
		"p95_ms": _percentile(sorted, 0.95),
		"p99_ms": _percentile(sorted, 0.99),
		"mean_ms": _mean(sorted),
		"max_ms": _max(sorted),
	}


func _percentile(sorted: Array, quantile: float) -> float:
	if sorted.is_empty():
		return 0.0
	var index: int = clampi(int(roundf(quantile * float(sorted.size() - 1))), 0, sorted.size() - 1)
	return float(sorted[index])


func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _max(values: Array) -> float:
	var highest: float = 0.0
	for value in values:
		highest = maxf(highest, float(value))
	return highest


# Times SandboxDirectedLanes.parked_screen_from_events for a stop that no
# route_segment_completed event ever reached. Such a call walks the whole
# ledger backwards, so its cost is the ledger-size term alone.
func _phase_scan() -> bool:
	var world: SandboxWorld = SandboxWorld.new(SEED)
	var results: Array = []
	var reps: int = 200
	for target in LEDGER_TARGETS:
		if not _prefill(world, target):
			print("PERF_FAIL prefill could not reach ", target, " events; at ", world.events.size())
			return false
		var stop: String = _unreached_stop(world)
		if stop.is_empty():
			print("PERF_FAIL every district has an arrival; scan would stop early")
			return false
		var started: int = Time.get_ticks_usec()
		for rep in range(reps):
			SandboxDirectedLanes.parked_screen_from_events(world.events, stop)
		var row: Dictionary = {
			"events": world.events.size(),
			"minute": world.minute,
			"stop": stop,
			"scan_mean_us": float(Time.get_ticks_usec() - started) / float(reps),
		}
		print("PERF_ROW ", JSON.stringify(row))
		results.append(row)
	print("PERF_SUMMARY ", JSON.stringify(results))
	return true


func _unreached_stop(world: SandboxWorld) -> String:
	for district in SandboxRoads.DISTRICTS:
		var reached: bool = false
		for event in world.events:
			if event.get("kind") == "route_segment_completed" and event.get("detail", {}).get("to") == district:
				reached = true
				break
		if not reached:
			return str(district)
	return ""
