class_name ProvinceLabelsLayer
extends Node2D

const MIN_LABEL_ZOOM := 0.95
const MAX_LABEL_ZOOM := 8.0

var _labels: Array[Label] = []
var _anchors: Array[Vector2] = []


func build_from_provinces(provinces: Array[Province]) -> void:
	for child in get_children():
		child.queue_free()
	_labels.clear()
	_anchors.clear()

	for province in provinces:
		if province.center == Vector2.ZERO:
			continue
		var label := Label.new()
		label.text = province.display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(120, 16)
		label.position = province.center + Vector2(-60, -8)
		label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 0.92))
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.10, 0.9))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_font_size_override("font_size", 10)
		label.visible = false
		add_child(label)
		_labels.append(label)
		_anchors.append(province.center)


func update_zoom(zoom_level: float) -> void:
	var show: bool = zoom_level >= MIN_LABEL_ZOOM and zoom_level <= MAX_LABEL_ZOOM
	var text_scale: float = clampf(0.85 / zoom_level, 0.55, 1.4)
	for i in _labels.size():
		var label: Label = _labels[i]
		label.visible = show
		if show:
			label.scale = Vector2.ONE * text_scale
			label.position = _anchors[i] + Vector2(-60 * text_scale, -8 * text_scale)
