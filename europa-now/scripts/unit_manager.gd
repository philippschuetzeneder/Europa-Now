class_name UnitManager
extends Node2D

signal unit_selected(unit: Unit)
signal unit_move_ordered(unit: Unit, destination_id: String, arrival_date: GameDate)
signal unit_arrived(unit: Unit, province_id: String)
signal unit_retreat_ordered(unit: Unit, destination_id: String, arrival_date: GameDate)
signal unit_destroyed(unit: Unit)

const TRAVEL_DAYS := 3

var combat_manager: CombatManager
var war_state: WarState

var _provinces_by_id: Dictionary = {}
var _adjacency: ProvinceAdjacency
var _units: Array[Unit] = []
var _units_by_id: Dictionary = {}
var _selected_unit: Unit
var _pending_arrivals: Array[Dictionary] = []
var _recruited_army_counter := 0
var _current_zoom := 1.0


func _ready() -> void:
	GameTime.day_advanced.connect(_on_day_advanced)


func initialize(
	provinces: Array[Province],
	adjacency: ProvinceAdjacency,
	start_province_id: String,
	enemy_province_id: String = "",
	war: WarState = null
) -> void:
	_provinces_by_id.clear()
	_adjacency = adjacency
	war_state = war
	for province in provinces:
		_provinces_by_id[province.province_id] = province

	_spawn_starting_units(start_province_id, enemy_province_id, war)


func get_unit(unit_id: String) -> Unit:
	return _units_by_id.get(unit_id)


func get_units() -> Array[Unit]:
	return _units


func get_save_data() -> Dictionary:
	var units_data: Array = []
	for unit in _units:
		units_data.append(unit.data.to_dict())
	return {
		"units": units_data,
		"recruited_army_counter": _recruited_army_counter,
	}


func load_save_data(data: Dictionary) -> void:
	for unit in _units.duplicate():
		unit.queue_free()
	_units.clear()
	_units_by_id.clear()
	_selected_unit = null
	_recruited_army_counter = int(data.get("recruited_army_counter", 0))
	for entry in data.get("units", []):
		var unit_data: UnitData = UnitData.from_dict(entry)
		_add_unit(unit_data)


func create_recruited_army(
	country_id: String,
	province_id: String,
	soldiers: int
) -> Unit:
	if not _provinces_by_id.has(province_id) or soldiers <= 0:
		return null
	var province: Province = _provinces_by_id[province_id]
	if province.controller_country_id != country_id:
		return null

	_recruited_army_counter += 1
	var unit_data := UnitData.new(
		"%s_RECRUIT_%d" % [country_id, _recruited_army_counter],
		"Army",
		country_id,
		province_id,
		soldiers,
		100
	)
	_add_unit(unit_data)
	return _units_by_id.get(unit_data.unit_id)


func get_units_in_province(province_id: String) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in _units:
		if unit.data.current_province_id == province_id and unit.data.soldiers > 0:
			result.append(unit)
	return result


func get_selected_unit() -> Unit:
	return _selected_unit


func select_unit(unit: Unit) -> void:
	if _selected_unit == unit:
		return
	if _selected_unit != null:
		_selected_unit.set_selected(false)
	_selected_unit = unit
	unit.set_selected(true)
	unit_selected.emit(unit)


func clear_unit_selection() -> void:
	if _selected_unit != null:
		_selected_unit.set_selected(false)
	_selected_unit = null


func get_move_block_reason(unit: Unit, province_id: String) -> String:
	if unit.data.is_in_combat:
		return "Einheit kaempft."
	if unit.data.is_retreating:
		return "Einheit zieht sich zurueck."
	if unit.data.is_moving:
		return "Einheit ist bereits unterwegs."
	if not _provinces_by_id.has(province_id):
		return "Unbekannte Zielprovinz."
	if unit.data.current_province_id == province_id:
		return "Einheit befindet sich bereits in dieser Provinz."
	if _adjacency == null or not _adjacency.are_neighbors(unit.data.current_province_id, province_id):
		return "Nur benachbarte Provinzen sind erreichbar."
	var destination: Province = _provinces_by_id[province_id]
	if destination.controller_country_id == unit.data.owner_country_id:
		return ""
	if war_state == null or not war_state.are_at_war(
		unit.data.owner_country_id,
		destination.controller_country_id
	):
		return "Dieses Land ist nicht am Krieg beteiligt."
	return ""


func order_move_to_province(unit: Unit, province_id: String) -> bool:
	if not get_move_block_reason(unit, province_id).is_empty():
		return false

	var arrival_date := GameTime.current_date.add_days(TRAVEL_DAYS)
	unit.data.destination_province_id = province_id
	unit.data.arrival_date = arrival_date
	unit.set_moving(true)

	unit_move_ordered.emit(unit, province_id, arrival_date)
	return true


func order_retreat(unit: Unit, province_id: String) -> bool:
	if not _provinces_by_id.has(province_id):
		return false
	var destination: Province = _provinces_by_id[province_id]
	if destination.controller_country_id != unit.data.owner_country_id:
		return false

	var arrival_days := CombatRetreat.RETREAT_DAYS
	if _adjacency == null or not _adjacency.are_neighbors(unit.data.current_province_id, province_id):
		arrival_days = CombatRetreat.RETREAT_DAYS + 1
	var arrival_date := GameTime.current_date.add_days(arrival_days)
	unit.data.retreat_destination_id = province_id
	unit.data.retreat_arrival_date = arrival_date
	unit.data.is_retreating = true
	unit.set_retreating(true)
	unit_retreat_ordered.emit(unit, province_id, arrival_date)
	return true


func destroy_unit(unit: Unit) -> void:
	var province_id := unit.data.current_province_id
	if _selected_unit == unit:
		_selected_unit = null
	_units.erase(unit)
	_units_by_id.erase(unit.data.unit_id)
	unit_destroyed.emit(unit)
	unit.queue_free()
	_refresh_province_unit_positions(province_id)


func update_zoom_scale(zoom_level: float) -> void:
	_current_zoom = zoom_level
	for unit in _units:
		unit.update_zoom_scale(zoom_level)


func pick_unit_at(world_pos: Vector2) -> Unit:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Unit.COLLISION_LAYER_UNITS

	for x_offset in GeoProjection.wrap_offsets():
		params.position = world_pos + Vector2(x_offset, 0.0)
		for hit in space.intersect_point(params, 8):
			var collider: Variant = hit.get("collider")
			if collider is Unit and collider.visible:
				return collider
	return null


func _on_day_advanced(date: GameDate) -> void:
	if combat_manager != null:
		combat_manager.on_day_advanced(date)
	_process_retreats(date)
	_process_moves(date)
	_finalize_arrivals()


func _process_moves(date: GameDate) -> void:
	for unit in _units:
		if not unit.data.is_moving or unit.data.is_retreating:
			continue
		if unit.data.arrival_date == null:
			continue
		if date.is_on_or_after(unit.data.arrival_date):
			_queue_arrival(unit, true)


func _process_retreats(date: GameDate) -> void:
	for unit in _units:
		if not unit.data.is_retreating:
			continue
		if unit.data.retreat_arrival_date == null:
			continue
		if date.is_on_or_after(unit.data.retreat_arrival_date):
			_complete_retreat(unit)


func _queue_arrival(unit: Unit, was_moving: bool) -> void:
	var destination_id := unit.data.destination_province_id
	unit.data.current_province_id = destination_id
	unit.data.destination_province_id = ""
	unit.data.arrival_date = null
	unit.set_moving(false)
	unit.place_on_province(_provinces_by_id[destination_id])
	_pending_arrivals.append({"unit": unit, "province_id": destination_id, "was_moving": was_moving})
	_refresh_province_unit_positions(destination_id)


func _finalize_arrivals() -> void:
	if _pending_arrivals.is_empty():
		return

	var arrivals: Array[Dictionary] = _pending_arrivals.duplicate()
	_pending_arrivals.clear()

	var provinces_touched: Dictionary = {}
	for entry in arrivals:
		var unit: Unit = entry["unit"]
		var province_id: String = entry["province_id"]
		var was_moving: bool = entry["was_moving"]
		unit_arrived.emit(unit, province_id)
		if combat_manager != null:
			combat_manager.on_unit_arrived(unit, was_moving)
		provinces_touched[province_id] = true

	if combat_manager != null:
		for province_id in provinces_touched:
			combat_manager.handle_province_after_arrivals(province_id)


func _complete_retreat(unit: Unit) -> void:
	var destination_id := unit.data.retreat_destination_id
	unit.data.current_province_id = destination_id
	unit.data.retreat_destination_id = ""
	unit.data.retreat_arrival_date = null
	unit.data.is_retreating = false
	unit.set_retreating(false)
	unit.place_on_province(_provinces_by_id[destination_id])
	_refresh_province_unit_positions(destination_id)
	unit_arrived.emit(unit, destination_id)
	if combat_manager != null:
		combat_manager.on_unit_arrived(unit, true)


func _spawn_starting_units(start_province_id: String, enemy_province_id: String, war: WarState) -> void:
	if not _provinces_by_id.has(start_province_id):
		push_error("Missing start province for unit: %s" % start_province_id)
		return

	var german_army := UnitData.new("GER_1", "Army", "DEU", start_province_id, 100_000, 100)
	_add_unit(german_army)
	_spawn_enemy_army(start_province_id, enemy_province_id, war)


func _spawn_enemy_army(start_province_id: String, enemy_province_id: String, war: WarState) -> void:
	if not enemy_province_id.is_empty() and _provinces_by_id.has(enemy_province_id):
		var enemy_province: Province = _provinces_by_id[enemy_province_id]
		var enemy_id := "%s_1" % enemy_province.country_id
		var enemy_army := UnitData.new(enemy_id, "Army", enemy_province.country_id, enemy_province_id, 80_000, 80)
		_add_unit(enemy_army)
		return

	_spawn_enemy_neighbor_army(start_province_id, war)


func _spawn_enemy_neighbor_army(start_province_id: String, war: WarState) -> void:
	if _adjacency == null:
		return

	for neighbor_id in _adjacency.get_neighbors(start_province_id):
		var province: Province = _provinces_by_id.get(neighbor_id)
		if province == null:
			continue
		if war != null and not war.are_at_war("DEU", province.country_id):
			continue
		var enemy_army := UnitData.new("%s_1" % province.country_id, "Army", province.country_id, neighbor_id, 80_000, 80)
		_add_unit(enemy_army)
		return


func _add_unit(unit_data: UnitData) -> void:
	if not _provinces_by_id.has(unit_data.current_province_id):
		push_error("Unknown province for unit %s: %s" % [unit_data.unit_id, unit_data.current_province_id])
		return

	var unit: Unit = Unit.new()
	unit.setup(unit_data)
	add_child(unit)
	_units.append(unit)
	_units_by_id[unit_data.unit_id] = unit
	unit.update_zoom_scale(_current_zoom)
	_refresh_province_unit_positions(unit_data.current_province_id)


func _refresh_province_unit_positions(province_id: String) -> void:
	var province_units: Array[Unit] = []
	for unit in _units:
		if unit.data.current_province_id == province_id and unit.data.soldiers > 0:
			province_units.append(unit)

	for i in province_units.size():
		province_units[i].place_on_province(_provinces_by_id[province_id], i, province_units.size())
