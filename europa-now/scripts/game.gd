extends Node2D

@onready var europe_map: EuropeMap = $EuropeMap
@onready var map_camera: MapCamera = $MapCamera
@onready var country_info_panel: PanelContainer = $UI/LeftPanel/InfoPanel
@onready var debug_log: PanelContainer = $UI/DebugPanel
@onready var unit_manager: UnitManager = $EuropeMap/Units
@onready var capitals_layer: CapitalsLayer = $EuropeMap/Capitals

var _combat_manager: CombatManager


func _ready() -> void:
	europe_map.map_loaded.connect(_on_map_loaded)
	europe_map.country_selected.connect(_on_country_selected)
	europe_map.province_selected.connect(_on_province_selected)
	europe_map.province_move_ordered.connect(_on_province_move_ordered)
	europe_map.unit_selected.connect(_on_unit_selected)
	unit_manager.unit_move_ordered.connect(_on_unit_move_ordered)
	unit_manager.unit_arrived.connect(_on_unit_arrived)
	unit_manager.unit_retreat_ordered.connect(_on_unit_retreat_ordered)
	unit_manager.unit_destroyed.connect(_on_unit_destroyed)
	map_camera.zoom_changed.connect(_on_camera_zoom_changed)

	_log(
		"Linksklick: Provinz/Einheit | Linksklick+Ziehen: Karte schieben | Rechtsklick: Armee | "
		+ "WASD/Pfeile: Karte | Mausrad: Zoom | Mittelklick: Pan"
	)


func _on_map_loaded(_bounds: Rect2) -> void:
	_combat_manager = europe_map.get_combat_manager()
	if _combat_manager != null:
		_combat_manager.combat_started.connect(_on_combat_started)
		_combat_manager.combat_updated.connect(_on_combat_updated)
		_combat_manager.combat_ended.connect(_on_combat_ended)
		_combat_manager.province_captured.connect(_on_province_captured)

	var countries_by_id: Dictionary = {}
	for country in europe_map.get_countries():
		countries_by_id[country.country_id] = country
	country_info_panel.set_countries_lookup(countries_by_id)

	_log("Karte geladen, passe Kamera an ...")
	call_deferred("_fit_camera")


func _fit_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	map_camera.fit_to_bounds(GeoProjection.europe_bavaria_view_bounds(), viewport_size)
	if not map_camera.has_valid_world_fit():
		await get_tree().process_frame
		viewport_size = get_viewport().get_visible_rect().size
		map_camera.fit_to_bounds(GeoProjection.europe_bavaria_view_bounds(), viewport_size)

	_on_camera_fit_completed(map_camera.get_fit_zoom())


func _on_camera_fit_completed(fit_zoom: float) -> void:
	capitals_layer.configure_for_fit_zoom(fit_zoom, map_camera.get_start_zoom())
	_on_camera_zoom_changed(map_camera.zoom.x)

	var countries: Array[Country] = europe_map.get_countries()
	var provinces: Array[Province] = europe_map.get_provinces()
	var aut_count: int = europe_map.get_province_count_for_country("AUT")
	var deu_count: int = europe_map.get_province_count_for_country("DEU")
	var rus_count: int = europe_map.get_province_count_for_country("RUS")
	var bel_count: int = europe_map.get_province_count_for_country("BEL")
	var nld_count: int = europe_map.get_province_count_for_country("NLD")
	var dnk_count: int = europe_map.get_province_count_for_country("DNK")

	_log(
		"Weltkarte geladen: %d Laender, %d Provinzen. AUT=%d, DEU=%d, BEL=%d, NLD=%d, DNK=%d, RUS=%d. Zoom=%.3f (min=%.3f, fit=%.3f)."
		% [
			countries.size(), provinces.size(), aut_count, deu_count, bel_count, nld_count, dnk_count, rus_count,
			map_camera.zoom.x, map_camera.get_min_zoom_limit(), fit_zoom,
		]
	)

	var report: MapValidationReport = europe_map.get_validation_report()
	if report != null:
		_log(MapValidator.format_report(report))


func _on_camera_zoom_changed(zoom_level: float) -> void:
	capitals_layer.update_zoom_scale(zoom_level)
	unit_manager.update_zoom_scale(zoom_level)


func _on_country_selected(country: Country) -> void:
	country_info_panel.show_country(country)


func _on_province_selected(province: Province) -> void:
	var country: Country = europe_map.get_country(province.country_id)
	if country != null:
		country_info_panel.show_country(country, true)
	country_info_panel.show_province(province)
	_refresh_combat_panel_for_province(province.province_id)


func _on_province_move_ordered(province: Province) -> void:
	var unit: Unit = unit_manager.get_selected_unit()
	if unit == null:
		return

	var reason: String = unit_manager.get_move_block_reason(unit, province.province_id)
	if not reason.is_empty():
		_log(reason)
		return

	if europe_map.order_selected_unit_move(province.province_id):
		var country: Country = europe_map.get_country(province.country_id)
		if country != null:
			country_info_panel.show_country(country, true)
		country_info_panel.show_province(province)


func _on_unit_move_ordered(unit: Unit, destination_id: String, arrival_date: GameDate) -> void:
	var province: Province = europe_map.get_province(destination_id)
	var province_name := destination_id if province == null else province.display_name
	_log(
		"%s unterwegs nach %s. Ankunft: %s."
		% [unit.data.unit_id, province_name, arrival_date.format_long()]
	)


func _on_unit_arrived(unit: Unit, province_id: String) -> void:
	var province: Province = europe_map.get_province(province_id)
	var province_name := province_id if province == null else province.display_name
	_log("%s ist in %s angekommen." % [unit.data.unit_id, province_name])
	if province != null:
		var country: Country = europe_map.get_country(province.country_id)
		if country != null:
			country_info_panel.show_country(country, true)
		country_info_panel.show_province(province)
	_refresh_combat_panel_for_province(province_id)


func _on_unit_retreat_ordered(unit: Unit, destination_id: String, arrival_date: GameDate) -> void:
	var province: Province = europe_map.get_province(destination_id)
	var province_name := destination_id if province == null else province.display_name
	_log(
		"%s zieht sich zurueck nach %s. Ankunft: %s."
		% [unit.data.unit_id, province_name, arrival_date.format_long()]
	)


func _on_unit_destroyed(unit: Unit) -> void:
	_log("%s wurde vernichtet." % unit.data.unit_id)


func _on_combat_started(combat: CombatState) -> void:
	var province: Province = europe_map.get_province(combat.province_id)
	var province_name := combat.province_id if province == null else province.display_name
	_log("Kampf in %s beginnt." % province_name)
	_refresh_combat_panel_for_province(combat.province_id)


func _on_combat_updated(combat: CombatState) -> void:
	_refresh_combat_panel_for_province(combat.province_id)


func _on_combat_ended(combat: CombatState) -> void:
	var province: Province = europe_map.get_province(combat.province_id)
	var province_name := combat.province_id if province == null else province.display_name
	var winner := combat.winner_side
	_log("Kampf in %s beendet. Sieger: %s." % [province_name, winner])
	_refresh_combat_panel_for_province(combat.province_id)


func _on_province_captured(province_id: String, new_controller_id: String) -> void:
	var province: Province = europe_map.get_province(province_id)
	var province_name := province_id if province == null else province.display_name
	var country: Country = europe_map.get_country(new_controller_id)
	var country_name := new_controller_id if country == null else country.display_name
	_log("%s wird von %s kontrolliert." % [province_name, country_name])


func _on_unit_selected(unit: Unit) -> void:
	country_info_panel.show_unit(unit)
	var combat := _combat_manager.get_combat_for_unit(unit.data.unit_id) if _combat_manager != null else null
	if combat != null:
		country_info_panel.show_combat(combat, unit_manager)
		return

	if unit.data.is_moving:
		var destination: Province = europe_map.get_province(unit.data.destination_province_id)
		var destination_name := unit.data.destination_province_id
		if destination != null:
			destination_name = destination.display_name
		_log(
			"%s (%s) unterwegs nach %s. Ankunft: %s."
			% [
				unit.data.unit_id,
				unit.data.unit_type,
				destination_name,
				unit.data.arrival_date.format_long(),
			]
		)
	else:
		_log("Einheit %s (%s) ausgewaehlt - Nachbarprovinz mit Rechtsklick waehlen." % [
			unit.data.unit_id,
			unit.data.unit_type,
		])


func _refresh_combat_panel_for_province(province_id: String) -> void:
	if _combat_manager == null:
		return
	var combat := _combat_manager.get_combat_at_province(province_id)
	if combat != null and combat.is_active():
		country_info_panel.show_combat(combat, unit_manager)
	else:
		country_info_panel.hide_combat()


func _log(message: String) -> void:
	debug_log.log_message(message)
