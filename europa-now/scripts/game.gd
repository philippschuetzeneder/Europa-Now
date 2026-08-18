extends Node2D

@onready var europe_map: EuropeMap = $EuropeMap
@onready var map_camera: MapCamera = $MapCamera
@onready var country_info_panel: PanelContainer = $UI/LeftPanel/InfoPanel
@onready var debug_log: PanelContainer = $UI/DebugPanel
@onready var unit_manager: UnitManager = $EuropeMap/Units
@onready var capitals_layer: CapitalsLayer = $EuropeMap/Capitals


func _ready() -> void:
	europe_map.map_loaded.connect(_on_map_loaded)
	europe_map.country_selected.connect(_on_country_selected)
	europe_map.province_selected.connect(_on_province_selected)
	europe_map.province_move_ordered.connect(_on_province_move_ordered)
	europe_map.unit_selected.connect(_on_unit_selected)
	unit_manager.unit_move_ordered.connect(_on_unit_move_ordered)
	unit_manager.unit_arrived.connect(_on_unit_arrived)
	map_camera.zoom_changed.connect(_on_camera_zoom_changed)

	_log(
		"Linksklick: Provinz/Einheit | Rechtsklick: Armee (Nachbarprovinzen) | "
		+ "WASD/Pfeile: Karte | Zeit oben | Mausrad: Zoom | Mittelklick: Pan"
	)


func _on_map_loaded(_bounds: Rect2) -> void:
	map_camera.fit_to_bounds(GeoProjection.europe_view_bounds(), get_viewport().get_visible_rect().size)
	capitals_layer.update_zoom_visibility(map_camera.zoom.x)
	var aut_count := europe_map.get_province_count_for_country("AUT")
	var deu_count := europe_map.get_province_count_for_country("DEU")
	_log("Provinzkarte geladen. Oesterreich: %d Provinzen, Deutschland: %d Provinzen." % [aut_count, deu_count])


func _on_camera_zoom_changed(zoom_level: float) -> void:
	capitals_layer.update_zoom_visibility(zoom_level)


func _on_country_selected(country: Country) -> void:
	country_info_panel.show_country(country)


func _on_province_selected(province: Province) -> void:
	var country: Country = europe_map.get_country(province.country_id)
	if country != null:
		country_info_panel.show_country(country)
	country_info_panel.show_province(province)


func _on_province_move_ordered(province: Province) -> void:
	var unit := unit_manager.get_selected_unit()
	if unit == null:
		return

	var reason := unit_manager.get_move_block_reason(unit, province.province_id)
	if not reason.is_empty():
		_log(reason)
		return

	if europe_map.order_selected_unit_move(province.province_id):
		var country: Country = europe_map.get_country(province.country_id)
		if country != null:
			country_info_panel.show_country(country)
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
			country_info_panel.show_country(country)
		country_info_panel.show_province(province)


func _on_unit_selected(unit: Unit) -> void:
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


func _log(message: String) -> void:
	debug_log.log_message(message)
