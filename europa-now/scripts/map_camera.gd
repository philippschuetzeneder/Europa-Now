extends Camera2D

class_name MapCamera

signal zoom_changed(zoom_level: float)

const MAX_ZOOM := 14.0
const ZOOM_STEP := 0.12
const START_ZOOM_IN_STEPS := 13
const EXTRA_ZOOM_OUT_STEPS := 0
const DRAG_THRESHOLD := 5.0
const KEY_PAN_SPEED := 900.0

var _is_panning := false
var _fit_zoom := 1.0
var _min_zoom_limit := 1.0
var _left_button_down := false
var _left_drag_active := false
var _left_press_position := Vector2.ZERO


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	_apply_keyboard_pan(delta)
	_apply_horizontal_wrap()


func _apply_horizontal_wrap() -> void:
	var wrapped_x: float = GeoProjection.wrap_x(position.x)
	if not is_equal_approx(position.x, wrapped_x):
		position.x = wrapped_x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func did_left_drag() -> bool:
	return _left_drag_active


func reset_left_drag_state() -> void:
	_left_drag_active = false
	_left_button_down = false


func get_fit_zoom() -> float:
	return _fit_zoom


func get_min_zoom_limit() -> float:
	return _min_zoom_limit


func get_start_zoom() -> float:
	return _fit_zoom * pow(1.0 + ZOOM_STEP, float(START_ZOOM_IN_STEPS))


func has_valid_world_fit() -> bool:
	return _fit_zoom < 0.85


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _left_button_down:
		if not _left_drag_active and _left_press_position.distance_to(event.position) > DRAG_THRESHOLD:
			_left_drag_active = true
		if _left_drag_active:
			position -= event.relative / zoom
			_apply_horizontal_wrap()
			get_viewport().set_input_as_handled()
			return

	if _is_panning:
		position -= event.relative / zoom
		_apply_horizontal_wrap()


func fit_to_bounds(bounds: Rect2, viewport_size: Vector2, padding := 80.0) -> void:
	if bounds.size == Vector2.ZERO:
		return

	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		var viewport := get_viewport()
		if viewport != null:
			viewport_size = viewport.get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return

	position = bounds.get_center()

	var usable := viewport_size - Vector2(padding, padding) * 2.0
	usable.x = maxf(usable.x, 1.0)
	usable.y = maxf(usable.y, 1.0)
	var zoom_x := usable.x / bounds.size.x
	var zoom_y := usable.y / bounds.size.y
	var fit_zoom := minf(zoom_x, zoom_y)
	_fit_zoom = fit_zoom
	_min_zoom_limit = fit_zoom * pow(1.0 - ZOOM_STEP, float(EXTRA_ZOOM_OUT_STEPS))
	var start_zoom: float = get_start_zoom()
	_set_zoom(start_zoom)


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
	_apply_horizontal_wrap()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_apply_zoom(1.0 + ZOOM_STEP, event.position)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_apply_zoom(1.0 - ZOOM_STEP, event.position)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_left_button_down = true
			_left_drag_active = false
			_left_press_position = event.position
		else:
			_left_button_down = false
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_panning = event.pressed


func _apply_zoom(factor: float, _screen_point: Vector2) -> void:
	var old_zoom := zoom.x
	var new_zoom := clampf(old_zoom * factor, _min_zoom_limit, MAX_ZOOM)
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
