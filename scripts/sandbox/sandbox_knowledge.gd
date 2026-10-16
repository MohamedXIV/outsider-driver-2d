class_name SandboxKnowledge
extends RefCounted

# A single translator with installed whole-language cartridges, not learned
# words, route markers, or per-phrase progress. Three languages are communal.
const LANGUAGES: Array[String] = ["trade", "local", "cant"]
const DEVICES: Array[String] = ["gps", "module:local", "radio"]
const FIRST_FACT: Dictionary = {
	"gps": "map:district-graph",
	"radio": "radio:alien-signal-pattern"
}
const MODULE_PRICES: Dictionary = {"local": 8, "cant": 9}
const MARKET_VENDOR: String = "vendor:market:language-stall"


# Stable two-phrase taxi surface for the third language. These are surface
# representations of the SAME shared Ink intents, not random glyph strings.
# Script-font presentation and per-locale translation belong to #33.
const CANT_SURFACES: Dictionary = {
	"Rru'ka shen vorr. Teka-rii?": "Neh-vari tel'nuk. Sai-keth?",
	"Vrek shaa. Tir-ka.": "Irith aan. Ket-vu."
}


static func alien_surface(language: String, text_line: String) -> String:
	if language != "cant":
		return text_line
	var result: String = text_line
	for original in CANT_SURFACES:
		result = result.replace(str(original), str(CANT_SURFACES[original]))
	return result


static func has_fact(facts: Array[String], fact: String) -> bool:
	return facts.has(fact)


static func understands(language: String, installed_languages: Array[String]) -> bool:
	return LANGUAGES.has(language) and installed_languages.has(language)


static func can_switch_to_common(npc: Dictionary) -> bool:
	# Fluency and willingness are separate NPC capabilities, not a universal
	# escape from missing cartridges. High-need cautious riders may refuse.
	return bool(npc.get("speaks_common", false)) \
			and bool(npc.get("will_use_common", false)) \
			and not (npc.get("temperament") == "cautious" and int(npc.get("need", 0)) >= 75)


static func market_open(minute: int) -> bool:
	var hour: int = (minute % 1440) / 60
	return hour >= 6 and hour < 20
