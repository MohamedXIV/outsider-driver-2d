extends Node2D

@onready var _city: SandboxCityView = $CityView
@onready var _status: Label = $HUD/DockPanel/Content/Status
@onready var _offers: ItemList = $HUD/DockPanel/Content/Offers
@onready var _details: Label = $HUD/DockPanel/Content/Details
@onready var _notice: Label = $HUD/DockPanel/Content/Notice
@onready var _accept: Button = $HUD/DockPanel/Content/Actions/Accept
@onready var _decline: Button = $HUD/DockPanel/Content/Actions/Decline
@onready var _districts: OptionButton = $HUD/DockPanel/Content/Navigation/District
@onready var _reposition: Button = $HUD/DockPanel/Content/Navigation/Reposition
@onready var _clock: Label = $HUD/DockPanel/Content/Clock
@onready var _world_info: Label = $HUD/WorldPanel/Content/WorldInfo
@onready var _observe: Button = $HUD/WorldPanel/Content/Observe
@onready var _talk: Button = $HUD/DockPanel/Content/Actions/Talk
@onready var _dialogue_panel: PanelContainer = $HUD/DialoguePanel
@onready var _dialogue_title: Label = $HUD/DialoguePanel/Content/Title
@onready var _dialogue_text: Label = $HUD/DialoguePanel/Content/Line
@onready var _dialogue_choices: VBoxContainer = $HUD/DialoguePanel/Content/Choices
@onready var _gear_panel: PanelContainer = $HUD/GearPanel
@onready var _gear_info: Label = $HUD/GearPanel/Content/Info
@onready var _gps: Button = $HUD/GearPanel/Content/Devices/GPS
@onready var _translator: Button = $HUD/GearPanel/Content/Devices/Translator
@onready var _radio: Button = $HUD/GearPanel/Content/Devices/Radio

const REAL_SECONDS_PER_STEP: float = 10.0

var _world: SandboxWorld = SandboxWorld.new(8)
var _selected_id: String = ""
var _notice_text: String = "No scripted passengers. NPC needs generate every offer."
var _elapsed: float = 0.0
var _conversation: SandboxConversation
var _last_intent: String = ""
var _last_outcome: String = ""


func _ready() -> void:
	_city.world = _world
	for district in SandboxRoads.DISTRICTS:
		_districts.add_item(district.capitalize())
	_districts.select(0)
	_offers.item_selected.connect(_on_selected)
	_gps.pressed.connect(_on_starter_device.bind("gps"))
	_translator.pressed.connect(_on_starter_device.bind("translator"))
	_radio.pressed.connect(_on_starter_device.bind("radio"))
	_talk.pressed.connect(_on_talk)
	_accept.pressed.connect(_on_accept)
	_decline.pressed.connect(_on_decline)
	_reposition.pressed.connect(_on_reposition)
	$HUD/DockPanel/Content/TimeActions/Wait.pressed.connect(_on_wait)
	_observe.pressed.connect(_on_observe)
	$HUD/DockPanel/Content/TimeActions/NewSeed.pressed.connect(_on_new_seed)
	$HUD/DockPanel/Content/Persistence/Save.pressed.connect(_on_save)
	$HUD/DockPanel/Content/Persistence/Load.pressed.connect(_on_load)
	_render()


func _process(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)
	if _elapsed >= REAL_SECONDS_PER_STEP:
		_elapsed -= REAL_SECONDS_PER_STEP
		_world.advance(10)
		_render()


func _on_selected(index: int) -> void:
	_selected_id = str(_offers.get_item_metadata(index))
	_render()


func _on_starter_device(device: String) -> void:
	if _world.select_starter_device(device):
		_notice_text = "Equipped %s. This only reveals its own kind of evidence." % device.to_upper()
		_conversation = null # Re-read live context on the next conversation.
	else:
		_notice_text = "Only one starter device per world; equipment already selected."
	_render()


func _on_talk() -> void:
	var conversation: SandboxConversation = SandboxConversation.new()
	if not conversation.open(_world, _selected_id, get_tree()):
		_notice_text = "Speak locally to an available resident; no valid offer here."
		_render()
		return
	_conversation = conversation
	_last_intent = "request_trip"
	_last_outcome = ""
	_notice_text = "The resident speaks. Speech is determined by NPC state."
	_render()


func _on_dialogue_choice(index: int) -> void:
	if _conversation == null or not _conversation.choose(index, _world):
		_notice_text = "That request is no longer valid."
		_conversation = null
		_last_outcome = "invalid"
		_render()
		return
	var frame: Dictionary = _conversation.current_frame()
	for tag in frame.get("tags", []):
		if str(tag).begins_with("intent:"):
			_last_intent = str(tag).trim_prefix("intent:")
	if _conversation.is_finished():
		_last_outcome = _conversation.outcome()
		_notice_text = "Conversation outcome: %s. The world owns the decision." % _last_outcome
		_conversation = null
	_render()


func _on_accept() -> void:
	if _world.accept(_selected_id):
		_conversation = null
		_last_outcome = "accepted"
		_notice_text = "Job accepted. World time still moves; complete the route by waiting."
	else:
		_notice_text = "Not accessible: travel to origin or avoid licensed dispatch."
	_render()


func _on_decline() -> void:
	if _world.decline(_selected_id):
		_conversation = null
		_last_outcome = "declined"
		_notice_text = "Offer declined. This NPC must reconsider its travel plans."
	_render()


func _on_reposition() -> void:
	var destination: String = SandboxRoads.DISTRICTS[_districts.get_selected_id()]
	if _world.reposition(destination):
		_conversation = null
		_notice_text = "Repositioned via city roads; offers continued aging."
	else:
		_notice_text = "Cannot move: already here, busy or insufficient credits."
	_render()


func _on_wait() -> void:
	_world.advance(20)
	_notice_text = "20 minutes passed. NPC needs and dispatch changed."
	_render()


func _on_observe() -> void:
	_world.advance(360)
	_notice_text = "Six simulated hours passed; independent residents continued their lives."
	_render()


func _on_new_seed() -> void:
	_world = SandboxWorld.new(_world.seed + 1)
	_conversation = null
	_last_intent = ""
	_last_outcome = ""
	_city.world = _world
	_selected_id = ""
	_elapsed = 0.0
	_notice_text = "Fresh independent simulated city seed."
	_render()


func _on_save() -> void:
	var dialogue_snapshot: Dictionary = _conversation.snapshot() if _conversation != null else {}
	_notice_text = "Sandbox saved." if SandboxSave.save_world(_world, SandboxSave.PATH, dialogue_snapshot) else "Save failed."
	_render()


func _on_load() -> void:
	var bundle: Dictionary = SandboxSave.load_bundle()
	if bundle.is_empty():
		_notice_text = "No valid sandbox save."
		_render()
		return
	var saved: SandboxWorld = bundle["world"] as SandboxWorld
	var restored: SandboxConversation = null
	var dialogue_state: Dictionary = bundle["dialogue"]
	if not dialogue_state.is_empty():
		restored = SandboxConversation.new()
		if not restored.restore(saved, dialogue_state, get_tree()):
			_notice_text = "Save has an invalid or expired conversation."
			_render()
			return
	_world = saved
	_city.world = saved
	_conversation = restored
	_selected_id = restored.offer_id if restored != null else ""
	_elapsed = 0.0
	_last_intent = "restored" if restored != null else ""
	_last_outcome = ""
	_notice_text = "World, NPC and live dialogue restored."
	_render()


func _render() -> void:
	if _conversation != null and not _conversation.still_valid(_world):
		_conversation = null
		_last_outcome = "expired"
		_notice_text = "That NPC request has expired or the speaker left."
	_city.queue_redraw()
	var clock_hour: int = (int(_world.minute) % 1440) / 60
	var clock_minute: int = int(_world.minute) % 60
	_status.text = "DISTRICT %s  |  WALLET %d cr  |  EXPOSURE %d" % [
		_world.player_district.to_upper(), _world.credits, _world.risk
	]
	_clock.text = "DAY %d  %02d:%02d  |  SEED %d  |  %d NPCs" % [
		int(_world.minute / 1440) + 1, clock_hour, clock_minute,
		_world.seed, _world.residents.size()
	]
	_offers.clear()
	var available: Array[Dictionary] = _world.open_offers()
	for offer in available:
		var locked: String = "[LICENSE]" if offer["channel"] == "official" else "[%s]" % str(offer["channel"]).to_upper()
		var line: String = "%s  %s > %s  %d cr  (%s)" % [
			locked, offer["origin"], offer["destination"], offer["fare"], offer["npc_id"]
		]
		_offers.add_item(line)
		_offers.set_item_metadata(_offers.item_count - 1, str(offer["id"]))
	if available.size() > 0:
		if _selected_id.is_empty() or _world.offer_by_id(_selected_id).get("status") != "open":
			# On arrival, focus a *real accessible local request* if one exists.
			_selected_id = str(available[0]["id"])
			for offer in available:
				if offer["origin"] == _world.player_district and offer["channel"] != "official":
					_selected_id = str(offer["id"])
					break
		for i in range(_offers.item_count):
			if _offers.get_item_metadata(i) == _selected_id:
				_offers.select(i)
				break
	else:
		_selected_id = ""
	var chosen: Dictionary = _world.offer_by_id(_selected_id)
	var npc: Dictionary = _world.resident(str(chosen.get("npc_id", "")))
	var eligible: bool = not chosen.is_empty() and chosen["origin"] == _world.player_district \
			and chosen["channel"] != "official" and _world.active_offer_id.is_empty()
	_accept.disabled = not eligible
	_talk.disabled = chosen.is_empty() or chosen["origin"] != _world.player_district \
			or not _world.active_offer_id.is_empty()
	_decline.disabled = chosen.is_empty()
	_reposition.disabled = not _world.active_offer_id.is_empty()
	if chosen.is_empty():
		_details.text = "No active offers. Time advances independently; Wait +20m to observe change."
	else:
		_details.text = "PURPOSE %s | NEED %d | CASH %d | LANGUAGE %s | EXPIRES IN %dm" % [
			chosen["purpose"], npc["need"], npc["cash"], npc["language"],
			maxi(0, int(chosen["expires_at"]) - _world.minute)
		]
	_notice.text = _notice_text
	_gear_panel.visible = true
	var gear_selected: bool = not _world.starter_device.is_empty()
	_gps.disabled = gear_selected
	_translator.disabled = gear_selected
	_radio.disabled = gear_selected
	match _world.starter_device:
		"gps":
			_gear_info.text = "GPS active: district graph known. To %s: %d road hops." % [
				str(chosen.get("destination", _world.player_district)),
				SandboxRoads.hops(_world.player_district, str(chosen.get("destination", _world.player_district)))
			]
		"translator":
			_gear_info.text = "Translator: local route marker LEARNED; other speech unknown." if _world.knows(SandboxKnowledge.ROUTE_MARKER) else \
					"Translator: uncalibrated. Ask a local speaker for a route to learn one marker."
		"radio":
			_gear_info.text = "Alien radio: 'Sha-ruu ... vekk nai ...' (no translation; local signal pattern recognized)."
		_:
			_gear_info.text = "Choose ONE starter: GPS (maps), Translator (limited phrases), Radio (alien broadcasts)."
	_dialogue_panel.visible = _conversation != null
	for button in _dialogue_choices.get_children():
		button.queue_free()
	if _conversation != null:
		var speaker_offer: Dictionary = _world.offer_by_id(_conversation.offer_id)
		var speaker: Dictionary = _world.resident(str(speaker_offer.get("npc_id", "")))
		_dialogue_title.text = "SPEAKING  |  %s  |  %s" % [
			speaker["id"], "trade speech" if _conversation.understood() else \
					("local speech / route marker recognized" if _conversation.recognizes_route() else "unfamiliar alien language")
		]
		var frame: Dictionary = _conversation.current_frame()
		_dialogue_text.text = str(frame.get("text", ""))
		var choices: Array = frame.get("choices", [])
		for i in range(choices.size()):
			var button: Button = Button.new()
			button.text = str(choices[i])
			button.custom_minimum_size = Vector2(0, 32)
			button.pressed.connect(_on_dialogue_choice.bind(i))
			_dialogue_choices.add_child(button)
	var phase: String = "enroute" if not _world.active_offer_id.is_empty() else "seeking"
	var departed: int = _count_events("npc_alternative_departed")
	var arrived: int = _count_events("npc_alternative_arrived")
	var working: int = _count_activity("working")
	var resting: int = _count_activity("resting")
	var moving: int = _count_activity("travelling")
	var recent: String = "No independent trips yet"
	for j in range(_world.events.size() - 1, -1, -1):
		var event: Dictionary = _world.events[j]
		if str(event["kind"]).begins_with("npc_alternative_"):
			recent = "%s %s" % [str(event["subject"]), str(event["kind"]).trim_prefix("npc_alternative_")]
			break
	_world_info.text = "LIVING CITY\nOFFERS %d / %d\nNPCs %d\nWORKING %d  RESTING %d\nTRAVELLING %d\nALT DEPARTURES %d\nALT ARRIVALS %d\nEVENTS %d\n%s\n\nNo player input required.\nSTATUS %s" % [
		available.size(), _world.offers.size(), _world.residents.size(),
		working, resting, moving, departed, arrived, _world.events.size(), recent, phase.to_upper()
	]
	if not _world.active_offer_id.is_empty():
		var route: Dictionary = _world.offer_by_id(_world.active_offer_id)
		_notice.text = "ON ROUTE  %s -> %s  |  %dm remaining" % [
			route["origin"], route["destination"], _world.remaining_minutes
		]
	if OS.has_feature("web"):
		var web_state: String = "Object.assign(document.documentElement.dataset,{sandboxReady:'true',sandboxSeed:'%d',sandboxOffers:'%d',sandboxResidents:'%d',sandboxEvents:'%d',sandboxCredits:'%d',sandboxRisk:'%d',sandboxPhase:'%s',sandboxDistrict:'%s',sandboxSelected:'%s',sandboxAccepted:'%s',sandboxSettlements:'%d',sandboxDialogue:'%s',sandboxDialogueChoices:'%d',sandboxDialogueUnderstood:'%s',sandboxDialogueOffer:'%s',sandboxDialogueIntent:'%s',sandboxDialogueOutcome:'%s',sandboxDialogueText:%s,sandboxDevice:'%s',sandboxKnowledge:'%d',sandboxRouteMarker:'%s',sandboxGearInfo:%s,sandboxAltDepartures:'%d',sandboxAltArrivals:'%d',sandboxWorkers:'%d',sandboxResting:'%d',sandboxNpcMoving:'%d',sandboxObserveRect:%s})" % [
			_world.seed, available.size(), _world.residents.size(), _world.events.size(),
			_world.credits, _world.risk, phase, _world.player_district,
			_selected_id, str(not _accept.disabled).to_lower(), _settled_count(),
			str(_conversation != null).to_lower(),
			_conversation.current_frame().get("choices", []).size() if _conversation != null else 0,
			str(_conversation.understood()).to_lower() if _conversation != null else "false",
			_conversation.offer_id if _conversation != null else "",
			_last_intent, _last_outcome, JSON.stringify(_dialogue_text.text if _conversation != null else ""),
			_world.starter_device, _world.knowledge.size(), str(_world.knows(SandboxKnowledge.ROUTE_MARKER)).to_lower(),
			JSON.stringify(_gear_info.text), departed, arrived, working, resting, moving,
			JSON.stringify([
				int(_observe.get_global_rect().position.x), int(_observe.get_global_rect().position.y),
				int(_observe.get_global_rect().size.x), int(_observe.get_global_rect().size.y)
			])
		]
		JavaScriptBridge.eval(web_state, true)


func _settled_count() -> int:
	var total: int = 0
	for event in _world.events:
		if event["kind"] == "fare_settled":
			total += 1
	return total

func _count_activity(activity: String) -> int:
	var total: int = 0
	for npc in _world.residents:
		if str(npc.get("activity", "")) == activity:
			total += 1
	return total


func _count_events(kind: String) -> int:
	var total: int = 0
	for event in _world.events:
		if event["kind"] == kind:
			total += 1
	return total
