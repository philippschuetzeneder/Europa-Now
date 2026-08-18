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

var _polar_root: PolarRegionsLayer

var _countries: Array[Country] = []
var _countries_by_id: Dictionary = {}
var _provinces: Array[Province] = []
var _province_adjacency: ProvinceAdjacency
var _country_adjacency: CountryAdjacency
var _validation_report: MapValidationReport
var _selected_country: Country
var _selected_province: Province
var _hovered_province: Province
var _last_mouse_pos := Vector2.INF
var _map_camera: MapCamera
var _combat_manager: CombatManager
var _war_state: WarState


func _ready() -> void:
	_map_camera = get_parent().get_node("MapCamera") as MapCamera
	_build_map()


func _process(_delta: float) -> void:
	var mouse_pos := _get_mouse_world_position()
	if mouse_pos.distance_squared_to(_last_mouse_pos) < 0.25:
		return
	_last_mouse_pos = mouse_pos
	_update_hover(mouse_pos)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if _map_camera != null and not _map_camera.did_left_drag():
				_handle_left_click()
			if _map_camera != null:
				_map_camera.reset_left_drag_state()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click()


func _handle_left_click() -> void:
	var world_pos := _get_mouse_world_position()
	var unit: Unit = units_root.pick_unit_at(world_pos)
	if unit != null:
		units_root.select_unit(unit)
		_clear_selection()
		unit_selected.emit(unit)
		get_viewport().set_input_as_handled()
		return

	var province: Province = _pick_province_at(world_pos)
	if province != null:
		_select_province(province)
		province_selected.emit(province)
		get_viewport().set_input_as_handled()


func _handle_right_click() -> void:
	if units_root.get_selected_unit() == null:
		return

	var world_pos := _get_mouse_world_position()
	var province: Province = _pick_province_at(world_pos)
	if province == null:
		return

	_select_province(province)
	province_move_ordered.emit(province)
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


func get_combat_manager() -> CombatManager:
	return _combat_manager


func get_war_state() -> WarState:
	return _war_state


func order_selected_unit_move(province_id: String) -> bool:
	var unit := units_root.get_selected_unit()
	if unit == null:
		return false
	return units_root.order_move_to_province(unit, province_id)


func get_country_adjacency() -> CountryAdjacency:
	return _country_adjacency


func get_validation_report() -> MapValidationReport:
	return _validation_report


func _build_map() -> void:
	_polar_root = PolarRegionsLayer.new()
	_polar_root.name = "PolarRegions"
	_polar_root.z_index = -2
	add_child(_polar_root)
	move_child(_polar_root, 0)

	var polar_data: Array[Dictionary] = GeoJsonLoader.load_polar_regions()
	_polar_root.build_from_data(polar_data)

	var country_data: Array[Dictionary] = GeoJsonLoader.load_world_countries()
	var bounds := Rect2()

	for data in polar_data:
		for ring in data.get("rings", []):
			if ring is PackedVector2Array:
				for point in ring:
					if bounds.size == Vector2.ZERO:
						bounds = Rect2(point, Vector2.ZERO)
					else:
						bounds = bounds.expand(point)

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
	_country_adjacency = CountryAdjacency.build(_countries)
	for country in _countries:
		country.neighbor_country_ids = _country_adjacency.get_neighbors(country.country_id)
	_validation_report = MapValidator.validate(_countries, _provinces, _province_adjacency)
	capitals_root.build_from_countries(_countries)

	var start_province_id := "DEU_bb"
	if provinces_root.get_province(start_province_id) == null:
		var berlin_position := GeoProjection.project(13.405, 52.52)
		var start_province: Province = provinces_root.find_province_near_position("DEU", berlin_position)
		if start_province != null:
			start_province_id = start_province.province_id

	units_root.initialize(_provinces, _province_adjacency, start_province_id)

	_war_state = WarState.new()
	_war_state.set_war("DEU", "AUT", true)
	_war_state.set_war("DEU", "CZE", true)

	_combat_manager = CombatManager.new()
	_combat_manager.name = "Combat"
	add_child(_combat_manager)
	_combat_manager.initialize(units_root, _provinces, _province_adjacency, _war_state)
	units_root.combat_manager = _combat_manager

	_create_horizon_wrap_visuals()
	call_deferred("_emit_map_loaded", bounds)


func _emit_map_loaded(bounds: Rect2) -> void:
	map_loaded.emit(bounds)


func _create_horizon_wrap_visuals() -> void:
	var width: float = GeoProjection.world_width()
	for source in [_polar_root, countries_root]:
		for offset in [-width, width]:
			var copy: Node2D = source.duplicate() as Node2D
			if copy == null:
				continue
			copy.position.x = offset
			copy.set_meta("wrap_copy", true)
			add_child(copy)


func _get_mouse_world_position() -> Vector2:
	return get_global_mouse_position()


func _pick_province_at(world_pos: Vector2) -> Province:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Province.COLLISION_LAYER_PROVINCES

	for x_offset in GeoProjection.wrap_offsets():
		params.position = world_pos + Vector2(x_offset, 0.0)
		for hit in space.intersect_point(params, 32):
			var collider = hit.get("collider")
			if collider is Province:
				return collider
	return null


func _update_hover(world_pos: Vector2) -> void:
	if units_root.pick_unit_at(world_pos) != null:
		_set_hovered_province(null)
		return

	var found: Province = _pick_province_at(world_pos)
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
