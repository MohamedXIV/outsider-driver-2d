class_name SandboxDriverMemory
extends RefCounted

# A resident remembers witnessed *actions*, not the player's species/name
# or legal status. Each bounded memory cites a real world event.
const MAX_MEMORIES: int = 6
const COMPLETED: String = "ride_completed"
const REFUSED: String = "ride_refused"


static func remember(npc: Dictionary, kind: String, offer_id: String,
		source: String, minute: int) -> bool:
	if not [COMPLETED, REFUSED].has(kind) or source.is_empty():
		return false
	var memories: Array = npc["driver_memories"]
	for entry in memories:
		if entry["source"] == source:
			return false
	memories.append({
		"kind": kind, "offer_id": offer_id,
		"source": source, "minute": minute,
		"salience": 3 if kind == COMPLETED else 1
	})
	if memories.size() > MAX_MEMORIES:
		memories.pop_front()
	return true


static func recognizes(npc: Dictionary) -> bool:
	var refusal_count: int = 0
	for entry in npc.get("driver_memories", []):
		if entry["kind"] == COMPLETED:
			return true
		if entry["kind"] == REFUSED:
			refusal_count += 1
	return refusal_count >= 2


static func significance(npc: Dictionary) -> String:
	var served: int = 0
	for entry in npc.get("driver_memories", []):
		if entry["kind"] == COMPLETED:
			served += 1
	if served >= 2:
		return "significant"
	if recognizes(npc):
		return "persistent"
	return "ordinary"


static func valid_history(npc: Dictionary, offers: Array, events: Array, minute: int) -> bool:
	if not (npc.get("driver_memories") is Array) \
			or not (npc.get("driver_identity_facts") is Dictionary):
		return false
	# Until an explicit identity-evidence system exists, no person learns
	# 'human', real name or undocumented status from a fare/recognition alone.
	if not npc["driver_identity_facts"].is_empty():
		return false
	var memories: Array = npc["driver_memories"]
	if memories.size() > MAX_MEMORIES:
		return false
	var sources: Dictionary = {}
	for entry in memories:
		if not (entry is Dictionary) or not [COMPLETED, REFUSED].has(entry.get("kind", "")):
			return false
		var kind: String = str(entry["kind"])
		var offer_id: String = str(entry.get("offer_id", ""))
		var source: String = str(entry.get("source", ""))
		var at_minute: int = int(entry.get("minute", -1))
		if offer_id.is_empty() or source.is_empty() or sources.has(source) \
				or at_minute < SandboxWorld.START_MINUTE or at_minute > minute \
				or int(entry.get("salience", -1)) != (3 if kind == COMPLETED else 1):
			return false
		sources[source] = true
		var owned: bool = false
		for offer in offers:
			if offer is Dictionary and offer.get("id") == offer_id \
					and offer.get("npc_id") == npc["id"]:
				owned = true
				break
		if not owned:
			return false
		var matched: bool = false
		for event in events:
			if event is Dictionary and event.get("id") == source \
					and event.get("minute") == at_minute \
					and event.get("subject") == offer_id \
					and event.get("kind") == ("fare_settled" if kind == COMPLETED else "offer_declined"):
				matched = true
				break
		if not matched:
			return false
	return true
