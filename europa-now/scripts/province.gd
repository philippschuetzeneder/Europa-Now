class_name Province
extends Area2D

const COLLISION_LAYER_PROVINCES := 4

var province_id: String
var display_name: String
var country_id: String
var owner_country_id: String
var center: Vector2
var primary_city: String

var _base_color: Color
var _polygon_nodes: Array[Polygon2D] = []
var _is_selected := false
var _is_hovered := false


func setup(data: Dictionary) -> void:
	province_id = data["id"]
	display_name = data["name"]
	country_id = data["country_id"]
	owner_country_id = data.get("owner_country_id", country_id)
	center = data.get("center", Vector2.ZERO)
	primary_city = data.get("primary_city", "")

	var color: Color = data["color"]
	_base_color = color

	for ring in data["rings"]:
		if ring is not PackedVector2Array or ring.size() < 3:
			continue

		var fill := Polygon2D.new()
		fill.polygon = ring
		fill.color = color
		add_child(fill)
		_polygon_nodes.append(fill)

		var border := Line2D.new()
		border.points = ring
		border.closed = true
		border.default_color = Color(0.08, 0.10, 0.14, 0.85)
		border.width = 1.0
		border.antialiased = true
		add_child(border)

		var collision := CollisionPolygon2D.new()
		collision.polygon = ring
		add_child(collision)

	collision_layer = COLLISION_LAYER_PROVINCES
	collision_mask = 0
	input_pickable = false


func get_placement_position() -> Vector2:
	if center != Vector2.ZERO:
		return center
	return global_position


func get_border_segments() -> Array:
	var segments: Array = []
	for polygon in _polygon_nodes:
		var points: PackedVector2Array = polygon.polygon
		for i in points.size():
			segments.append([points[i], points[(i + 1) % points.size()]])
	return segments


func set_selected(value: bool) -> void:
	_is_selected = value
	_apply_fill_color()


func set_hovered(value: bool) -> void:
	if _is_hovered == value:
		return
	_is_hovered = value
	_apply_fill_color()


func _apply_fill_color() -> void:
	var color := _base_color
	if _is_selected:
		color = _base_color.lightened(0.22)
	elif _is_hovered:
		color = _base_color.lightened(0.12)
	for polygon in _polygon_nodes:
		polygon.color = color
