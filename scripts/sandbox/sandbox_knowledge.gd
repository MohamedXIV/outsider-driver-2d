class_name SandboxKnowledge
extends RefCounted

# Knowledge is an explicit, world-owned ledger. Devices reveal *different*
# evidence; no invented fluent translation, omniscient GPS or human radio.
const DEVICES: Array[String] = ["gps", "translator", "radio"]
const FIRST_FACT: Dictionary = {
	"gps": "map:district-graph",
	"translator": "tool:local-phrase-scanner",
	"radio": "radio:alien-signal-pattern"
}
const ROUTE_MARKER: String = "lexicon:local:route-marker"


static func has_fact(facts: Array[String], fact: String) -> bool:
	return facts.has(fact)


static func understands(language: String, facts: Array[String]) -> bool:
	# Trade speech is a known lingua franca. Local dialect is *never* fully
	# translated in S2, not even after learning one route expression.
	return language == "trade"


static func recognizes_route_marker(language: String, facts: Array[String]) -> bool:
	return language == "local" and facts.has(ROUTE_MARKER)


static func can_observe_route(device: String, language: String, fact: String) -> bool:
	return device == "translator" and language == "local" and fact == ROUTE_MARKER
