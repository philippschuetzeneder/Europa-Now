class_name Province
extends Area2D

const COLLISION_LAYER_PROVINCES := 4
static var _controller_hatch_shader: Shader

var province_id: String
var display_name: String
var country_id: String
var owner_country_id: String
var controller_country_id: String
var controller_color := Color.TRANSPARENT
var center: Vector2
var primary_city: String

var _base_color: Color
var _polygon_nodes: Array[Polygon2D] = []
var _is_selected := false
var _is_hovered := false
var _is_contested := false
var _controller_hatch_nodes: Array[Polygon2D] = []
var _controller_hatch_rings: Array[PackedVector2Array] = []
var _border_segments_cache: Array = []


func setup(data: Dictionary) -> void:
	province_id = data["id"]
	display_name = data["name"]
	country_id = data["country_id"]
	owner_country_id = data.get("owner_country_id", country_id)
	controller_country_id = data.get("controller_country_id", owner_country_id)
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
		border.antialiased = false
		add_child(border)

		_controller_hatch_rings.append(ring)

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
	if not _border_segments_cache.is_empty():
		return _border_segments_cache
	var segments: Array = []
	for polygon in _polygon_nodes:
		var points: PackedVector2Array = polygon.polygon
		for i in points.size():
			segments.append([points[i], points[(i + 1) % points.size()]])
	_border_segments_cache = segments
	return _border_segments_cache


func set_selected(value: bool) -> void:
	_is_selected = value
	_apply_fill_color()


func set_hovered(value: bool) -> void:
	if _is_hovered == value:
		return
	_is_hovered = value
	_apply_fill_color()


func set_contested(value: bool) -> void:
	if _is_contested == value:
		return
	_is_contested = value
	_apply_fill_color()


func set_controller(country_id: String) -> void:
	controller_country_id = country_id
	_apply_controller_overlay()


func set_controller_color(color: Color) -> void:
	controller_color = color
	_apply_controller_overlay()


func set_owner_country(country_id: String) -> void:
	owner_country_id = country_id
	controller_country_id = country_id
	_apply_controller_overlay()


func is_contested() -> bool:
	return _is_contested


func _apply_fill_color() -> void:
	var color := _base_color
	if _is_contested:
		color = _base_color.lerp(Color(0.85, 0.2, 0.18, 1.0), 0.45)
	if _is_selected:
		color = color.lightened(0.22)
	elif _is_hovered:
		color = color.lightened(0.12)
	for polygon in _polygon_nodes:
		polygon.color = color


func _create_controller_hatch(ring: PackedVector2Array) -> void:
	var hatch := Polygon2D.new()
	hatch.polygon = ring
	hatch.z_index = 2
	var material := ShaderMaterial.new()
	material.shader = _get_controller_hatch_shader()
	hatch.material = material
	add_child(hatch)
	_controller_hatch_nodes.append(hatch)


static func _get_controller_hatch_shader() -> Shader:
	if _controller_hatch_shader != null:
		return _controller_hatch_shader
	_controller_hatch_shader = Shader.new()
	_controller_hatch_shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform vec4 stripe_color : source_color;
varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float stripe_position = (local_position.x + local_position.y) * 0.09;
	float stripe = step(0.68, fract(stripe_position));
	COLOR = vec4(stripe_color.rgb, stripe * stripe_color.a * 0.72);
}
"""
	return _controller_hatch_shader


func _apply_controller_overlay() -> void:
	var show_overlay := (
		not controller_country_id.is_empty()
		and controller_country_id != country_id
		and controller_color.a > 0.0
	)
	if show_overlay and _controller_hatch_nodes.is_empty():
		for ring in _controller_hatch_rings:
			_create_controller_hatch(ring)
	for hatch in _controller_hatch_nodes:
		hatch.visible = show_overlay
		var material := hatch.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("stripe_color", controller_color)
