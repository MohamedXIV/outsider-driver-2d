class_name SandboxLanguagePresentation
extends RefCounted

# Presentation only. Ink owns speech acts, SandboxWorld owns state, and these
# *authored* semantic phrases never encode a seed, destination or NPC identity.
# Local = Runic-shaped glyphs, Cant = Ogham-shaped glyphs, both served by OFL
# font assets. Neither glyph inventory pretends to be a complete conlang.
const SCRIPT_LINES: Dictionary = {
	"local": {
		"intro_repeat": "ᚠᛇᚱ ᚾᚨᚷ ᛏᚺᛁ?",
		"intro_urgent_cautious": "ᚲᚨᚾ ᚹᛁᚾ ᛗᚨ ᛁᛋ!",
		"intro_urgent": "ᚺᚨᛚ ᛏᚱᚢ ᛗᚨ!",
		"intro_cautious": "ᛖᚾ ᛏᚨᚲ ᚱᛖᛞ?",
		"intro_normal": "ᚠᚢᚦᚨᚱᚲ ᛟᚾ ᛁᛋ?",
		"destination": "ᛞᚨᚷ ᚲᚾ ᚱᚨᛞ."
	},
	"cant": {
		"intro_repeat": "᚛ᚂᚐᚅᚓᚔ ᚋᚒᚉᚐᚇ᚜",
		"intro_urgent_cautious": "᚛ᚄᚐᚅᚓ ᚈᚒᚇᚔ᚜",
		"intro_urgent": "᚛ᚈᚓᚇᚐ ᚆᚓᚋ᚜",
		"intro_cautious": "᚛ᚅᚒᚇᚔ ᚂᚓᚈᚐ᚜",
		"intro_normal": "᚛ᚁᚂᚃᚐ ᚋᚒᚉᚐ᚜",
		"destination": "᚛ᚇᚔᚋᚐ ᚂᚓᚅ᚜"
	}
}
const AR_DISTRICTS: Dictionary = {
	"docks": "الأرصفة", "market": "السوق", "clinic": "العيادة",
	"shelter": "الملجأ", "depot": "المستودع"
}
const AR_PURPOSES: Dictionary = {
	"medical": "تلقي العلاج", "supplies": "شراء المؤن",
	"work": "العمل", "shelter": "البحث عن مأوى"
}


static func speech_key(frame: Dictionary, npc: Dictionary) -> String:
	var tags: Array = frame.get("tags", [])
	if tags.has("intent:ask_destination"):
		return "destination"
	if not tags.has("intent:request_trip"):
		return ""
	if not npc.get("driver_memories", []).is_empty() and SandboxDriverMemory.recognizes(npc):
		return "intro_repeat"
	if int(npc.get("need", 0)) >= 70:
		return "intro_urgent_cautious" if npc.get("temperament") == "cautious" else "intro_urgent"
	return "intro_cautious" if npc.get("temperament") == "cautious" else "intro_normal"


static func source_line(language: String, key: String) -> String:
	if language == "trade":
		return ""
	return str(SCRIPT_LINES.get(language, {}).get(key, ""))


static func localized_line(frame: Dictionary, npc: Dictionary, offer: Dictionary, locale: String) -> String:
	if locale != "ar":
		return str(frame.get("text", ""))
	match speech_key(frame, npc):
		"intro_repeat":
			return "أنت مرة أخرى! أتذكر هذه السيارة؛ أوصلتني في المرة السابقة."
		"intro_urgent_cautious":
			return "أرجوك، أحتاج إلى توصيلة، لكن أبعدنا عن المشاكل."
		"intro_urgent":
			return "أحتاج إلى توصيلة حالًا. هل يمكنك الإسراع؟"
		"intro_cautious":
			return "هل تقلّ ركابًا؟ أفضل أن يظل الأمر بعيدًا عن الأنظار."
		"intro_normal":
			return "يا سائق! هل لديك مكان؟ أحتاج إلى التحرك."
		"destination":
			var district: String = str(AR_DISTRICTS.get(str(offer.get("destination", "")), ""))
			var purpose: String = str(AR_PURPOSES.get(str(offer.get("purpose", "")), ""))
			if district.is_empty() or purpose.is_empty():
				return "" # Never invent a translated clue for an unknown key.
			return "أنا ذاهب إلى %s من أجل %s." % [district, purpose]
	return ""


static func localized_choice(choice: String, locale: String) -> String:
	if locale != "ar":
		return choice
	match choice:
		"Ask where they need to go.":
			return "اسأل عن الوجهة"
		"Agree to the trip.":
			return "وافق على التوصيلة"
		"Turn them down.":
			return "ارفض التوصيلة"
	return choice


static func native_font_path(language: String) -> String:
	match language:
		"local": return "res://assets/fonts/NotoSansRunic-Regular.ttf"
		"cant": return "res://assets/fonts/NotoSansOgham-Regular.ttf"
	return ""
