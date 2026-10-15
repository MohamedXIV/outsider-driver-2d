class_name SandboxSocial
extends RefCounted

# Bounded co-presence. Existing 'trade/local' are S2 prototype languages,
# not the later three-language product taxonomy. No remote psychic gossip.
# Affinity and rivalry are independent. Shared origin, language and workplace
# can create familiarity AND competition at the same time.
static func affinity(a: Dictionary, b: Dictionary) -> int:
	return (2 if a["home"] == b["home"] else 0) \
			+ (1 if a["language"] == b["language"] else 0) \
			+ (1 if a["community"] == b["community"] else 0)


static func rivalry(a: Dictionary, b: Dictionary) -> int:
	return (2 if a["workplace"] == b["workplace"] else 0) \
			+ (1 if a["home"] == b["home"] else 0)


static func pick(residents: Array[Dictionary], minute: int) -> Dictionary:
	# One pair per hour, each resident at most once per simulated 24h.
	# Ordering derives only from stable resident IDs/list, never RNG state.
	if minute % 60 != 20:
		return {}
	var day: int = (minute - SandboxWorld.START_MINUTE) / 1440
	for i in range(residents.size()):
		var a: Dictionary = residents[i]
		if int(a["last_peer_day"]) >= day or str(a["activity"]) == "travelling":
			continue
		for j in range(i + 1, residents.size()):
			var b: Dictionary = residents[j]
			if int(b["last_peer_day"]) >= day or str(b["activity"]) == "travelling" \
					or a["location"] != b["location"] or a["language"] != b["language"]:
				continue
			var closeness: int = affinity(a, b)
			if closeness < 2:
				continue
			return {"actor": str(a["id"]), "recipient": str(b["id"]),
				"affinity": closeness, "rivalry": rivalry(a, b)}
	return {}
