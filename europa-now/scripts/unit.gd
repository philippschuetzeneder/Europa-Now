class_name Unit
extends Area2D

signal selected(unit: Unit)

const MARKER_RADIUS := 5.0
const TARGET_SCREEN_RADIUS_PX := 12.0
const COLLISION_LAYER_UNITS := 2

var data: UnitData

var _fill: Polygon2D
var _selection_ring: Line2D
var _type_label: Label
var _collision: CollisionShape2D
var _is_selected := false
var _is_in_combat := false


func setup(unit_data: UnitData) -> void:
	data = unit_data
	collision_layer = COLLISION_LAYER_UNITS
	collision_mask = 0
	input_pickable = false
	z_index = 10

	_fill = _create_circle_polygon(MARKER_RADIUS, Color(0.82, 0.16, 0.16))
	add_child(_fill)

	_selection_ring = _create_circle_line(MARKER_RADIUS + 1.5, Color(1.0, 0.92, 0.35), 1.2)
	_selection_ring.visible = false
	add_child(_selection_ring)

	_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = MARKER_RADIUS + 2.0
	_collision.shape = shape
	add_child(_collision)

	_type_label = Label.new()
	_type_label.text = unit_data.owner_country_id.substr(0, 1)
	_apply_country_style()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_label.position = Vector2(-4, -6)
	_type_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_type_label.add_theme_font_size_override("font_size", 11)
	add_child(_type_label)


func update_zoom_scale(zoom_level: float) -> void:
	var ui_scale: float = MapUiScale.screen_scale(zoom_level, MARKER_RADIUS, TARGET_SCREEN_RADIUS_PX)
	scale = Vector2.ONE * ui_scale


func set_selected(value: bool) -> void:
	_is_selected = value
	_selection_ring.visible = value and visible
	_apply_fill_color()


func set_moving(value: bool) -> void:
	data.is_moving = value
	if value and not data.is_retreating:
		visible = false
		_selection_ring.visible = false
	else:
		visible = true
		_apply_fill_color()
		if _is_selected:
			_selection_ring.visible = true


func set_in_combat(value: bool) -> void:
	_is_in_combat = value
	visible = true
	_apply_fill_color()


func cancel_movement() -> void:
	data.is_moving = false
	data.destination_province_id = ""
	data.arrival_date = null
	visible = true
	_apply_fill_color()


func set_retreating(value: bool) -> void:
	data.is_retreating = value
	visible = true
	_apply_fill_color()


func is_moving() -> bool:
	return data.is_moving


func place_on_province(province: Province, slot_index: int = 0, slot_count: int = 1) -> void:
	var base_position := province.get_placement_position()
	if slot_count <= 1:
		global_position = base_position
		return
	var spacing := 10.0
	var offset_x := (float(slot_index) - (float(slot_count) - 1.0) * 0.5) * spacing
	global_position = base_position + Vector2(offset_x, 0.0)


func _apply_fill_color() -> void:
	if not is_instance_valid(_fill):
		return
	var base_color := _get_country_color()
	if _is_in_combat:
		_fill.color = base_color.lightened(0.25) if _is_selected else base_color.lightened(0.12)
	elif data.is_retreating:
		_fill.color = base_color.darkened(0.15) if _is_selected else base_color.darkened(0.28)
	else:
		_fill.color = base_color.lightened(0.18) if _is_selected else base_color


func _apply_country_style() -> void:
	_apply_fill_color()


func _get_country_color() -> Color:
	match data.owner_country_id:
		"DEU":
			return Color(0.12, 0.22, 0.62)
		"AUT":
			return Color(0.82, 0.16, 0.16)
		"CZE":
			return Color(0.16, 0.58, 0.24)
		"POL":
			return Color(0.78, 0.18, 0.22)
		"FRA":
			return Color(0.18, 0.32, 0.72)
		_:
			var hash_value: int = absi(data.owner_country_id.hash())
			return Color(
				0.35 + float(hash_value % 100) / 200.0,
				0.35 + float((hash_value / 100) % 100) / 200.0,
				0.35 + float((hash_value / 10000) % 100) / 200.0
			)


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
