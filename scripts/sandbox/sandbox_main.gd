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

const REAL_SECONDS_PER_STEP: float = 10.0

var _world: SandboxWorld = SandboxWorld.new(7)
var _selected_id: String = ""
var _notice_text: String = "No scripted passengers. NPC needs generate every offer."
var _elapsed: float = 0.0


func _ready() -> void:
	_city.world = _world
	for district in SandboxRoads.DISTRICTS:
		_districts.add_item(district.capitalize())
	_districts.select(0)
	_offers.item_selected.connect(_on_selected)
	_accept.pressed.connect(_on_accept)
	_decline.pressed.connect(_on_decline)
	_reposition.pressed.connect(_on_reposition)
	$HUD/DockPanel/Content/TimeActions/Wait.pressed.connect(_on_wait)
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


func _on_accept() -> void:
	if _world.accept(_selected_id):
		_notice_text = "Job accepted. World time still moves; complete the route by waiting."
	else:
		_notice_text = "Not accessible: travel to origin or avoid licensed dispatch."
	_render()


func _on_decline() -> void:
	if _world.decline(_selected_id):
		_notice_text = "Offer declined. This NPC must reconsider its travel plans."
	_render()


func _on_reposition() -> void:
	var destination: String = SandboxRoads.DISTRICTS[_districts.get_selected_id()]
	if _world.reposition(destination):
		_notice_text = "Repositioned via city roads; offers continued aging."
	else:
		_notice_text = "Cannot move: already here, busy or insufficient credits."
	_render()


func _on_wait() -> void:
	_world.advance(20)
	_notice_text = "20 minutes passed. NPC needs and dispatch changed."
	_render()


func _on_new_seed() -> void:
	_world = SandboxWorld.new(_world.seed + 1)
	_city.world = _world
	_selected_id = ""
	_elapsed = 0.0
	_notice_text = "Fresh independent simulated city seed."
	_render()


func _on_save() -> void:
	_notice_text = "Sandbox saved." if SandboxSave.save_world(_world) else "Save failed."
	_render()


func _on_load() -> void:
	var saved: SandboxWorld = SandboxSave.load_world()
	if saved == null:
		_notice_text = "No valid sandbox save."
	else:
		_world = saved
		_city.world = saved
		_selected_id = ""
		_elapsed = 0.0
		_notice_text = "World and offer history restored."
	_render()


func _render() -> void:
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
			_selected_id = str(available[0]["id"])
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
	var phase: String = "enroute" if not _world.active_offer_id.is_empty() else "seeking"
	_world_info.text = "LIVING CITY\n\nOFFERS  %d open / %d total\nNPCs  %d\nEVENTS  %d\nSTATUS  %s\n\nUnlicensed residents cannot\naccept official-network jobs.\n\nTime runs: +10m each 10s.\nTaxi travel: 10m per graph edge.\nNo fixed scripted passenger." % [
		available.size(), _world.offers.size(), _world.residents.size(),
		_world.events.size(), phase.to_upper()
	]
	if not _world.active_offer_id.is_empty():
		var route: Dictionary = _world.offer_by_id(_world.active_offer_id)
		_notice.text = "ON ROUTE  %s -> %s  |  %dm remaining" % [
			route["origin"], route["destination"], _world.remaining_minutes
		]
	if OS.has_feature("web"):
		var web_state: String = "Object.assign(document.documentElement.dataset,{sandboxReady:'true',sandboxSeed:'%d',sandboxOffers:'%d',sandboxResidents:'%d',sandboxEvents:'%d',sandboxCredits:'%d',sandboxRisk:'%d',sandboxPhase:'%s',sandboxDistrict:'%s',sandboxSelected:'%s',sandboxAccepted:'%s',sandboxSettlements:'%d'})" % [
			_world.seed, available.size(), _world.residents.size(), _world.events.size(),
			_world.credits, _world.risk, phase, _world.player_district,
			_selected_id, str(not _accept.disabled).to_lower(), _settled_count()
		]
		JavaScriptBridge.eval(web_state, true)


func _settled_count() -> int:
	var total: int = 0
	for event in _world.events:
		if event["kind"] == "fare_settled":
			total += 1
	return total
