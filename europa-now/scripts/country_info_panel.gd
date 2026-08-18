extends PanelContainer

@onready var _flag: TextureRect = $VBoxContainer/Header/FlagRect
@onready var _country_name: Label = $VBoxContainer/Header/CountryNameLabel
@onready var _province_label: Label = $VBoxContainer/ProvinceLabel
@onready var _head_of_state_label: Label = $VBoxContainer/HeadOfStateLabel
@onready var _government_label: Label = $VBoxContainer/GovernmentLabel
@onready var _population_label: Label = $VBoxContainer/PopulationLabel
@onready var _gdp_label: Label = $VBoxContainer/GdpLabel
@onready var _continent_label: Label = $VBoxContainer/ContinentLabel
@onready var _economy_label: Label = $VBoxContainer/EconomyLabel
@onready var _combat_label: Label = $VBoxContainer/CombatLabel

var _countries_by_id: Dictionary = {}


func _ready() -> void:
	show_empty()


func set_countries_lookup(countries_by_id: Dictionary) -> void:
	_countries_by_id = countries_by_id


func show_country(country: Country, keep_province: bool = false) -> void:
	_flag.texture = FlagFactory.get_flag_texture(country)
	_country_name.text = country.display_name
	_head_of_state_label.text = "Staatsoberhaupt: %s" % country.head_of_state
	_government_label.text = "Regierung: %s" % country.government_type
	_population_label.text = "Bevoelkerung (2024): %s" % _format_population(country.population)
	_gdp_label.text = "BIP: %s" % _format_gdp(country.gdp_million)
	_continent_label.text = "Kontinent: %s" % country.continent
	_economy_label.text = "Wirtschaft: %s" % _clean_economy_label(country.economy)
	if not keep_province:
		_province_label.text = "Provinz: -"
	_province_label.visible = true
	_set_details_visible(true)


func show_province(province: Province) -> void:
	_province_label.text = "Provinz: %s" % province.display_name
	_province_label.visible = true


func show_unit(unit: Unit) -> void:
	var country: Country = _countries_by_id.get(unit.data.owner_country_id)
	if country != null:
		show_country(country, true)
	var province_name := unit.data.current_province_id
	_combat_label.text = (
		"Einheit: %s\nSoldaten: %s\nKampfst. %.0f\nMoral: %.0f\nOrganisation: %.0f\nVerluste: %s"
		% [
			unit.data.unit_id,
			_format_population(unit.data.soldiers),
			unit.data.effective_strength(),
			unit.data.morale,
			unit.data.organization,
			_format_population(unit.data.casualties_this_battle),
		]
	)
	_combat_label.visible = true


func show_combat(combat: CombatState, unit_manager: UnitManager) -> void:
	if combat == null:
		hide_combat()
		return

	var lines: PackedStringArray = []
	lines.append("KAMPF")
	lines.append("")
	lines.append(_format_combat_side("Angreifer", combat.attacker_country_ids, combat.attacker_unit_ids, combat.attacker_casualties, unit_manager))
	lines.append("")
	lines.append(_format_combat_side("Verteidiger", combat.defender_country_ids, combat.defender_unit_ids, combat.defender_casualties, unit_manager))
	lines.append("")
	lines.append("Kampfdauer: %dh" % combat.get_duration_hours())
	lines.append("Status: %s" % _combat_status_text(combat, unit_manager))
	_combat_label.text = "\n".join(lines)
	_combat_label.visible = true


func hide_combat() -> void:
	_combat_label.text = ""
	_combat_label.visible = false


func show_empty() -> void:
	_flag.texture = FlagFactory.get_placeholder_texture()
	_country_name.text = "Kein Land ausgewaehlt"
	_province_label.visible = false
	hide_combat()
	_set_details_visible(false)


func _set_details_visible(visible: bool) -> void:
	_head_of_state_label.visible = visible
	_government_label.visible = visible
	_population_label.visible = visible
	_gdp_label.visible = visible
	_continent_label.visible = visible
	_economy_label.visible = visible


func _format_combat_side(
	side_label: String,
	country_ids: Array[String],
	unit_ids: Array[String],
	casualties: int,
	unit_manager: UnitManager
) -> String:
	var country_names: PackedStringArray = []
	for country_id in country_ids:
		var country: Country = _countries_by_id.get(country_id)
		country_names.append(country.display_name if country != null else country_id)

	var soldiers := 0
	var strength := 0.0
	var morale_sum := 0.0
	var org_sum := 0.0
	var count := 0
	for unit_id in unit_ids:
		var unit := unit_manager.get_unit(unit_id)
		if unit == null:
			continue
		soldiers += unit.data.soldiers
		strength += unit.data.effective_strength()
		morale_sum += unit.data.morale
		org_sum += unit.data.organization
		count += 1

	var morale := morale_sum / maxf(float(count), 1.0)
	var org := org_sum / maxf(float(count), 1.0)
	return (
		"%s: %s\n%s Soldaten\nKampfst. %.0f\nMoral: %.0f\nOrganisation: %.0f\nVerluste: %s"
		% [
			side_label,
			", ".join(country_names),
			_format_population(soldiers),
			strength,
			morale,
			org,
			_format_population(casualties),
		]
	)


func _combat_status_text(combat: CombatState, unit_manager: UnitManager) -> String:
	if not combat.is_active():
		if combat.winner_side == "attacker":
			return _country_names(combat.attacker_country_ids) + " siegt"
		return _country_names(combat.defender_country_ids) + " siegt"

	var attacker_units := _get_units(combat.attacker_unit_ids, unit_manager)
	var defender_units := _get_units(combat.defender_unit_ids, unit_manager)
	var attacker_eff := CombatCalculator.side_effective_strength(attacker_units)
	var defender_eff := CombatCalculator.side_effective_strength(defender_units)
	if attacker_eff > defender_eff:
		return _country_names(combat.attacker_country_ids) + " gewinnt"
	if defender_eff > attacker_eff:
		return _country_names(combat.defender_country_ids) + " gewinnt"
	return "Ausgeglichen"


func _country_names(country_ids: Array[String]) -> String:
	var names: PackedStringArray = []
	for country_id in country_ids:
		var country: Country = _countries_by_id.get(country_id)
		names.append(country.display_name if country != null else country_id)
	return ", ".join(names)


func _get_units(unit_ids: Array[String], unit_manager: UnitManager) -> Array:
	var result: Array = []
	for unit_id in unit_ids:
		var unit := unit_manager.get_unit(unit_id)
		if unit != null:
			result.append(unit)
	return result


func _format_population(value: int) -> String:
	if value <= 0:
		return "0"
	if value >= 1_000_000:
		return "%.1f Mio." % (value / 1_000_000.0)
	return "%s" % _with_thousands_separator(value)


func _format_gdp(value: int) -> String:
	if value <= 0:
		return "k. A."
	if value >= 1_000_000:
		return "$%.1f Bio." % (value / 1_000_000.0)
	if value >= 1_000:
		return "$%.1f Mrd." % (value / 1_000.0)
	return "$%s Mio." % _with_thousands_separator(value)


func _with_thousands_separator(value: int) -> String:
	var text := str(value)
	var result := ""
	for i in text.length():
		if i > 0 and (text.length() - i) % 3 == 0:
			result += "."
		result += text[i]
	return result


func _clean_economy_label(raw: String) -> String:
	if raw.is_empty():
		return "k. A."
	var parts := raw.split(": ", false, 1)
	if parts.size() == 2:
		return parts[1]
	return raw
