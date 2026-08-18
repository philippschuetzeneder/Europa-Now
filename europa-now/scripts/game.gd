extends Node2D

@onready var europe_map: Node2D = $EuropeMap
@onready var map_camera: Camera2D = $MapCamera
@onready var country_info_panel: PanelContainer = $UI/LeftPanel/InfoPanel
@onready var hint_label: Label = $UI/HintLabel


func _ready() -> void:
	europe_map.map_loaded.connect(_on_map_loaded)
	europe_map.country_selected.connect(_on_country_selected)
	europe_map.unit_selected.connect(_on_unit_selected)
	hint_label.text = (
		"Linksklick: Land/Einheit waehlen | Mausrad: Zoom | "
		+ "Rechts/Mittel: Verschieben | Einheit + Land: Bewegen"
	)


func _on_map_loaded(_bounds: Rect2) -> void:
	map_camera.fit_to_bounds(GeoProjection.europe_view_bounds(), get_viewport().get_visible_rect().size)


func _on_country_selected(country: Country) -> void:
	if europe_map.move_selected_unit_to_country(country.country_id):
		hint_label.text = "Armee bewegt nach %s." % country.display_name
	country_info_panel.show_country(country)


func _on_unit_selected(unit: Unit) -> void:
	hint_label.text = "Einheit %s (%s) ausgewaehlt - Zielland anklicken." % [
		unit.data.unit_id,
		unit.data.unit_type,
	]
