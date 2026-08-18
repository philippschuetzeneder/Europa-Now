class_name UnitManager
extends Node2D

signal unit_selected(unit: Unit)
signal unit_move_ordered(unit: Unit, destination_id: String, arrival_date: GameDate)
signal unit_arrived(unit: Unit, province_id: String)

const TRAVEL_DAYS := 3

var _provinces_by_id: Dictionary = {}
var _adjacency: ProvinceAdjacency
var _units: Array[Unit] = []
var _units_by_id: Dictionary = {}
var _selected_unit: Unit


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


func pick_unit_at(world_pos: Vector2) -> Unit:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Unit.COLLISION_LAYER_UNITS

	for hit in space.intersect_point(params, 8):
		var collider = hit.get("collider")
		if collider is Unit and collider.visible:
			return collider
	return null


func _on_day_advanced(date: GameDate) -> void:
	for unit in _units:
		if not unit.data.is_moving:
			continue
		if unit.data.arrival_date == null:
			continue
		if date.is_on_or_after(unit.data.arrival_date):
			_complete_move(unit)


func _complete_move(unit: Unit) -> void:
	var destination_id := unit.data.destination_province_id
	unit.data.current_province_id = destination_id
	unit.data.destination_province_id = ""
	unit.data.arrival_date = null
	unit.set_moving(false)
	unit.place_on_province(_provinces_by_id[destination_id])
	unit_arrived.emit(unit, destination_id)


func _spawn_starting_units(start_province_id: String) -> void:
	if not _provinces_by_id.has(start_province_id):
		push_error("Missing start province for unit: %s" % start_province_id)
		return
	var german_army := UnitData.new("GER_1", "Army", "DEU", start_province_id)
	_add_unit(german_army)


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
