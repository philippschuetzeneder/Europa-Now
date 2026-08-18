class_name CapitalMarker
extends Node2D

const DOT_RADIUS := 2.8
const DOT_TARGET_SCREEN_PX := 5.0
const DOT_MAX_SCALE := 3.5
const DOT_MIN_ZOOM := 0.52

var capital_name: String

var _dot: Polygon2D


func setup(name: String, map_position: Vector2) -> void:
	capital_name = name
	position = map_position
	z_index = 5

	_dot = _create_dot()
	add_child(_dot)


func update_zoom_scale(zoom_level: float) -> void:
	var show_marker: bool = zoom_level >= DOT_MIN_ZOOM
	visible = show_marker
	if not show_marker:
		return

	var target_px: float = DOT_TARGET_SCREEN_PX
	if zoom_level < 0.7:
		target_px = 4.0

	var dot_scale: float = MapUiScale.screen_scale(
		zoom_level, DOT_RADIUS, target_px, DOT_MAX_SCALE
	)
	scale = Vector2.ONE * dot_scale


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
