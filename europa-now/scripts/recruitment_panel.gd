class_name RecruitmentPanel
extends PanelContainer

@onready var _title: Label = $Margin/VBox/Title
@onready var _province_label: Label = $Margin/VBox/Province
@onready var _cost: Label = $Margin/VBox/Cost
@onready var _duration: Label = $Margin/VBox/Duration
@onready var _available: Label = $Margin/VBox/Available
@onready var _soldiers: SpinBox = $Margin/VBox/Soldiers
@onready var _recruit_button: Button = $Margin/VBox/Recruit
@onready var _close_button: Button = $Margin/VBox/Close
@onready var _message: Label = $Margin/VBox/Message

var _economy_manager: EconomyManager
var _province: Province
var _country_id := ""


func _ready() -> void:
	_soldiers.value_changed.connect(_refresh_preview)
	_recruit_button.pressed.connect(_recruit)
	_close_button.pressed.connect(_close)
	visible = false


func setup(manager: EconomyManager) -> void:
	_economy_manager = manager


func show_for_province(province: Province, country_id: String) -> void:
	if _economy_manager == null:
		return
	_province = province
	_country_id = country_id
	_title.text = "Armee rekrutieren"
	_province_label.text = "Provinz: %s" % province.display_name
	_message.text = ""
	visible = true
	_refresh_preview(_soldiers.value)


func refresh_preview() -> void:
	_refresh_preview(_soldiers.value)


func show_message(message: String) -> void:
	_message.text = message


func _refresh_preview(_value: float) -> void:
	if _economy_manager == null:
		return
	var preview: Dictionary = _economy_manager.preview_recruitment(
		_country_id,
		int(_soldiers.value)
	)
	_cost.text = "Kosten: € %s" % _format_number(int(preview["cost"]))
	_duration.text = "Ausbildungszeit: %d Tage" % int(preview["days"])
	var economy: CountryEconomy = _economy_manager.get_economy(_country_id)
	if economy != null:
		_available.text = "Verfuegbar: %s" % _format_number(economy.available_recruitable_population())
	_recruit_button.disabled = _province == null or _province.controller_country_id != _country_id


func _recruit() -> void:
	if _province == null:
		return
	var order: RecruitmentOrder = _economy_manager.create_recruitment_order(
		_country_id,
		_province.province_id,
		int(_soldiers.value)
	)
	if order == null:
		_message.text = "Rekrutierung nicht moeglich."
		return
	_message.text = "Auftrag angenommen. Fertig: %s" % order.completion_date.format_long()
	_refresh_preview(_soldiers.value)


func _close() -> void:
	visible = false


func _format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	for i in text.length():
		if i > 0 and (text.length() - i) % 3 == 0:
			result += "."
		result += text[i]
	return result
