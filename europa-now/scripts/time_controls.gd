extends PanelContainer

@onready var _date_label: Label = $HBoxContainer/DateLabel
@onready var _pause_button: Button = $HBoxContainer/SpeedButtons/PauseButton
@onready var _x1_button: Button = $HBoxContainer/SpeedButtons/X1Button
@onready var _x2_button: Button = $HBoxContainer/SpeedButtons/X2Button
@onready var _x5_button: Button = $HBoxContainer/SpeedButtons/X5Button

var _speed_buttons: Array[Button] = []


func _ready() -> void:
	_speed_buttons = [_pause_button, _x1_button, _x2_button, _x5_button]
	_pause_button.pressed.connect(func(): GameTime.set_speed(GameTime.Speed.PAUSE))
	_x1_button.pressed.connect(func(): GameTime.set_speed(GameTime.Speed.X1))
	_x2_button.pressed.connect(func(): GameTime.set_speed(GameTime.Speed.X2))
	_x5_button.pressed.connect(func(): GameTime.set_speed(GameTime.Speed.X5))

	GameTime.day_advanced.connect(_on_day_advanced)
	GameTime.speed_changed.connect(_on_speed_changed)

	_refresh_date()
	_refresh_speed_buttons()


func _on_day_advanced(_date: GameDate) -> void:
	_refresh_date()


func _on_speed_changed(_speed: int) -> void:
	_refresh_speed_buttons()


func _refresh_date() -> void:
	_date_label.text = GameTime.current_date.format_long()


func _refresh_speed_buttons() -> void:
	var active_index := GameTime.speed
	for i in _speed_buttons.size():
		_speed_buttons[i].disabled = i == active_index
