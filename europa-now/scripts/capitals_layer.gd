class_name CapitalsLayer
extends Node2D

var _markers: Array[CapitalMarker] = []


func build_from_countries(countries: Array[Country]) -> void:
	for child in get_children():
		child.queue_free()
	_markers.clear()

	for country in countries:
		if country.capital_name.is_empty() or country.capital_name == "k. A.":
			continue
		var marker := CapitalMarker.new()
		marker.setup(country.capital_name, country.capital_position)
		add_child(marker)
		_markers.append(marker)


func update_zoom_visibility(zoom_level: float) -> void:
	for marker in _markers:
		marker.update_zoom_visibility(zoom_level)
