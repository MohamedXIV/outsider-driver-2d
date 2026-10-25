extends SceneTree

# Architecture ratchet (Epic #89, issue #93).
#
# Scans source text for rule violations. Rules marked "fail" may not gain new
# violations, and an allowlisted violation that no longer occurs must be
# deleted. So the allowlist can only shrink. Entries are keyed by file, enclosing
# function and matched token, not by line, so unrelated edits do not churn it.
#
# ARCH_INIT=1      create tests/architecture_allowlist.json if it is missing (once)
# ARCH_SHRINK=1    drop stale entries; refused if anything new would be added
#
# Rule list lives in RULES. Add a rule there, then re-baseline with ARCH_INIT
# only when the allowlist is absent. Never hand-add entries.

const ALLOWLIST_PATH: String = "res://tests/architecture_allowlist.json"
const SCRIPT_ROOT: String = "res://scripts"
const WORLD_PATH: String = "res://scripts/sandbox/sandbox_world.gd"
const SIZE_FILE_LINES: int = 500
const SIZE_FUNCTION_LINES: int = 80

const RULES: Array = [
	{
		"id": "domain_purity",
		"mode": "fail",
		"scope": "domain",
		"patterns": [
			"\\bextends\\s+(Node|Node2D|Control)\\b",
			"\\bget_tree\\(",
			"\\bJavaScriptBridge\\b",
			"\\bOS\\.",
			"\\bDisplayServer\\b",
			"\\bResourceLoader\\b",
			"\\b(pre)?load\\(\\s*\"res://[^\"]*\\.tscn\"",
		],
	},
	{
		"id": "determinism",
		"mode": "fail",
		"scope": "domain",
		"patterns": [
			"\\b(randi|randf|randi_range|randf_range|randomize|RandomNumberGenerator)\\b",
			"\\bTime\\.",
			"\\bOS\\.get_ticks_",
		],
	},
	{
		"id": "presentation_truth",
		"mode": "report",
		"scope": "presentation",
		"patterns": ["\\b_?world\\.([a-z_]+)\\s*[+-]?=(?!=)"],
		"world_fields": true,
	},
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var files: Array[String] = _gd_files(SCRIPT_ROOT)
	var domain: Dictionary = {}
	for path in files:
		domain[path] = _is_domain(path)
	var current: Dictionary = {}
	var locations: Dictionary = {}
	var report: Dictionary = {}
	for rule in RULES:
		if rule["mode"] == "fail":
			current[rule["id"]] = []
	for rule in RULES:
		var found: Array = _scan_rule(rule, files, domain)
		report[rule["id"]] = found.size()
		if rule["mode"] == "fail":
			for violation in found:
				var key: String = violation["key"]
				current[rule["id"]].append(key)
				locations[key] = violation
		else:
			for violation in found:
				print("ARCH_REPORT %s %s:%d %s" % [rule["id"], violation["path"], violation["line"], violation["token"]])
	var size: Dictionary = _size_report(files)
	print("ARCH_REPORT size_files_over_%d %d" % [SIZE_FILE_LINES, size["files"].size()])
	print("ARCH_REPORT size_functions_over_%d %d" % [SIZE_FUNCTION_LINES, size["functions"].size()])
	for entry in size["files"]:
		print("ARCH_REPORT size_file %s" % entry)
	for entry in size["functions"]:
		print("ARCH_REPORT size_function %s" % entry)

	var allowlist: Dictionary = _read_allowlist()
	if allowlist.is_empty() and not FileAccess.file_exists(ALLOWLIST_PATH):
		if OS.get_environment("ARCH_INIT") == "1":
			_write_allowlist(current)
			print("ARCH_INIT wrote %s" % ALLOWLIST_PATH)
			quit(0)
			return
		if not Check.ok(false, "allowlist missing; run once with ARCH_INIT=1"): return

	var new_violations: Array = []
	var stale_entries: Array = []
	for rule in RULES:
		if rule["mode"] != "fail":
			continue
		var id: String = rule["id"]
		var now: Array = current.get(id, [])
		var was: Array = allowlist.get(id, [])
		for key in _multiset_minus(now, was):
			new_violations.append([id, key])
		for key in _multiset_minus(was, now):
			stale_entries.append([id, key])

	if OS.get_environment("ARCH_SHRINK") == "1":
		if not new_violations.is_empty():
			for entry in new_violations:
				print("FAIL refusing to shrink, new violation [%s] %s" % [entry[0], entry[1]])
			if not Check.ok(false, "ARCH_SHRINK refused: allowlist may only shrink"): return
		var shrunk: Dictionary = {}
		for rule in RULES:
			if rule["mode"] == "fail":
				shrunk[rule["id"]] = current.get(rule["id"], [])
		_write_allowlist(shrunk)
		print("ARCH_SHRINK removed %d stale entries" % stale_entries.size())
		quit(0)
		return

	for entry in new_violations:
		_print_new(entry, locations)
	for entry in stale_entries:
		print("FAIL stale allowlist entry [%s] %s: the violation is gone, delete this entry (ratchet)" % [entry[0], entry[1]])
	var counts: String = " ".join(PackedStringArray(_counts_line(report)))
	if not Check.ok(new_violations.is_empty() and stale_entries.is_empty(),
			"architecture: %d new, %d stale" % [new_violations.size(), stale_entries.size()]):
		return
	Check.finish(self, "architecture " + counts)


func _is_domain(path: String) -> bool:
	if not path.get_file().begins_with("sandbox_"):
		return false
	if not path.begins_with("res://scripts/sandbox/"):
		return false
	return _first_code_line(path).begins_with("extends RefCounted")


func _first_code_line(path: String) -> String:
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var code: String = _code_part(line).strip_edges()
		if code.begins_with("extends "):
			return code
	return ""


func _scan_rule(rule: Dictionary, files: Array[String], domain: Dictionary) -> Array:
	var found: Array = []
	var fields: Dictionary = _world_fields() if rule.get("world_fields", false) else {}
	var regexes: Array[RegEx] = []
	for pattern in rule["patterns"]:
		regexes.append(RegEx.create_from_string(pattern))
	for path in files:
		var is_domain: bool = domain[path]
		if rule["scope"] == "domain" and not is_domain:
			continue
		if rule["scope"] == "presentation" and is_domain:
			continue
		var function_name: String = "-"
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for index in range(lines.size()):
			var raw: String = lines[index]
			var declared: String = _function_name(raw)
			if not declared.is_empty():
				function_name = declared
			var code: String = _code_part(raw)
			if code.strip_edges().is_empty():
				continue
			for regex in regexes:
				var hit: RegExMatch = regex.search(code)
				if hit == null:
					continue
				# Only SandboxWorld fields count as world truth. Scene nodes named
				# _world (for example _world.visible) are presentation.
				if rule.get("world_fields", false) and not fields.has(hit.get_string(1)):
					continue
				var token: String = hit.get_string(0).strip_edges()
				found.append({
					"path": path,
					"line": index + 1,
					"token": token,
					"key": "%s::%s:%s" % [path, function_name, token],
				})
	return found


# "func x(" or "static func x(" -> "x"; anything else -> "".
func _function_name(line: String) -> String:
	var code: String = line.trim_prefix("static ")
	if not code.begins_with("func "):
		return ""
	return code.trim_prefix("func ").get_slice("(", 0).strip_edges()


# Names of SandboxWorld's own vars, read from its source (the domain truth).
func _world_fields() -> Dictionary:
	var fields: Dictionary = {}
	for line in FileAccess.get_file_as_string(WORLD_PATH).split("\n"):
		if line.begins_with("var "):
			fields[line.trim_prefix("var ").get_slice(":", 0).get_slice("=", 0).strip_edges()] = true
	return fields


# Source text before any '#' comment, ignoring '#' inside string literals.
func _code_part(line: String) -> String:
	var in_string: bool = false
	for index in range(line.length()):
		var character: String = line[index]
		if character == "\"":
			in_string = not in_string
		elif character == "#" and not in_string:
			return line.substr(0, index)
	return line


func _size_report(files: Array[String]) -> Dictionary:
	var big_files: Array = []
	var big_functions: Array = []
	for path in files:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		if lines.size() > SIZE_FILE_LINES:
			big_files.append("%s %d lines" % [path, lines.size()])
		var start: int = -1
		var name: String = ""
		for index in range(lines.size() + 1):
			var is_boundary: bool = index == lines.size() or not _function_name(lines[index]).is_empty()
			if not is_boundary:
				continue
			if start >= 0 and index - start > SIZE_FUNCTION_LINES:
				big_functions.append("%s::%s %d lines" % [path, name, index - start])
			if index < lines.size():
				start = index
				name = _function_name(lines[index])
	return {"files": big_files, "functions": big_functions}


func _gd_files(directory: String) -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		return out
	for name in dir.get_directories():
		out.append_array(_gd_files(directory.path_join(name)))
	for name in dir.get_files():
		if name.ends_with(".gd"):
			out.append(directory.path_join(name))
	out.sort()
	return out


func _read_allowlist() -> Dictionary:
	if not FileAccess.file_exists(ALLOWLIST_PATH):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(ALLOWLIST_PATH))
	return value if value is Dictionary else {}


func _write_allowlist(entries: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(ALLOWLIST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(entries, "\t", true) + "\n")
	file.close()


# Multiset difference: keeps duplicates, so two identical violations need two entries.
func _multiset_minus(left: Array, right: Array) -> Array:
	var remaining: Array = right.duplicate()
	var out: Array = []
	for item in left:
		var index: int = remaining.find(item)
		if index >= 0:
			remaining.remove_at(index)
		else:
			out.append(item)
	return out


func _print_new(entry: Array, locations: Dictionary) -> void:
	var key: String = entry[1]
	var where: Dictionary = locations[key]
	print("FAIL %s:%d: [%s] %s is a new violation (%s)" % [where["path"], where["line"], entry[0], where["token"], key])


func _counts_line(report: Dictionary) -> Array:
	var out: Array = []
	for rule in RULES:
		out.append("%s=%d" % [rule["id"], report[rule["id"]]])
	return out
