class_name CapitalsLayer
extends Node2D

const LABEL_FONT_SIZE := 12
const LABEL_SCREEN_OFFSET := Vector2(0.0, 10.0)
const LABEL_WIDTH := 96.0
## Hide labels when zoom falls below start_zoom * this factor (zooming out).
const LABEL_ZOOM_OUT_FACTOR := 0.97

var _markers: Array[CapitalMarker] = []
var _labels: Array[Label] = []
var _label_layer: CanvasLayer
var _current_zoom := 0.0
var _label_show_min_zoom := 0.55


func _ready() -> void:
	_label_layer = CanvasLayer.new()
	_label_layer.layer = 12
	add_child(_label_layer)


func configure_for_fit_zoom(fit_zoom: float, start_zoom: float = 0.0) -> void:
	if fit_zoom <= 0.0:
		return
	if start_zoom <= fit_zoom:
		start_zoom = fit_zoom * 2.0
	_label_show_min_zoom = start_zoom * LABEL_ZOOM_OUT_FACTOR
	update_zoom_scale(_current_zoom if _current_zoom > 0.0 else start_zoom)


func _process(_delta: float) -> void:
	if _labels.is_empty():
		return
	if _current_zoom < _label_show_min_zoom:
		return
	_update_label_positions()


func build_from_countries(countries: Array[Country]) -> void:
	for child in get_children():
		if child != _label_layer:
			child.queue_free()
	for label in _labels:
		label.queue_free()
	_markers.clear()
	_labels.clear()

	for country in countries:
		if country.capital_name.is_empty() or country.capital_name == "k. A.":
			continue
		var marker := CapitalMarker.new()
		marker.setup(country.capital_name, country.capital_position)
		add_child(marker)
		_markers.append(marker)

		var label := Label.new()
		label.text = country.capital_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
		label.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.95))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
		label.visible = false
		_label_layer.add_child(label)
		_labels.append(label)


func update_zoom_scale(zoom_level: float) -> void:
	_current_zoom = zoom_level
	var show_labels: bool = zoom_level >= _label_show_min_zoom

	for i in _markers.size():
		var marker: CapitalMarker = _markers[i]
		marker.update_zoom_scale(zoom_level)

		var label: Label = _labels[i]
		label.visible = show_labels

	if show_labels:
		_update_label_positions()


func _update_label_positions() -> void:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	for i in _markers.size():
		var marker: CapitalMarker = _markers[i]
		var label: Label = _labels[i]
		if not label.visible:
			continue
		var screen_pos: Vector2 = canvas_transform * marker.global_position
		label.position = screen_pos + LABEL_SCREEN_OFFSET + Vector2(-LABEL_WIDTH * 0.5, 0.0)


func update_zoom_visibility(zoom_level: float) -> void:
	update_zoom_scale(zoom_level)
