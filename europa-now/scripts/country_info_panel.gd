extends PanelContainer

@onready var _flag_label: Label = $VBoxContainer/Header/FlagLabel
@onready var _country_name: Label = $VBoxContainer/Header/CountryNameLabel
@onready var _iso_label: Label = $VBoxContainer/IsoLabel
@onready var _population_label: Label = $VBoxContainer/PopulationLabel
@onready var _gdp_label: Label = $VBoxContainer/GdpLabel
@onready var _continent_label: Label = $VBoxContainer/ContinentLabel
@onready var _economy_label: Label = $VBoxContainer/EconomyLabel


func _ready() -> void:
	show_empty()


func show_country(country: Country) -> void:
	_flag_label.text = _iso_to_flag_emoji(country.iso_a2)
	_country_name.text = country.display_name
	_iso_label.text = "ISO: %s / %s" % [country.country_id, country.iso_a2]
	_population_label.text = "Bevoelkerung: %s" % _format_population(country.population)
	_gdp_label.text = "BIP: %s" % _format_gdp(country.gdp_million)
	_continent_label.text = "Kontinent: %s" % country.continent
	_economy_label.text = "Wirtschaft: %s" % _clean_economy_label(country.economy)
	_set_details_visible(true)


func show_empty() -> void:
	_flag_label.text = ""
	_country_name.text = "Kein Land ausgewaehlt"
	_set_details_visible(false)


func _set_details_visible(visible: bool) -> void:
	_iso_label.visible = visible
	_population_label.visible = visible
	_gdp_label.visible = visible
	_continent_label.visible = visible
	_economy_label.visible = visible


func _iso_to_flag_emoji(iso_a2: String) -> String:
	var code := iso_a2.to_upper()
	if code.length() != 2:
		return ""

	var flag := ""
	for i in 2:
		var char_code := code.unicode_at(i)
		if char_code < 65 or char_code > 90:
			return ""
		flag += String.chr(0x1F1E6 + char_code - 65)
	return flag


func _format_population(value: int) -> String:
	if value <= 0:
		return "k. A."
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
