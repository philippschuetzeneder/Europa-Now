class_name ArmyInfoPanel
extends PanelContainer

var _title := Label.new()
var _details := Label.new()
var _close_button := Button.new()


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	_title.add_theme_font_size_override("font_size", 17)
	box.add_child(_title)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_details)
	_close_button.text = "Schliessen"
	_close_button.pressed.connect(_close)
	box.add_child(_close_button)
	visible = false


func show_unit(unit: Unit, combat: CombatState = null, unit_manager: UnitManager = null) -> void:
	_title.text = "Armee: %s" % unit.data.unit_id
	var lines: PackedStringArray = [
		"Land: %s" % unit.data.owner_country_id,
		"Provinz: %s" % unit.data.current_province_id,
		"Soldaten: %s" % _format_number(unit.data.soldiers),
		"Kampfstärke: %s" % _format_number(int(unit.data.effective_strength())),
		"Moral: %.0f" % unit.data.morale,
		"Organisation: %.0f" % unit.data.organization,
		"Verluste: %s" % _format_number(unit.data.casualties_this_battle),
	]
	if combat != null:
		lines.append("Status: Kampf, Tag %d" % combat.days_fought)
	elif unit.data.is_retreating:
		lines.append("Status: Rückzug")
	elif unit.data.is_moving:
		lines.append("Status: Bewegung")
	else:
		lines.append("Status: Bereit")
	_details.text = "\n".join(lines)
	visible = true


func close_panel() -> void:
	visible = false


func _close() -> void:
	close_panel()


func _format_number(value: int) -> String:
	var absolute_value := absi(value)
	var suffix := ""
	var number := float(absolute_value)
	if absolute_value >= 1_000_000_000:
		number /= 1_000_000_000.0
		suffix = " Mrd."
	elif absolute_value >= 1_000_000:
		number /= 1_000_000.0
		suffix = " Mio."
	elif absolute_value >= 1_000:
		number /= 1_000.0
		suffix = " K"
	var sign := "-" if value < 0 else ""
	return "%s%.1f%s" % [sign, number, suffix] if not suffix.is_empty() else "%s%d" % [sign, absolute_value]
