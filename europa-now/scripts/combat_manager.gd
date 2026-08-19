class_name CombatManager
extends Node

signal combat_started(combat: CombatState)
signal combat_updated(combat: CombatState)
signal combat_ended(combat: CombatState)
signal province_captured(province_id: String, new_controller_id: String)

var war_state: WarState
var _country_colors: Dictionary = {}

var _unit_manager: UnitManager
var _provinces_by_id: Dictionary = {}
var _adjacency: ProvinceAdjacency
var _combats_by_id: Dictionary = {}
var _combats_by_province: Dictionary = {}
var _combat_counter := 0


func initialize(
	unit_manager: UnitManager,
	provinces: Array[Province],
	adjacency: ProvinceAdjacency,
	war: WarState,
	country_colors: Dictionary = {}
) -> void:
	_unit_manager = unit_manager
	_adjacency = adjacency
	war_state = war
	_country_colors = country_colors
	_provinces_by_id.clear()
	for province in provinces:
		_provinces_by_id[province.province_id] = province


func get_combat_at_province(province_id: String) -> CombatState:
	return _combats_by_province.get(province_id)


func get_combat_for_unit(unit_id: String) -> CombatState:
	for combat: CombatState in _combats_by_id.values():
		if not combat.is_active():
			continue
		if unit_id in combat.attacker_unit_ids or unit_id in combat.defender_unit_ids:
			return combat
	return null


func get_active_combats() -> Array[CombatState]:
	var result: Array[CombatState] = []
	for combat: CombatState in _combats_by_id.values():
		if combat.is_active():
			result.append(combat)
	return result


func on_unit_arrived(unit: Unit, was_moving: bool = true) -> void:
	var province_id := unit.data.current_province_id
	if _try_join_or_start_combat(unit, was_moving):
		return
	_try_peaceful_capture(unit, province_id)


func on_day_advanced(_date: GameDate) -> void:
	var combats_to_process: Array[CombatState] = []
	for combat: CombatState in _combats_by_id.values():
		if combat.is_active():
			combats_to_process.append(combat)

	for combat in combats_to_process:
		_process_combat_day(combat)


func on_peace_signed(country_a: String, country_b: String) -> void:
	var combats_to_end: Array[CombatState] = []
	for combat: CombatState in _combats_by_id.values():
		if not combat.is_active():
			continue
		if _combat_contains_country_pair(combat, country_a, country_b):
			combats_to_end.append(combat)

	for combat in combats_to_end:
		_end_combat_without_battle_winner(combat)


func handle_province_after_arrivals(province_id: String) -> void:
	if _combats_by_province.has(province_id):
		return

	var hostile_groups: Array = _collect_hostile_groups_in_province(province_id)
	if hostile_groups.size() < 2:
		return

	_start_combat_from_groups(province_id, hostile_groups[0], hostile_groups[1])


func get_save_data() -> Dictionary:
	var combats: Array = []
	for combat: CombatState in _combats_by_id.values():
		combats.append(combat.to_dict())
	return {
		"combats": combats,
		"combat_counter": _combat_counter,
	}


func load_save_data(data: Dictionary) -> void:
	_combats_by_id.clear()
	_combats_by_province.clear()
	_combat_counter = int(data.get("combat_counter", 0))
	for entry in data.get("combats", []):
		var combat: CombatState = CombatState.from_dict(entry)
		_register_combat(combat)
		_sync_province_contested(combat.province_id)


func _try_join_or_start_combat(arriving_unit: Unit, was_moving: bool) -> bool:
	var province_id := arriving_unit.data.current_province_id
	var existing: CombatState = _combats_by_province.get(province_id)
	if existing != null and existing.is_active():
		_add_unit_to_combat(existing, arriving_unit)
		return true

	var enemies: Array[Unit] = _find_hostile_units_in_province(arriving_unit)
	if enemies.is_empty():
		return false

	var defenders: Array[Unit] = []
	var attackers: Array[Unit] = [arriving_unit]
	for enemy in enemies:
		if was_moving:
			defenders.append(enemy)
		else:
			attackers.append(enemy)

	if defenders.is_empty():
		defenders = enemies
		attackers = [arriving_unit]

	_start_combat(province_id, attackers, defenders)
	return true


func _try_peaceful_capture(unit: Unit, province_id: String) -> void:
	var province: Province = _provinces_by_id.get(province_id)
	if province == null:
		return
	if province.controller_country_id == unit.data.owner_country_id:
		return
	if not war_state.are_at_war(unit.data.owner_country_id, province.controller_country_id):
		return
	if _has_hostile_units_in_province(unit):
		return

	_capture_province(province, unit.data.owner_country_id)


func _start_combat_from_groups(
	province_id: String,
	attackers: Array[Unit],
	defenders: Array[Unit]
) -> void:
	_start_combat(province_id, attackers, defenders)


func _start_combat(province_id: String, attackers: Array[Unit], defenders: Array[Unit]) -> void:
	if attackers.is_empty() or defenders.is_empty():
		return

	_combat_counter += 1
	var combat: CombatState = CombatState.new()
	combat.combat_id = "combat_%d" % _combat_counter
	combat.province_id = province_id
	combat.start_date = GameTime.current_date.duplicate_date()

	for unit in attackers:
		_add_unit_id_to_side(combat, unit, true)
	for unit in defenders:
		_add_unit_id_to_side(combat, unit, false)

	_register_combat(combat)
	_set_province_contested(province_id, true)
	combat_started.emit(combat)


func _add_unit_to_combat(combat: CombatState, unit: Unit) -> void:
	var is_attacker: bool = _unit_belongs_to_side(unit, combat.attacker_country_ids)
	var is_defender: bool = _unit_belongs_to_side(unit, combat.defender_country_ids)
	if is_attacker:
		_add_unit_id_to_side(combat, unit, true)
	elif is_defender:
		_add_unit_id_to_side(combat, unit, false)
	else:
		var arriving_was_attacker: bool = not _side_has_stationary_units(combat.defender_unit_ids, unit.data.unit_id)
		_add_unit_id_to_side(combat, unit, arriving_was_attacker)
	combat_updated.emit(combat)


func _add_unit_id_to_side(combat: CombatState, unit: Unit, is_attacker: bool) -> void:
	var unit_id := unit.data.unit_id
	var country_id := unit.data.owner_country_id
	if is_attacker:
		if unit_id not in combat.attacker_unit_ids:
			combat.attacker_unit_ids.append(unit_id)
		if country_id not in combat.attacker_country_ids:
			combat.attacker_country_ids.append(country_id)
	else:
		if unit_id not in combat.defender_unit_ids:
			combat.defender_unit_ids.append(unit_id)
		if country_id not in combat.defender_country_ids:
			combat.defender_country_ids.append(country_id)

	unit.data.combat_id = combat.combat_id
	unit.data.is_in_combat = true
	unit.set_in_combat(true)
	if unit.data.is_moving:
		unit.cancel_movement()


func _process_combat_day(combat: CombatState) -> void:
	var attacker_units: Array[Unit] = _get_units_by_ids(combat.attacker_unit_ids)
	var defender_units: Array[Unit] = _get_units_by_ids(combat.defender_unit_ids)

	for unit in attacker_units + defender_units:
		CombatCalculator.apply_daily_wear(unit.data)

	var losses: Dictionary = CombatCalculator.calculate_daily_casualties(attacker_units, defender_units)
	combat.attacker_casualties += CombatCalculator.apply_casualties_to_side(attacker_units, losses["attacker"])
	combat.defender_casualties += CombatCalculator.apply_casualties_to_side(defender_units, losses["defender"])
	combat.days_fought += 1

	combat_updated.emit(combat)

	if not CombatCalculator.should_end_combat(attacker_units, defender_units, combat.days_fought):
		return

	var winner_side: String = CombatCalculator.determine_winner_side(attacker_units, defender_units)
	_resolve_combat(combat, winner_side)


func _resolve_combat(combat: CombatState, winner_side: String) -> void:
	combat.status = CombatState.Status.ENDED
	combat.winner_side = winner_side

	var attacker_units: Array[Unit] = _get_units_by_ids(combat.attacker_unit_ids)
	var defender_units: Array[Unit] = _get_units_by_ids(combat.defender_unit_ids)
	var winner_units: Array[Unit] = attacker_units if winner_side == "attacker" else defender_units
	var loser_units: Array[Unit] = defender_units if winner_side == "attacker" else attacker_units

	for unit in attacker_units + defender_units:
		unit.data.is_in_combat = false
		unit.data.combat_id = ""
		unit.set_in_combat(false)

	var province: Province = _provinces_by_id.get(combat.province_id)
	if winner_side == "attacker" and province != null:
		var new_owner: String = combat.attacker_country_ids[0]
		_capture_province(province, new_owner)

	for unit in loser_units:
		_order_retreat_or_destroy(unit)

	_set_province_contested(combat.province_id, false)
	_combats_by_province.erase(combat.province_id)
	combat_ended.emit(combat)


func _end_combat_without_battle_winner(combat: CombatState) -> void:
	combat.status = CombatState.Status.ENDED
	combat.winner_side = "peace"
	var units := _get_units_by_ids(combat.attacker_unit_ids)
	units.append_array(_get_units_by_ids(combat.defender_unit_ids))
	for unit in units:
		unit.data.is_in_combat = false
		unit.data.combat_id = ""
		unit.set_in_combat(false)
	_set_province_contested(combat.province_id, false)
	_combats_by_province.erase(combat.province_id)
	combat_ended.emit(combat)


func _combat_contains_country_pair(
	combat: CombatState,
	country_a: String,
	country_b: String
) -> bool:
	for attacker_country in combat.attacker_country_ids:
		for defender_country in combat.defender_country_ids:
			if (
				(attacker_country == country_a and defender_country == country_b)
				or (attacker_country == country_b and defender_country == country_a)
			):
				return true
	return false


func _capture_province(province: Province, country_id: String) -> void:
	province.set_controller(country_id)
	province.set_controller_color(
		_country_colors.get(country_id, Color.TRANSPARENT)
	)
	province.set_owner_country(country_id)
	province_captured.emit(province.province_id, country_id)


func _order_retreat_or_destroy(unit: Unit) -> void:
	if unit.data.soldiers <= 0:
		_unit_manager.destroy_unit(unit)
		return

	var retreat_target: String = CombatRetreat.find_retreat_province(
		unit.data,
		unit.data.current_province_id,
		_adjacency,
		_provinces_by_id
	)
	if retreat_target.is_empty():
		_unit_manager.destroy_unit(unit)
		return

	_unit_manager.order_retreat(unit, retreat_target)


func _find_hostile_units_in_province(unit: Unit) -> Array[Unit]:
	var result: Array[Unit] = []
	for other in _unit_manager.get_units_in_province(unit.data.current_province_id):
		if other == unit:
			continue
		if other.data.is_retreating:
			continue
		if war_state.are_at_war(unit.data.owner_country_id, other.data.owner_country_id):
			result.append(other)
	return result


func _has_hostile_units_in_province(unit: Unit) -> bool:
	return not _find_hostile_units_in_province(unit).is_empty()


func _collect_hostile_groups_in_province(province_id: String) -> Array:
	var units: Array[Unit] = _unit_manager.get_units_in_province(province_id)
	var groups: Dictionary = {}
	for unit in units:
		if unit.data.is_retreating:
			continue
		var country_id := unit.data.owner_country_id
		if not groups.has(country_id):
			groups[country_id] = []
		groups[country_id].append(unit)

	var country_ids: Array[String] = []
	for country_id in groups:
		country_ids.append(country_id)

	for i in country_ids.size():
		for j in range(i + 1, country_ids.size()):
			var a: String = country_ids[i]
			var b: String = country_ids[j]
			if war_state.are_at_war(a, b):
				return [groups[a], groups[b]]
	return []


func _get_units_by_ids(unit_ids: Array[String]) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit_id in unit_ids:
		var unit: Unit = _unit_manager.get_unit(unit_id)
		if unit != null:
			result.append(unit)
	return result


func _register_combat(combat: CombatState) -> void:
	_combats_by_id[combat.combat_id] = combat
	_combats_by_province[combat.province_id] = combat


func _sync_province_contested(province_id: String) -> void:
	var combat: CombatState = _combats_by_province.get(province_id)
	_set_province_contested(province_id, combat != null and combat.is_active())


func _set_province_contested(province_id: String, contested: bool) -> void:
	var province: Province = _provinces_by_id.get(province_id)
	if province != null:
		province.set_contested(contested)


func _unit_belongs_to_side(unit: Unit, country_ids: Array[String]) -> bool:
	return unit.data.owner_country_id in country_ids


func _side_has_stationary_units(unit_ids: Array[String], exclude_unit_id: String) -> bool:
	for unit_id in unit_ids:
		if unit_id == exclude_unit_id:
			continue
		var unit: Unit = _unit_manager.get_unit(unit_id)
		if unit != null and not unit.data.is_moving:
			return true
	return false
