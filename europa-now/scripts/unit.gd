class_name Unit
extends Area2D

signal selected(unit: Unit)

const MARKER_RADIUS := 14.0
const COLLISION_LAYER_UNITS := 2

var data: UnitData

var _fill: Polygon2D
var _selection_ring: Line2D
var _type_label: Label
var _is_selected := false


func setup(unit_data: UnitData) -> void:
	data = unit_data
	collision_layer = COLLISION_LAYER_UNITS
	collision_mask = 0
	input_pickable = false
	z_index = 10

	_fill = _create_circle_polygon(MARKER_RADIUS, Color(0.82, 0.16, 0.16))
	add_child(_fill)

	_selection_ring = _create_circle_line(MARKER_RADIUS + 5.0, Color(1.0, 0.92, 0.35), 3.0)
	_selection_ring.visible = false
	add_child(_selection_ring)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = MARKER_RADIUS + 6.0
	collision.shape = shape
	add_child(collision)

	_type_label = Label.new()
	_type_label.text = "A"
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_label.position = Vector2(-7, -10)
	_type_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_type_label.add_theme_font_size_override("font_size", 14)
	add_child(_type_label)


func set_selected(value: bool) -> void:
	_is_selected = value
	_selection_ring.visible = value and visible
	_apply_fill_color()


func set_moving(value: bool) -> void:
	data.is_moving = value
	visible = not value
	if value:
		_selection_ring.visible = false
	else:
		_apply_fill_color()


func is_moving() -> bool:
	return data.is_moving


func place_on_province(province: Province) -> void:
	global_position = province.get_placement_position()


func _apply_fill_color() -> void:
	if not is_instance_valid(_fill):
		return
	_fill.color = Color(0.95, 0.28, 0.22) if _is_selected else Color(0.82, 0.16, 0.16)


func _create_circle_polygon(radius: float, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = _build_circle_points(radius)
	polygon.color = color
	return polygon


func _create_circle_line(radius: float, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.points = _build_circle_points(radius)
	line.closed = true
	line.default_color = color
	line.width = width
	line.antialiased = true
	return line


func _build_circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(24)
	for i in 24:
		var angle := (float(i) / 24.0) * TAU
		points[i] = Vector2(cos(angle), sin(angle)) * radius
	return points
