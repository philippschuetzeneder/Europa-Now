class_name UnitManager
extends Node2D

signal unit_selected(unit: Unit)
signal unit_move_ordered(unit: Unit, destination_id: String, arrival_date: GameDate)
signal unit_arrived(unit: Unit, province_id: String)
signal unit_retreat_ordered(unit: Unit, destination_id: String, arrival_date: GameDate)
signal unit_destroyed(unit: Unit)

const TRAVEL_DAYS := 3

var combat_manager: CombatManager

var _provinces_by_id: Dictionary = {}
var _adjacency: ProvinceAdjacency
var _units: Array[Unit] = []
var _units_by_id: Dictionary = {}
var _selected_unit: Unit
var _pending_arrivals: Array[Dictionary] = []


func _ready() -> void:
	GameTime.day_advanced.connect(_on_day_advanced)


func initialize(provinces: Array[Province], adjacency: ProvinceAdjacency, start_province_id: String) -> void:
	_provinces_by_id.clear()
	_adjacency = adjacency
	for province in provinces:
		_provinces_by_id[province.province_id] = province

	_spawn_starting_units(start_province_id)


func get_unit(unit_id: String) -> Unit:
	return _units_by_id.get(unit_id)


func get_units() -> Array[Unit]:
	return _units


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
	if _adjacency == null or not _adjacency.are_neighbors(unit.data.current_province_id, province_id):
		return false

	var arrival_date := GameTime.current_date.add_days(CombatRetreat.RETREAT_DAYS)
	unit.data.retreat_destination_id = province_id
	unit.data.retreat_arrival_date = arrival_date
	unit.data.is_retreating = true
	unit.set_retreating(true)
	unit_retreat_ordered.emit(unit, province_id, arrival_date)
	return true


func destroy_unit(unit: Unit) -> void:
	if _selected_unit == unit:
		_selected_unit = null
	_units.erase(unit)
	_units_by_id.erase(unit.data.unit_id)
	unit_destroyed.emit(unit)
	unit.queue_free()


func update_zoom_scale(zoom_level: float) -> void:
	for unit in _units:
		unit.update_zoom_scale(zoom_level)


func pick_unit_at(world_pos: Vector2) -> Unit:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Unit.COLLISION_LAYER_UNITS

	for x_offset in GeoProjection.wrap_offsets():
		params.position = world_pos + Vector2(x_offset, 0.0)
		for hit in space.intersect_point(params, 8):
			var collider = hit.get("collider")
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


func _finalize_arrivals() -> void:
	if _pending_arrivals.is_empty():
		return

	var arrivals := _pending_arrivals.duplicate()
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
	unit_arrived.emit(unit, destination_id)
	if combat_manager != null:
		combat_manager.on_unit_arrived(unit, true)


func _spawn_starting_units(start_province_id: String) -> void:
	if not _provinces_by_id.has(start_province_id):
		push_error("Missing start province for unit: %s" % start_province_id)
		return

	var german_army := UnitData.new("GER_1", "Army", "DEU", start_province_id, 100_000, 100)
	_add_unit(german_army)
	_spawn_enemy_neighbor_army(start_province_id)


func _spawn_enemy_neighbor_army(start_province_id: String) -> void:
	if _adjacency == null:
		return

	for neighbor_id in _adjacency.get_neighbors(start_province_id):
		var province: Province = _provinces_by_id.get(neighbor_id)
		if province == null:
			continue
		if province.country_id == "AUT":
			var austrian_army := UnitData.new("AUT_1", "Army", "AUT", neighbor_id, 80_000, 80)
			_add_unit(austrian_army)
			return
		if province.country_id == "CZE":
			var czech_army := UnitData.new("CZE_1", "Army", "CZE", neighbor_id, 80_000, 80)
			_add_unit(czech_army)
			return


func _add_unit(unit_data: UnitData) -> void:
	if not _provinces_by_id.has(unit_data.current_province_id):
		push_error("Unknown province for unit %s: %s" % [unit_data.unit_id, unit_data.current_province_id])
		return

	var unit := Unit.new()
	unit.setup(unit_data)
	unit.place_on_province(_provinces_by_id[unit_data.current_province_id])
	add_child(unit)
	_units.append(unit)
	_units_by_id[unit_data.unit_id] = unit
