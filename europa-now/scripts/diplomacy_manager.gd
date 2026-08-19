class_name DiplomacyManager
extends Node

signal war_declared(source_country_id: String, target_country_id: String)
signal peace_signed(source_country_id: String, target_country_id: String)
signal treaty_created(treaty: DiplomaticTreaty)
signal treaty_expired(treaty: DiplomaticTreaty)
signal relationship_changed(country_a: String, country_b: String, score: int)
signal diplomatic_action_received(action: DiplomaticAction)
signal diplomatic_action_resolved(action: DiplomaticAction)
signal diplomacy_error(message: String)

const ACTION_DECLARE_WAR := "declare_war"
const ACTION_OFFER_PEACE := "offer_peace"
const ACTION_OFFER_NAP := "offer_non_aggression_pact"
const ACTION_OFFER_ALLIANCE := "offer_alliance"

const TREATY_NAP := "non_aggression_pact"
const TREATY_ALLIANCE := "alliance"

const NAP_DURATION_DAYS := 180
const RELATIONSHIP_DECLARE_WAR := -60
const RELATIONSHIP_PEACE := 10
const RELATIONSHIP_NAP := 8
const RELATIONSHIP_ALLIANCE := 20
const RELATIONSHIP_BREAK_TREATY := -35
const RELATIONSHIP_REJECT_OFFER := -5

var player_country_id := "DEU"
var _war_state := WarState.new()
var _relationships: Dictionary = {}
var _treaties: Dictionary = {}
var _actions: Dictionary = {}
var _action_counter := 0
var _treaty_counter := 0


func initialize(country_ids: Array[String], initial_wars: Array[Array] = []) -> void:
	_relationships.clear()
	_treaties.clear()
	_actions.clear()
	_action_counter = 0
	_treaty_counter = 0
	_war_state = WarState.new()

	for i in country_ids.size():
		for j in range(i + 1, country_ids.size()):
			_relationships[_pair_key(country_ids[i], country_ids[j])] = 0

	for war_pair in initial_wars:
		if war_pair.size() >= 2:
			var country_a := str(war_pair[0])
			var country_b := str(war_pair[1])
			_war_state.set_war(country_a, country_b, true)
			_relationships[_pair_key(country_a, country_b)] = RELATIONSHIP_DECLARE_WAR

	if not GameTime.day_advanced.is_connected(_on_day_advanced):
		GameTime.day_advanced.connect(_on_day_advanced)


func get_war_state() -> WarState:
	return _war_state


func is_at_war(country_a: String, country_b: String) -> bool:
	return _war_state.are_at_war(country_a, country_b)


func get_relationship(country_a: String, country_b: String) -> int:
	if country_a == country_b:
		return 100
	return int(_relationships.get(_pair_key(country_a, country_b), 0))


func change_relationship(country_a: String, country_b: String, amount: int) -> int:
	var score := clampi(
		get_relationship(country_a, country_b) + amount,
		-100,
		100
	)
	_relationships[_pair_key(country_a, country_b)] = score
	relationship_changed.emit(country_a, country_b, score)
	return score


func are_allied(country_a: String, country_b: String) -> bool:
	return _has_active_treaty(country_a, country_b, TREATY_ALLIANCE)


func have_non_aggression_pact(country_a: String, country_b: String) -> bool:
	return _has_active_treaty(country_a, country_b, TREATY_NAP)


func get_treaty(country_a: String, country_b: String, treaty_type: String) -> DiplomaticTreaty:
	for treaty: DiplomaticTreaty in _treaties.values():
		if treaty.treaty_type != treaty_type or not treaty.is_active(GameTime.current_date):
			continue
		if (
			(treaty.country_a == country_a and treaty.country_b == country_b)
			or (treaty.country_a == country_b and treaty.country_b == country_a)
		):
			return treaty
	return null


func get_pending_actions_for(country_id: String) -> Array[DiplomaticAction]:
	var result: Array[DiplomaticAction] = []
	for action: DiplomaticAction in _actions.values():
		if (
			action.target_country_id == country_id
			and action.status == DiplomaticAction.Status.PENDING
		):
			result.append(action)
	return result


func get_pending_actions() -> Array[DiplomaticAction]:
	var result: Array[DiplomaticAction] = []
	for action: DiplomaticAction in _actions.values():
		if action.status == DiplomaticAction.Status.PENDING:
			result.append(action)
	return result


func declare_war(source_country_id: String, target_country_id: String) -> bool:
	if not _validate_pair(source_country_id, target_country_id):
		return false
	if is_at_war(source_country_id, target_country_id):
		return _reject("Diese Laender befinden sich bereits im Krieg.")

	if have_non_aggression_pact(source_country_id, target_country_id):
		_cancel_treaty(source_country_id, target_country_id, TREATY_NAP)
		change_relationship(
			source_country_id,
			target_country_id,
			RELATIONSHIP_BREAK_TREATY
		)
	if are_allied(source_country_id, target_country_id):
		_cancel_treaty(source_country_id, target_country_id, TREATY_ALLIANCE)
		change_relationship(
			source_country_id,
			target_country_id,
			RELATIONSHIP_BREAK_TREATY
		)

	_war_state.set_war(source_country_id, target_country_id, true)
	change_relationship(source_country_id, target_country_id, RELATIONSHIP_DECLARE_WAR)
	var action := _record_completed_action(
		ACTION_DECLARE_WAR,
		source_country_id,
		target_country_id
	)
	diplomatic_action_resolved.emit(action)
	war_declared.emit(source_country_id, target_country_id)
	return true


func offer_peace(source_country_id: String, target_country_id: String) -> DiplomaticAction:
	if not is_at_war(source_country_id, target_country_id):
		return _reject_action("Zwischen diesen Laendern herrscht bereits Frieden.")
	var action := _create_action(ACTION_OFFER_PEACE, source_country_id, target_country_id)
	accept_action(action.action_id)
	return action


func offer_non_aggression_pact(
	source_country_id: String,
	target_country_id: String
) -> DiplomaticAction:
	if is_at_war(source_country_id, target_country_id):
		return _reject_action("Ein NAP ist waehrend eines Krieges nicht moeglich.")
	if have_non_aggression_pact(source_country_id, target_country_id):
		return _reject_action("Es existiert bereits ein Nichtangriffspakt.")
	var action := _create_action(ACTION_OFFER_NAP, source_country_id, target_country_id)
	accept_action(action.action_id)
	return action


func offer_alliance(
	source_country_id: String,
	target_country_id: String
) -> DiplomaticAction:
	if is_at_war(source_country_id, target_country_id):
		return _reject_action("Ein Buendnis ist waehrend eines Krieges nicht moeglich.")
	if are_allied(source_country_id, target_country_id):
		return _reject_action("Diese Laender sind bereits verbuendet.")
	var action := _create_action(ACTION_OFFER_ALLIANCE, source_country_id, target_country_id)
	accept_action(action.action_id)
	return action


func accept_action(action_id: String) -> bool:
	var action: DiplomaticAction = _actions.get(action_id)
	if action == null or action.status != DiplomaticAction.Status.PENDING:
		return false
	action.status = DiplomaticAction.Status.ACCEPTED
	_apply_action(action)
	diplomatic_action_resolved.emit(action)
	return true


func reject_action(action_id: String) -> bool:
	var action: DiplomaticAction = _actions.get(action_id)
	if action == null or action.status != DiplomaticAction.Status.PENDING:
		return false
	action.status = DiplomaticAction.Status.REJECTED
	change_relationship(
		action.source_country_id,
		action.target_country_id,
		RELATIONSHIP_REJECT_OFFER
	)
	diplomatic_action_resolved.emit(action)
	return true


func get_save_data() -> Dictionary:
	var relationships: Dictionary = {}
	for key in _relationships:
		relationships[str(key)] = _relationships[key]
	var treaties: Array = []
	for treaty: DiplomaticTreaty in _treaties.values():
		treaties.append(treaty.to_dict())
	var actions: Array = []
	for action: DiplomaticAction in _actions.values():
		actions.append(action.to_dict())
	return {
		"player_country_id": player_country_id,
		"relationships": relationships,
		"war_state": _war_state.to_dict(),
		"treaties": treaties,
		"actions": actions,
		"action_counter": _action_counter,
		"treaty_counter": _treaty_counter,
	}


func load_save_data(data: Dictionary) -> void:
	player_country_id = str(data.get("player_country_id", "DEU"))
	_relationships.clear()
	for key in data.get("relationships", {}):
		_relationships[str(key)] = int(data["relationships"][key])
	_war_state.load_from_dict(data.get("war_state", {}))
	_treaties.clear()
	for entry in data.get("treaties", []):
		var treaty := DiplomaticTreaty.from_dict(entry)
		_treaties[treaty.treaty_id] = treaty
	_actions.clear()
	for entry in data.get("actions", []):
		var action := DiplomaticAction.from_dict(entry)
		_actions[action.action_id] = action
	_action_counter = int(data.get("action_counter", 0))
	_treaty_counter = int(data.get("treaty_counter", 0))


func _on_day_advanced(date: GameDate) -> void:
	var expired: Array[DiplomaticTreaty] = []
	for treaty: DiplomaticTreaty in _treaties.values():
		if treaty.status == DiplomaticTreaty.Status.ACTIVE and treaty.end_date != null:
			if date.is_on_or_after(treaty.end_date):
				expired.append(treaty)
	for treaty in expired:
		treaty.status = DiplomaticTreaty.Status.EXPIRED
		treaty_expired.emit(treaty)


func _apply_action(action: DiplomaticAction) -> void:
	match action.action_type:
		ACTION_OFFER_PEACE:
			_war_state.set_war(
				action.source_country_id,
				action.target_country_id,
				false
			)
			change_relationship(
				action.source_country_id,
				action.target_country_id,
				RELATIONSHIP_PEACE
			)
			action.status = DiplomaticAction.Status.COMPLETED
			peace_signed.emit(action.source_country_id, action.target_country_id)
		ACTION_OFFER_NAP:
			_create_treaty(
				TREATY_NAP,
				action.source_country_id,
				action.target_country_id,
				GameTime.current_date.add_days(NAP_DURATION_DAYS)
			)
			change_relationship(
				action.source_country_id,
				action.target_country_id,
				RELATIONSHIP_NAP
			)
			action.status = DiplomaticAction.Status.COMPLETED
		ACTION_OFFER_ALLIANCE:
			_create_treaty(
				TREATY_ALLIANCE,
				action.source_country_id,
				action.target_country_id,
				null
			)
			change_relationship(
				action.source_country_id,
				action.target_country_id,
				RELATIONSHIP_ALLIANCE
			)
			action.status = DiplomaticAction.Status.COMPLETED


func _create_action(
	action_type: String,
	source_country_id: String,
	target_country_id: String
) -> DiplomaticAction:
	_action_counter += 1
	var action := DiplomaticAction.new()
	action.action_id = "diplomatic_action_%d" % _action_counter
	action.action_type = action_type
	action.source_country_id = source_country_id
	action.target_country_id = target_country_id
	action.date = GameTime.current_date.duplicate_date()
	_actions[action.action_id] = action
	diplomatic_action_received.emit(action)
	return action


func _record_completed_action(
	action_type: String,
	source_country_id: String,
	target_country_id: String
) -> DiplomaticAction:
	_action_counter += 1
	var action := DiplomaticAction.new()
	action.action_id = "diplomatic_action_%d" % _action_counter
	action.action_type = action_type
	action.source_country_id = source_country_id
	action.target_country_id = target_country_id
	action.date = GameTime.current_date.duplicate_date()
	action.status = DiplomaticAction.Status.COMPLETED
	_actions[action.action_id] = action
	return action


func _create_treaty(
	treaty_type: String,
	country_a: String,
	country_b: String,
	end_date: GameDate
) -> DiplomaticTreaty:
	_treaty_counter += 1
	var treaty := DiplomaticTreaty.new()
	treaty.treaty_id = "treaty_%d" % _treaty_counter
	treaty.treaty_type = treaty_type
	treaty.country_a = country_a
	treaty.country_b = country_b
	treaty.start_date = GameTime.current_date.duplicate_date()
	treaty.end_date = end_date
	_treaties[treaty.treaty_id] = treaty
	treaty_created.emit(treaty)
	return treaty


func _cancel_treaty(country_a: String, country_b: String, treaty_type: String) -> void:
	var treaty := get_treaty(country_a, country_b, treaty_type)
	if treaty != null:
		treaty.status = DiplomaticTreaty.Status.CANCELLED


func _has_active_treaty(country_a: String, country_b: String, treaty_type: String) -> bool:
	return get_treaty(country_a, country_b, treaty_type) != null


func _validate_pair(country_a: String, country_b: String) -> bool:
	if country_a.is_empty() or country_b.is_empty() or country_a == country_b:
		_reject("Ungueltige Laenderkombination.")
		return false
	return true


func _reject(message: String) -> bool:
	diplomacy_error.emit(message)
	return false


func _reject_action(message: String) -> DiplomaticAction:
	diplomacy_error.emit(message)
	return null


static func _pair_key(country_a: String, country_b: String) -> String:
	if country_a < country_b:
		return "%s|%s" % [country_a, country_b]
	return "%s|%s" % [country_b, country_a]
