extends PanelContainer

const MAX_LINES := 10

@onready var _log_label: RichTextLabel = $MarginContainer/LogLabel

var _messages: Array[String] = []


func _ready() -> void:
	log_message("Debug-Bereich bereit.")


func log_message(text: String) -> void:
	_messages.append(text)
	while _messages.size() > MAX_LINES:
		_messages.pop_front()
	_log_label.text = "\n".join(_messages)
