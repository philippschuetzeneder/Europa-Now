class_name GameMenu
extends PanelContainer

signal save_requested
signal load_requested

@onready var _save_button: Button = $VBox/SaveButton
@onready var _load_button: Button = $VBox/LoadButton
@onready var _close_button: Button = $VBox/CloseButton


func _ready() -> void:
	_save_button.pressed.connect(func() -> void: save_requested.emit())
	_load_button.pressed.connect(func() -> void: load_requested.emit())
	_close_button.pressed.connect(func() -> void: visible = false)
	visible = false


func toggle() -> void:
	visible = not visible
