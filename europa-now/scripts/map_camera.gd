extends Camera2D

class_name MapCamera

signal zoom_changed(zoom_level: float)

const MIN_ZOOM := 0.15
const MAX_ZOOM := 4.0
const ZOOM_STEP := 0.1
const PAN_MOUSE_BUTTONS := [MOUSE_BUTTON_MIDDLE]
const KEY_PAN_SPEED := 900.0

var _is_panning := false


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	_apply_keyboard_pan(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _is_panning:
		position -= event.relative / zoom


func fit_to_bounds(bounds: Rect2, viewport_size: Vector2, padding := 80.0) -> void:
	if bounds.size == Vector2.ZERO:
		return

	position = bounds.get_center()

	var usable := viewport_size - Vector2(padding, padding) * 2.0
	var zoom_x := usable.x / bounds.size.x
	var zoom_y := usable.y / bounds.size.y
	_set_zoom(clampf(minf(zoom_x, zoom_y), MIN_ZOOM, MAX_ZOOM))


func _apply_keyboard_pan(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1.0

	if direction == Vector2.ZERO:
		return

	position += direction.normalized() * KEY_PAN_SPEED * delta / zoom.x


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_apply_zoom(1.0 + ZOOM_STEP, event.position)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_apply_zoom(1.0 - ZOOM_STEP, event.position)
	elif event.button_index in PAN_MOUSE_BUTTONS:
		_is_panning = event.pressed


func _apply_zoom(factor: float, _screen_point: Vector2) -> void:
	var old_zoom := zoom.x
	var new_zoom := clampf(old_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(old_zoom, new_zoom):
		return

	var world_before := get_global_mouse_position()
	_set_zoom(new_zoom)
	var world_after := get_global_mouse_position()
	position += world_before - world_after


func _set_zoom(value: float) -> void:
	if is_equal_approx(zoom.x, value):
		return
	zoom = Vector2.ONE * value
	zoom_changed.emit(value)
