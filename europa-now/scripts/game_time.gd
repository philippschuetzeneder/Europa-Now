extends Node

signal day_advanced(date: GameDate)
signal speed_changed(speed: int)

enum Speed { PAUSE, X1, X2, X5 }

const SECONDS_PER_DAY_AT_1X := 1.0

var current_date: GameDate
var speed: Speed = Speed.PAUSE

var _accumulator := 0.0


func _ready() -> void:
	current_date = GameDate.new(2022, 1, 1)


func _process(delta: float) -> void:
	if speed == Speed.PAUSE:
		return

	var speed_multiplier := _get_speed_multiplier()
	_accumulator += delta
	var threshold := SECONDS_PER_DAY_AT_1X / speed_multiplier

	while _accumulator >= threshold:
		_accumulator -= threshold
		_advance_day()


func set_speed(new_speed: Speed) -> void:
	if speed == new_speed:
		return
	speed = new_speed
	if speed == Speed.PAUSE:
		_accumulator = 0.0
	speed_changed.emit(speed)


func get_speed_label() -> String:
	match speed:
		Speed.PAUSE:
			return "Pause"
		Speed.X1:
			return "1x"
		Speed.X2:
			return "2x"
		Speed.X5:
			return "5x"
		_:
			return "?"


func _advance_day() -> void:
	current_date = current_date.add_days(1)
	day_advanced.emit(current_date)


func _get_speed_multiplier() -> float:
	match speed:
		Speed.X1:
			return 1.0
		Speed.X2:
			return 2.0
		Speed.X5:
			return 5.0
		_:
			return 1.0
