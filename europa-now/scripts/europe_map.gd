class_name EuropeMap
extends Node2D

signal country_selected(country: Country)
signal province_selected(province: Province)
signal province_move_ordered(province: Province)
signal unit_selected(unit: Unit)
signal map_loaded(bounds: Rect2)

@onready var countries_root: Node2D = $Countries
@onready var provinces_root: ProvincesLayer = $Provinces
@onready var capitals_root: CapitalsLayer = $Capitals
@onready var units_root: UnitManager = $Units

var _countries: Array[Country] = []
var _countries_by_id: Dictionary = {}
var _provinces: Array[Province] = []
var _province_adjacency: ProvinceAdjacency
var _selected_country: Country
var _selected_province: Province
var _hovered_province: Province
var _last_mouse_pos := Vector2.INF


func _ready() -> void:
	_build_map()


func _process(_delta: float) -> void:
	var mouse_pos := _get_mouse_world_position()
	if mouse_pos.distance_squared_to(_last_mouse_pos) < 0.25:
		return
	_last_mouse_pos = mouse_pos
	_update_hover(mouse_pos)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		_handle_left_click()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click()


func _handle_left_click() -> void:
	var world_pos := _get_mouse_world_position()
	var unit := units_root.pick_unit_at(world_pos)
	if unit != null:
		units_root.select_unit(unit)
		_clear_selection()
		unit_selected.emit(unit)
		get_viewport().set_input_as_handled()
		return

	var province := _pick_province_at(world_pos)
	if province != null:
		_select_province(province)
		province_selected.emit(province)
		country_selected.emit(_countries_by_id[province.country_id])
		get_viewport().set_input_as_handled()


func _handle_right_click() -> void:
	if units_root.get_selected_unit() == null:
		return

	var world_pos := _get_mouse_world_position()
	var province := _pick_province_at(world_pos)
	if province == null:
		return

	_select_province(province)
	province_move_ordered.emit(province)
	country_selected.emit(_countries_by_id[province.country_id])
	get_viewport().set_input_as_handled()


func get_countries() -> Array[Country]:
	return _countries


func get_country(country_id: String) -> Country:
	return _countries_by_id.get(country_id)


func get_provinces() -> Array[Province]:
	return _provinces


func get_province(province_id: String) -> Province:
	return provinces_root.get_province(province_id)


func get_province_count_for_country(country_id: String) -> int:
	return provinces_root.get_count_for_country(country_id)


func get_unit_manager() -> UnitManager:
	return units_root


func order_selected_unit_move(province_id: String) -> bool:
	var unit := units_root.get_selected_unit()
	if unit == null:
		return false
	return units_root.order_move_to_province(unit, province_id)


func _build_map() -> void:
	var country_data := GeoJsonLoader.load_european_countries()
	var bounds := Rect2()

	for data in country_data:
		var country := Country.new()
		country.setup(data)
		countries_root.add_child(country)
		_countries.append(country)
		_countries_by_id[country.country_id] = country

		for ring in data["rings"]:
			if ring is PackedVector2Array:
				for point in ring:
					if bounds.size == Vector2.ZERO:
						bounds = Rect2(point, Vector2.ZERO)
					else:
						bounds = bounds.expand(point)

	_provinces = provinces_root.build_from_countries(country_data)
	_province_adjacency = ProvinceAdjacency.build(_provinces)
	capitals_root.build_from_countries(_countries)

	var berlin_position := GeoProjection.project(13.405, 52.52)
	var start_province := provinces_root.find_province_near_position("DEU", berlin_position)
	var start_province_id := "DEU_region_01"
	if start_province != null:
		start_province_id = start_province.province_id

	units_root.initialize(_provinces, _province_adjacency, start_province_id)
	map_loaded.emit(bounds)


func _get_mouse_world_position() -> Vector2:
	return get_global_mouse_position()


func _pick_province_at(world_pos: Vector2) -> Province:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Province.COLLISION_LAYER_PROVINCES

	for hit in space.intersect_point(params, 32):
		var collider = hit.get("collider")
		if collider is Province:
			return collider
	return null


func _update_hover(world_pos: Vector2) -> void:
	if units_root.pick_unit_at(world_pos) != null:
		_set_hovered_province(null)
		return

	var found := _pick_province_at(world_pos)
	_set_hovered_province(found)


func _set_hovered_province(province: Province) -> void:
	if _hovered_province == province:
		return

	if _hovered_province != null:
		_hovered_province.set_hovered(false)
	_hovered_province = province
	if _hovered_province != null:
		_hovered_province.set_hovered(true)


func _select_province(province: Province) -> void:
	if _selected_province == province:
		return
	_clear_selection()
	_selected_province = province
	province.set_selected(true)
	_selected_country = _countries_by_id.get(province.country_id)
	if _selected_country != null:
		_selected_country.set_selected(true)


func _clear_selection() -> void:
	if _selected_province != null:
		_selected_province.set_selected(false)
	_selected_province = null
	if _selected_country != null:
		_selected_country.set_selected(false)
	_selected_country = null
