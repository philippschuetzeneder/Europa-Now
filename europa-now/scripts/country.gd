class_name Country
extends Area2D

const COLLISION_LAYER_COUNTRIES := 1

var country_id: String
var display_name: String
var iso_a2: String
var population: int
var gdp_million: int
var continent: String
var economy: String
var capital_name: String
var capital_position: Vector2
var head_of_state: String
var government_type: String

var _base_color: Color
var _rings: Array = []
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
	capital_name = data.get("capital_name", "")
	capital_position = data.get("capital_position", Vector2.ZERO)
	head_of_state = data.get("head_of_state", "k. A.")
	government_type = data.get("government_type", "k. A.")

	var color: Color = data["color"]
	_base_color = color

	for ring in data["rings"]:
		if ring is not PackedVector2Array or ring.size() < 3:
			continue

		_rings.append(ring)

		var fill := Polygon2D.new()
		fill.polygon = ring
		fill.color = color
		fill.color.a = 0.15
		add_child(fill)

		var border := Line2D.new()
		border.points = ring
		border.closed = true
		border.default_color = Color(0.10, 0.12, 0.16, 0.95)
		border.width = 2.0
		border.antialiased = true
		add_child(border)

		var collision := CollisionPolygon2D.new()
		collision.polygon = ring
		add_child(collision)

	collision_layer = COLLISION_LAYER_COUNTRIES
	collision_mask = 0
	input_pickable = false


func get_placement_position() -> Vector2:
	var best_ring := _largest_ring()
	if best_ring.is_empty():
		return global_position
	return _polygon_centroid(best_ring)


func get_border_segments() -> Array:
	var segments: Array = []
	for ring in _rings:
		if ring is not PackedVector2Array:
			continue
		for i in ring.size():
			segments.append([ring[i], ring[(i + 1) % ring.size()]])
	return segments


func _largest_ring() -> PackedVector2Array:
	var best: PackedVector2Array = PackedVector2Array()
	var best_size := 0
	for ring in _rings:
		if ring is PackedVector2Array and ring.size() > best_size:
			best_size = ring.size()
			best = ring
	return best


func set_selected(value: bool) -> void:
	_is_selected = value


func set_hovered(value: bool) -> void:
	_is_hovered = value


func _apply_fill_color() -> void:
	pass


func _polygon_centroid(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO

	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())
