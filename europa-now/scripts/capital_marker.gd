class_name CapitalMarker
extends Node2D

const DOT_RADIUS := 4.0
const MIN_DOT_ZOOM := 0.22
const MIN_LABEL_ZOOM := 0.42

var capital_name: String

var _dot: Polygon2D
var _label: Label


func setup(name: String, map_position: Vector2) -> void:
	capital_name = name
	position = map_position
	z_index = 5

	_dot = _create_dot()
	add_child(_dot)

	_label = Label.new()
	_label.text = name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-48, 6)
	_label.custom_minimum_size = Vector2(96, 0)
	_label.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.95))
	_label.add_theme_constant_override("outline_size", 3)
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)


func update_zoom_visibility(zoom_level: float) -> void:
	_dot.visible = zoom_level >= MIN_DOT_ZOOM
	_label.visible = zoom_level >= MIN_LABEL_ZOOM


func _create_dot() -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = _build_circle_points(DOT_RADIUS)
	polygon.color = Color(0.98, 0.92, 0.35, 1.0)
	return polygon


func _build_circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(16)
	for i in 16:
		var angle := (float(i) / 16.0) * TAU
		points[i] = Vector2(cos(angle), sin(angle)) * radius
	return points
