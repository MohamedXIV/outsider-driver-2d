extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld = SandboxWorld.new(8)
	assert(not world.ar_owned and not world.ar_equipped)
	assert(not world.buy_ar() and not world.set_ar_equipped(true))
	assert(SandboxARHints.known_district(world, "docks").is_empty())
	assert(world.reposition("market"))
	assert(world.advance(world.remaining_minutes))
	assert(world.credits == 10)
	assert(world.buy_ar() and world.credits == 5)
	assert(not world.buy_ar())
	assert(not world.ar_equipped)
	assert(SandboxARHints.known_district(world, "market").is_empty())
	assert(world.set_ar_equipped(true))
	var verified: Dictionary = SandboxARHints.known_district(world, "market")
	assert(verified["certainty"] == "verified")
	assert(str(verified["source"]).contains("event:"))
	assert(SandboxARHints.known_district(world, "clinic").is_empty())
	assert(SandboxARHints.known_district(world, "nonexistent").is_empty())
	assert(world.set_ar_equipped(false))
	assert(SandboxARHints.known_district(world, "market").is_empty())
	assert(world.set_ar_equipped(true))
	var empty_frame: Dictionary = {"tags": ["intent:request_trip"]}
	var reveal_frame: Dictionary = {"tags": ["intent:ask_destination"]}
	var offer: Dictionary = {"npc_id": "npc:04", "destination": "market"}
	assert(SandboxARHints.contextual(world, empty_frame, offer, true).is_empty())
	assert(SandboxARHints.contextual(world, reveal_frame, offer, false).is_empty())
	assert(SandboxARHints.contextual(world, reveal_frame, offer, true)["certainty"] == "verified")
	offer["destination"] = "clinic"
	assert(SandboxARHints.contextual(world, reveal_frame, offer, true).is_empty())
	var forged: Dictionary = world.snapshot()
	forged["ar_owned"] = false
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = world.snapshot()
	forged["ar_equipped"] = false
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = world.snapshot()
	forged["events"].append({"id": "event:forged", "minute": world.minute,
			"kind": "player_rumor_heard", "subject": "offer:forged",
			"detail": {"speaker": "npc:00", "fact": "residence:npc:02", "value": "clinic",
				"claim_source": "event:fake"}})
	assert(not SandboxWorld.new().restore_snapshot(forged))
	var save: String = "user://sandbox-ar-v11-test.json"
	assert(SandboxSave.save_world(world, save))
	var loaded: SandboxWorld = SandboxSave.load_world(save)
	assert(loaded != null and loaded.ar_owned and loaded.ar_equipped and loaded.credits == 5)
	assert(loaded.snapshot() == world.snapshot())
	var fresh: SandboxWorld = SandboxWorld.new(8)
	assert(fresh.select_starter_device("gps"))
	assert(fresh.knows("map:district-graph"))
	assert(fresh.reposition("market"))
	assert(fresh.advance(fresh.remaining_minutes))
	assert(fresh.buy_ar() and fresh.set_ar_equipped(true))
	var gps_hint: Dictionary = SandboxARHints.known_district(fresh, "clinic")
	assert(gps_hint.get("certainty") == "verified")
	assert(str(gps_hint.get("source")).contains("starter:gps"))
	# Actual seeded peer contact creates a sourced private NPC claim. Stage a
	# reachable, willing fare in this domain fixture through the REAL dispatch,
	# never fabricate player_rumor_heard or bypass the world action.
	var rumors: SandboxWorld = SandboxWorld.new(8)
	assert(rumors.advance(20))
	var contact: Dictionary = {}
	for evt in rumors.events:
		if evt["kind"] == "npc_peer_contact":
			contact = evt
			break
	assert(not contact.is_empty())
	var listener: Dictionary = rumors.resident(str(contact["detail"]["recipient"]))
	assert(listener["peer_knowledge"].has(str(contact["detail"]["fact"])))
	# The NPC has heard it; the PLAYER has not. Ownership must not leak.
	assert(SandboxARHints.contextual(rumors, reveal_frame,
			{"npc_id": listener["id"], "destination": str(contact["detail"]["value"])}, true).is_empty())
	# Controlled fixture places the SAME resident at a legitimate market
	# dispatch encounter, preserving its real sourced peer contact.
	assert(rumors.reposition("market"))
	assert(rumors.advance(rumors.remaining_minutes))
	# A unit scenario with a still-current peer-knowledge source.
	listener["location"] = "market"
	listener["activity"] = "available"
	listener["transit_until"]=0;listener["transit_started"]=0;listener["transit_nodes"]=[]
	listener["transit_to"]="";listener["transit_from_offer"]="";listener["transit_method"]=""
	listener["need"] = 95
	listener["cash"] = 100
	listener["cooldown_until"] = 0
	listener["destination"] = "clinic"
	for pending in rumors.offers:
		if pending["npc_id"] == listener["id"] and pending["status"] == "open":
			pending["status"] = "expired" # Clear prior district request in fixture.
	SandboxDispatch.refresh(rumors.residents, rumors.offers, rumors.minute, rumors.seed)
	var rumor_offer: String = ""
	for candidate in rumors.open_offers():
		if candidate["npc_id"] == listener["id"] and candidate["origin"] == "market":
			rumor_offer = str(candidate["id"])
			break
	assert(not rumor_offer.is_empty())
	var language: String = str(listener["language"])
	rumors.credits = 100 # Fixture funding; buying each component still uses its real gate.
	if language == "cant":
		assert(rumors.buy_language_module("cant"))
		assert(rumors.install_language_module("cant"))
	elif language == "local":
		assert(rumors.buy_language_module("local"))
		assert(rumors.install_language_module("local"))
	assert(rumors.rumor_candidate(rumor_offer).get("claim_source") == contact["id"])
	assert(rumors.hear_rumor(rumor_offer))
	assert(not rumors.hear_rumor(rumor_offer))
	assert(rumors.buy_ar() and rumors.set_ar_equipped(true))
	var rumor_note: Dictionary = SandboxARHints.contextual(rumors, reveal_frame,
			{"npc_id": listener["id"], "destination": "clinic"}, true)
	assert(rumor_note["certainty"] == "unverified" and rumor_note["kind"] == "rumor")
	assert(str(rumor_note["source"]).contains(str(contact["id"])))
	assert(not str(rumor_note["text"]).contains("verified"))
	# Receipt is still provenance-checked and tagged as second-hand, not truth.
	var heard: Dictionary = {}
	for evt in rumors.events:
		if evt["kind"] == "player_rumor_heard":
			heard = evt
			break
	assert(heard.get("detail", {}).get("claim_source") == contact["id"])
	var rumor_save: Dictionary = rumors.snapshot()
	assert(SandboxWorld.new().restore_snapshot(rumor_save))
	# Exercise a natural, event-sourced property (never grant rumor magically).
	assert(str(heard["detail"]["fact"]).begins_with("residence:"))
	print("SANDBOX_AR_DOMAIN_PASS")
	quit(0)
