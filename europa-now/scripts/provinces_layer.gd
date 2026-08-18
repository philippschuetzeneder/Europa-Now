class_name ProvincesLayer
extends Node2D

var _provinces: Array[Province] = []
var _provinces_by_id: Dictionary = {}
var _provinces_by_country: Dictionary = {}  # country_id -> Array[Province]


func build_from_countries(countries_data: Array[Dictionary]) -> Array[Province]:
	_clear()

	var reference_area := ProvinceGenerator.reference_area_from_countries(countries_data)
	for country_data in countries_data:
		var generated := ProvinceGenerator.generate_for_country(country_data, reference_area)
		for province_data in generated:
			_add_province(province_data)

	return _provinces


func get_provinces() -> Array[Province]:
	return _provinces


func get_province(province_id: String) -> Province:
	return _provinces_by_id.get(province_id)


func get_provinces_for_country(country_id: String) -> Array[Province]:
	if not _provinces_by_country.has(country_id):
		var empty: Array[Province] = []
		return empty
	var provinces: Array[Province] = _provinces_by_country[country_id]
	return provinces


func get_count_for_country(country_id: String) -> int:
	return get_provinces_for_country(country_id).size()


func find_province_near_position(country_id: String, position: Vector2) -> Province:
	var best: Province = null
	var best_distance := INF
	for province in get_provinces_for_country(country_id):
		var distance := province.center.distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best = province
	return best


func _add_province(data: Dictionary) -> void:
	var province := Province.new()
	province.setup(data)
	add_child(province)
	_provinces.append(province)
	_provinces_by_id[province.province_id] = province

	if not _provinces_by_country.has(province.country_id):
		var list: Array[Province] = []
		_provinces_by_country[province.country_id] = list
	var country_provinces: Array[Province] = _provinces_by_country[province.country_id]
	country_provinces.append(province)


func _clear() -> void:
	for child in get_children():
		child.queue_free()
	_provinces.clear()
	_provinces_by_id.clear()
	_provinces_by_country.clear()
