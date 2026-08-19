class_name ForeignCountryPanel
extends PanelContainer

var _title := Label.new()
var _details := Label.new()
var _flag := TextureRect.new()


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
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_flag.custom_minimum_size = Vector2(40, 28)
	_flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_flag)
	_title.add_theme_font_size_override("font_size", 17)
	header.add_child(_title)
	box.add_child(header)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_details)
	visible = false


func show_country(country: Country) -> void:
	_flag.texture = FlagFactory.get_flag_texture(country)
	_title.text = country.display_name
	_details.text = "\n".join([
		"Staatsoberhaupt: %s" % country.head_of_state,
		"Regierung: %s" % country.government_type,
		"Bevölkerung: %s" % _format_number(country.population),
		"BIP: %s" % _format_gdp(country.gdp_million),
	])
	visible = true


func close_panel() -> void:
	visible = false


func _format_gdp(value: int) -> String:
	if value >= 1_000_000:
		return "$%.1f Bio." % (value / 1_000_000.0)
	if value >= 1_000:
		return "$%.1f Mrd." % (value / 1_000.0)
	return "$%s Mio." % _format_number(value)


func _format_number(value: int) -> String:
	var absolute_value := absi(value)
	if absolute_value >= 1_000_000_000:
		return "%.1f Mrd." % (value / 1_000_000_000.0)
	if absolute_value >= 1_000_000:
		return "%.1f Mio." % (value / 1_000_000.0)
	if absolute_value >= 1_000:
		return "%.1f K" % (value / 1_000.0)
	return str(value)
