extends Node2D

signal country_selected(country: Country)
signal unit_selected(unit: Unit)
signal map_loaded(bounds: Rect2)

@onready var countries_root: Node2D = $Countries
@onready var units_root: UnitManager = $Units

var _countries: Array[Country] = []
var _countries_by_id: Dictionary = {}
var _selected_country: Country
var _hovered_country: Country
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
	if not (event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var world_pos := _get_mouse_world_position()
	var unit := units_root.pick_unit_at(world_pos)
	if unit != null:
		units_root.select_unit(unit)
		_clear_country_selection()
		unit_selected.emit(unit)
		get_viewport().set_input_as_handled()
		return

	var country := _pick_country_at(world_pos)
	if country != null:
		_select_country(country)
		units_root.clear_unit_selection()
		country_selected.emit(country)
		get_viewport().set_input_as_handled()


func get_countries() -> Array[Country]:
	return _countries


func get_country(country_id: String) -> Country:
	return _countries_by_id.get(country_id)


func get_unit_manager() -> UnitManager:
	return units_root


func move_selected_unit_to_country(country_id: String) -> bool:
	var unit := units_root.get_selected_unit()
	if unit == null:
		return false
	return units_root.move_unit_to_country(unit, country_id)


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

	units_root.initialize(_countries)
	map_loaded.emit(bounds)


func _get_mouse_world_position() -> Vector2:
	return get_global_mouse_position()


func _pick_country_at(world_pos: Vector2) -> Country:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Country.COLLISION_LAYER_COUNTRIES

	for hit in space.intersect_point(params, 32):
		var collider = hit.get("collider")
		if collider is Country:
			return collider
	return null


func _update_hover(world_pos: Vector2) -> void:
	if units_root.pick_unit_at(world_pos) != null:
		_set_hovered_country(null)
		return

	var found := _pick_country_at(world_pos)
	_set_hovered_country(found)


func _set_hovered_country(country: Country) -> void:
	if _hovered_country == country:
		return

	if _hovered_country != null:
		_hovered_country.set_hovered(false)
	_hovered_country = country
	if _hovered_country != null:
		_hovered_country.set_hovered(true)


func _select_country(country: Country) -> void:
	if _selected_country == country:
		return
	_clear_country_selection()
	_selected_country = country
	country.set_selected(true)


func _clear_country_selection() -> void:
	if _selected_country != null:
		_selected_country.set_selected(false)
	_selected_country = null
