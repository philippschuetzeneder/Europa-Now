extends Node2D

@onready var europe_map: EuropeMap = $EuropeMap
@onready var map_camera: MapCamera = $MapCamera
@onready var country_info_panel: PanelContainer = $UI/LeftPanel/InfoPanel
@onready var debug_log: PanelContainer = $UI/DebugPanel
@onready var unit_manager: UnitManager = $EuropeMap/Units
@onready var capitals_layer: CapitalsLayer = $EuropeMap/Capitals
@onready var diplomacy_panel: DiplomacyPanel = $UI/DiplomacyPanel
@onready var recruitment_panel: RecruitmentPanel = $UI/RecruitmentPanel
@onready var army_panel: ArmyInfoPanel = $UI/ArmyInfoPanel
@onready var foreign_country_panel: ForeignCountryPanel = $UI/ForeignCountryPanel
@onready var game_menu_button: Button = $UI/GameMenuButton
@onready var game_menu: GameMenu = $UI/GameMenuPanel

var _combat_manager: CombatManager
var _economy_manager: EconomyManager
var _diplomacy_manager: DiplomacyManager
const SAVE_PATH := "user://europa_now_save.json"


func _ready() -> void:
	europe_map.map_loaded.connect(_on_map_loaded)
	europe_map.country_selected.connect(_on_country_selected)
	europe_map.province_selected.connect(_on_province_selected)
	europe_map.province_move_ordered.connect(_on_province_move_ordered)
	europe_map.unit_selected.connect(_on_unit_selected)
	europe_map.unit_deselected.connect(_on_unit_deselected)
	europe_map.diplomacy_country_requested.connect(_on_diplomacy_country_requested)
	game_menu_button.pressed.connect(game_menu.toggle)
	game_menu.save_requested.connect(_save_game)
	game_menu.load_requested.connect(_load_game)
	unit_manager.unit_move_ordered.connect(_on_unit_move_ordered)
	unit_manager.unit_arrived.connect(_on_unit_arrived)
	unit_manager.unit_retreat_ordered.connect(_on_unit_retreat_ordered)
	unit_manager.unit_destroyed.connect(_on_unit_destroyed)
	map_camera.zoom_changed.connect(_on_camera_zoom_changed)

	_log(
		"Linksklick: Provinz/Einheit | Linksklick+Ziehen: Karte schieben | Rechtsklick: Armee/Diplomatie | "
		+ "WASD/Pfeile: Karte | Mausrad: Zoom | Mittelklick: Pan"
	)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			diplomacy_panel.close_panel()
			recruitment_panel.visible = false
			army_panel.close_panel()
			foreign_country_panel.close_panel()
			game_menu.visible = false


func _on_map_loaded(_bounds: Rect2) -> void:
	_combat_manager = europe_map.get_combat_manager()
	if _combat_manager != null:
		_combat_manager.combat_started.connect(_on_combat_started)
		_combat_manager.combat_updated.connect(_on_combat_updated)
		_combat_manager.combat_ended.connect(_on_combat_ended)
		_combat_manager.province_captured.connect(_on_province_captured)
	_economy_manager = europe_map.get_economy_manager()
	if _economy_manager != null:
		_economy_manager.economy_updated.connect(_on_economy_updated)
		_economy_manager.recruitment_order_created.connect(_on_recruitment_order_created)
		_economy_manager.recruitment_completed.connect(_on_recruitment_completed)
		_economy_manager.recruitment_rejected.connect(_on_recruitment_rejected)
		country_info_panel.set_economy_manager(_economy_manager)
	_diplomacy_manager = europe_map.get_diplomacy_manager()
	if _diplomacy_manager != null:
		_diplomacy_manager.war_declared.connect(_on_war_declared)
		_diplomacy_manager.peace_signed.connect(_on_peace_signed)
		_diplomacy_manager.treaty_created.connect(_on_treaty_created)
		_diplomacy_manager.treaty_expired.connect(_on_treaty_expired)
		_diplomacy_manager.diplomacy_error.connect(_on_diplomacy_error)
		var diplomacy_countries: Dictionary = {}
		for country in europe_map.get_countries():
			diplomacy_countries[country.country_id] = country
		diplomacy_panel.setup(_diplomacy_manager, diplomacy_countries)

	var countries_by_id: Dictionary = {}
	for country in europe_map.get_countries():
		countries_by_id[country.country_id] = country
	country_info_panel.set_countries_lookup(countries_by_id)
	recruitment_panel.setup(_economy_manager)
	var player_country: Country = europe_map.get_country("DEU")
	if player_country != null:
		country_info_panel.show_country(player_country)

	_log("Karte geladen, passe Kamera an ...")
	call_deferred("_fit_camera")


func _fit_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	map_camera.fit_world_with_focus(GeoProjection.bavaria_focus_position(), viewport_size)
	if not map_camera.has_valid_world_fit():
		await get_tree().process_frame
		viewport_size = get_viewport().get_visible_rect().size
		map_camera.fit_world_with_focus(GeoProjection.bavaria_focus_position(), viewport_size)

	_on_camera_fit_completed(map_camera.get_fit_zoom())
	_show_start_diplomacy()


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
	if country.country_id == "DEU":
		country_info_panel.show_country(country)
	recruitment_panel.visible = false
	army_panel.close_panel()
	foreign_country_panel.close_panel()


func _on_province_selected(province: Province) -> void:
	army_panel.close_panel()
	var country: Country = europe_map.get_country(province.country_id)
	if country != null:
		if province.country_id == "DEU":
			country_info_panel.show_country(country)
			foreign_country_panel.close_panel()
		else:
			foreign_country_panel.show_country(country)
	if province.controller_country_id == "DEU":
		recruitment_panel.show_for_province(province, "DEU")
	else:
		recruitment_panel.visible = false
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
		if province.country_id != "DEU":
			var country: Country = europe_map.get_country(province.country_id)
			if country != null:
				foreign_country_panel.show_country(country)


func _on_unit_move_ordered(unit: Unit, destination_id: String, arrival_date: GameDate) -> void:
	var province: Province = europe_map.get_province(destination_id)
	var province_name: String = destination_id if province == null else province.display_name
	_log(
		"%s unterwegs nach %s. Ankunft: %s."
		% [unit.data.unit_id, province_name, arrival_date.format_long()]
	)


func _on_unit_arrived(unit: Unit, province_id: String) -> void:
	var province: Province = europe_map.get_province(province_id)
	var province_name: String = province_id if province == null else province.display_name
	_log("%s ist in %s angekommen." % [unit.data.unit_id, province_name])
	if province != null:
		var country: Country = europe_map.get_country(province.country_id)
		if country != null:
			if province.country_id == "DEU":
				country_info_panel.show_country(country)
				foreign_country_panel.close_panel()
			else:
				foreign_country_panel.show_country(country)
	_refresh_combat_panel_for_province(province_id)


func _on_unit_retreat_ordered(unit: Unit, destination_id: String, arrival_date: GameDate) -> void:
	var province: Province = europe_map.get_province(destination_id)
	var province_name: String = destination_id if province == null else province.display_name
	_log(
		"%s zieht sich zurueck nach %s. Ankunft: %s."
		% [unit.data.unit_id, province_name, arrival_date.format_long()]
	)


func _on_unit_destroyed(unit: Unit) -> void:
	_log("%s wurde vernichtet." % unit.data.unit_id)


func _on_combat_started(combat: CombatState) -> void:
	var province: Province = europe_map.get_province(combat.province_id)
	var province_name: String = combat.province_id if province == null else province.display_name
	_log("Kampf in %s beginnt." % province_name)
	_refresh_combat_panel_for_province(combat.province_id)


func _on_combat_updated(combat: CombatState) -> void:
	_refresh_combat_panel_for_province(combat.province_id)


func _on_combat_ended(combat: CombatState) -> void:
	var province: Province = europe_map.get_province(combat.province_id)
	var province_name: String = combat.province_id if province == null else province.display_name
	var winner: String = combat.winner_side
	_log("Kampf in %s beendet. Sieger: %s." % [province_name, winner])
	_refresh_combat_panel_for_province(combat.province_id)


func _on_province_captured(province_id: String, new_controller_id: String) -> void:
	var province: Province = europe_map.get_province(province_id)
	var province_name: String = province_id if province == null else province.display_name
	var country: Country = europe_map.get_country(new_controller_id)
	var country_name: String = new_controller_id if country == null else country.display_name
	_log("%s wird von %s kontrolliert." % [province_name, country_name])


func _on_war_declared(source_country_id: String, target_country_id: String) -> void:
	_log("%s hat %s den Krieg erklaert." % [
		_country_name(source_country_id),
		_country_name(target_country_id),
	])


func _on_peace_signed(source_country_id: String, target_country_id: String) -> void:
	_log("%s und %s haben Frieden geschlossen." % [
		_country_name(source_country_id),
		_country_name(target_country_id),
	])


func _on_treaty_created(treaty: DiplomaticTreaty) -> void:
	_log(
		"Vertrag aktiv: %s zwischen %s und %s."
		% [
			treaty.treaty_type,
			_country_name(treaty.country_a),
			_country_name(treaty.country_b),
		]
	)


func _on_treaty_expired(treaty: DiplomaticTreaty) -> void:
	_log(
		"Vertrag abgelaufen: %s zwischen %s und %s."
		% [
			treaty.treaty_type,
			_country_name(treaty.country_a),
			_country_name(treaty.country_b),
		]
	)


func _on_diplomacy_error(message: String) -> void:
	_log(message)


func _country_name(country_id: String) -> String:
	var country: Country = europe_map.get_country(country_id)
	return country.display_name if country != null else country_id


func _on_economy_updated(country_id: String) -> void:
	if country_id == "DEU":
		country_info_panel.refresh_economy(country_id)


func _on_recruitment_order_created(order: RecruitmentOrder) -> void:
	_log(
		"Rekrutierung %s: %s Soldaten in %s. Fertigstellung: %s."
		% [
			order.order_id,
			_format_number(order.soldiers),
			order.province_id,
			order.completion_date.format_long(),
		]
	)
	recruitment_panel.refresh_preview()


func _on_recruitment_completed(order: RecruitmentOrder, unit: Unit) -> void:
	_log(
		"Rekrutierung abgeschlossen: %s in %s (%s)."
		% [unit.data.unit_id, order.province_id, _format_number(order.soldiers)]
	)
	recruitment_panel.refresh_preview()


func _on_recruitment_rejected(reason: String) -> void:
	_log(reason)
	recruitment_panel.show_message(reason)


func _on_unit_selected(unit: Unit) -> void:
	foreign_country_panel.close_panel()
	recruitment_panel.visible = false
	var combat: CombatState = _combat_manager.get_combat_for_unit(unit.data.unit_id) if _combat_manager != null else null
	army_panel.show_unit(unit, combat, unit_manager)
	if combat != null:
		return

	if unit.data.is_moving:
		var destination: Province = europe_map.get_province(unit.data.destination_province_id)
		var destination_name: String = unit.data.destination_province_id
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


func _on_unit_deselected() -> void:
	army_panel.close_panel()
	unit_manager.clear_unit_selection()


func _refresh_combat_panel_for_province(province_id: String) -> void:
	if _combat_manager == null:
		return
	var combat: CombatState = _combat_manager.get_combat_at_province(province_id)
	if combat != null and combat.is_active():
		var selected_unit: Unit = unit_manager.get_selected_unit()
		if selected_unit != null:
			army_panel.show_unit(selected_unit, combat, unit_manager)


func _log(message: String) -> void:
	debug_log.log_message(message)


func _on_diplomacy_country_requested(country_id: String) -> void:
	diplomacy_panel.show_for_country(country_id)


func _save_game() -> void:
	var save_data := {
		"date": {
			"year": GameTime.current_date.year,
			"month": GameTime.current_date.month,
			"day": GameTime.current_date.day,
		},
		"units": unit_manager.get_save_data(),
		"economy": _economy_manager.get_save_data() if _economy_manager != null else {},
		"diplomacy": _diplomacy_manager.get_save_data() if _diplomacy_manager != null else {},
		"combat": _combat_manager.get_save_data() if _combat_manager != null else {},
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_log("Spiel konnte nicht gespeichert werden.")
		return
	file.store_string(JSON.stringify(save_data))
	file.close()
	_log("Spiel gespeichert.")
	game_menu.visible = false


func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_log("Kein Spielstand vorhanden.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_log("Spielstand konnte nicht gelesen werden.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Dictionary:
		_log("Spielstand ist ungueltig.")
		return
	var data: Dictionary = parsed
	var date_data: Dictionary = data.get("date", {})
	GameTime.current_date = GameDate.new(
		int(date_data.get("year", 2022)),
		int(date_data.get("month", 1)),
		int(date_data.get("day", 1))
	)
	unit_manager.load_save_data(data.get("units", {}))
	if _diplomacy_manager != null:
		_diplomacy_manager.load_save_data(data.get("diplomacy", {}))
	if _economy_manager != null:
		_economy_manager.load_save_data(data.get("economy", {}))
	if _combat_manager != null:
		_combat_manager.load_save_data(data.get("combat", {}))
	_log("Spielstand geladen.")
	game_menu.visible = false


func _format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	for i in text.length():
		if i > 0 and (text.length() - i) % 3 == 0:
			result += "."
		result += text[i]
	return result


func _show_start_diplomacy() -> void:
	var war_state: WarState = europe_map.get_war_state()
	if war_state == null:
		return
	var enemies: Array[String] = war_state.get_enemies("DEU")
	if enemies.is_empty():
		_log("Deutschland befindet sich in keinem Krieg.")
		return
	var enemy_names: PackedStringArray = []
	for enemy_id in enemies:
		var country: Country = europe_map.get_country(enemy_id)
		enemy_names.append(country.display_name if country != null else enemy_id)
	_log("Kriegszustand DEU gegen: %s." % ", ".join(enemy_names))
	for unit in unit_manager.get_units():
		var country: Country = europe_map.get_country(unit.data.owner_country_id)
		var country_name: String = unit.data.owner_country_id
		if country != null:
			country_name = country.display_name
		_log(
			"Armee %s (%s) in %s."
			% [unit.data.unit_id, country_name, unit.data.current_province_id]
		)
