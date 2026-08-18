class_name Country
extends Area2D

const COLLISION_LAYER_COUNTRIES := 1

signal selected(country: Country)

var country_id: String
var display_name: String
var iso_a2: String
var population: int
var gdp_million: int
var continent: String
var economy: String

var _base_color: Color
var _polygon_nodes: Array[Polygon2D] = []
var _is_selected := false
var _is_hovered := false


func setup(data: Dictionary) -> void:
	country_id = data["id"]
	display_name = data["name"]
	iso_a2 = data.get("iso_a2", "")
	population = data.get("population", 0)
	gdp_million = data.get("gdp_million", 0)
	continent = data.get("continent", "")
	economy = data.get("economy", "")

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
		border.default_color = Color(0.12, 0.14, 0.18, 1.0)
		border.width = 1.25
		border.antialiased = true
		add_child(border)

		var collision := CollisionPolygon2D.new()
		collision.polygon = ring
		add_child(collision)

	collision_layer = COLLISION_LAYER_COUNTRIES
	collision_mask = 0
	input_pickable = false


func get_placement_position() -> Vector2:
	var best_ring: PackedVector2Array = PackedVector2Array()
	var best_size := 0

	for polygon in _polygon_nodes:
		if polygon.polygon.size() > best_size:
			best_size = polygon.polygon.size()
			best_ring = polygon.polygon

	if best_ring.is_empty():
		return global_position

	return _polygon_centroid(best_ring)


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
		color = _base_color.lightened(0.28)
	elif _is_hovered:
		color = _base_color.lightened(0.16)
	for polygon in _polygon_nodes:
		polygon.color = color


func _polygon_centroid(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO

	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())
