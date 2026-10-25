class_name PerfProbe
extends RefCounted

# Coarse frame-section timer for the #94 profiling harness.
#
# Disabled (the default, and every shipped run): begin()/end() return after one
# static bool check. Enabled only with OD2D_PERF_PROBE=1, which the harness sets.
# Never reads or writes simulation state, and never affects determinism.

static var enabled: bool = OS.get_environment("OD2D_PERF_PROBE") == "1"
static var _started: Dictionary = {}
static var _total_usec: Dictionary = {}
static var _calls: Dictionary = {}


static func begin(section: String) -> void:
	if not enabled:
		return
	_started[section] = Time.get_ticks_usec()


static func end(section: String) -> void:
	if not enabled or not _started.has(section):
		return
	_total_usec[section] = int(_total_usec.get(section, 0)) + Time.get_ticks_usec() - int(_started[section])
	_calls[section] = int(_calls.get(section, 0)) + 1
	_started.erase(section)


static func reset() -> void:
	_started.clear()
	_total_usec.clear()
	_calls.clear()


# {section: {"total_ms": float, "calls": int, "mean_us": float}}
static func report() -> Dictionary:
	var out: Dictionary = {}
	for section in _total_usec:
		var calls: int = int(_calls[section])
		out[section] = {
			"total_ms": float(_total_usec[section]) / 1000.0,
			"calls": calls,
			"mean_us": float(_total_usec[section]) / float(maxi(calls, 1)),
		}
	return out
