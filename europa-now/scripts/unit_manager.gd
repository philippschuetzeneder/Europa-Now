class_name UnitManager
extends Node2D

signal unit_selected(unit: Unit)

const COLLISION_LAYER_COUNTRIES := 1

var _countries_by_id: Dictionary = {}
var _units: Array[Unit] = []
var _units_by_id: Dictionary = {}
var _selected_unit: Unit


func initialize(countries: Array[Country]) -> void:
	_countries_by_id.clear()
	for country in countries:
		_countries_by_id[country.country_id] = country

	_spawn_starting_units()


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


func move_unit_to_country(unit: Unit, country_id: String) -> bool:
	if not _countries_by_id.has(country_id):
		return false

	unit.data.current_country_id = country_id
	unit.place_on_country(_countries_by_id[country_id])
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
		if collider is Unit:
			return collider
	return null


func _spawn_starting_units() -> void:
	var german_army := UnitData.new("GER_1", "Army", "DEU", "DEU")
	_add_unit(german_army)


func _add_unit(unit_data: UnitData) -> void:
	if not _countries_by_id.has(unit_data.current_country_id):
		push_error("Unknown country for unit %s: %s" % [unit_data.unit_id, unit_data.current_country_id])
		return

	var unit := Unit.new()
	unit.setup(unit_data)
	unit.place_on_country(_countries_by_id[unit_data.current_country_id])
	add_child(unit)
	_units.append(unit)
	_units_by_id[unit_data.unit_id] = unit
