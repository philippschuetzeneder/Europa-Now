class_name CountryMetadata
extends RefCounted

const WORLD_CAPITALS_PATH := "res://data/world_capitals.json"
const WORLD_POPULATION_PATH := "res://data/world_population.json"
const AUSTRIA_AREA_KM2 := 83879.0

## Detailed metadata for selected countries (ISO-A3). Others use world_capitals.json or GeoJSON labels.
const DATA: Dictionary = {
	"AUT": {"capital": "Wien", "lon": 16.3738, "lat": 48.2082, "head_of_state": "Alexander Van der Bellen", "government": "Parlamentarische Republik"},
	"DEU": {"capital": "Berlin", "lon": 13.4050, "lat": 52.5200, "head_of_state": "Frank-Walter Steinmeier", "government": "Parlamentarische Demokratie"},
	"FRA": {"capital": "Paris", "lon": 2.3522, "lat": 48.8566, "head_of_state": "Emmanuel Macron", "government": "Semipraesidentielle Republik"},
	"GBR": {"capital": "London", "lon": -0.1276, "lat": 51.5072, "head_of_state": "Charles III.", "government": "Parlamentarische Monarchie"},
	"USA": {"capital": "Washington D.C.", "lon": -77.036, "lat": 38.897, "head_of_state": "Joe Biden", "government": "Praesidentielle Foederation"},
	"CHN": {"capital": "Peking", "lon": 116.407, "lat": 39.904, "head_of_state": "Xi Jinping", "government": "Einparteienstaat"},
	"RUS": {"capital": "Moskau", "lon": 37.6173, "lat": 55.7558, "head_of_state": "Wladimir Putin", "government": "Praesidentielle Foederation"},
}

static var _world_capitals: Dictionary = {}
static var _world_capitals_loaded := false
static var _world_population: Dictionary = {}
static var _world_population_loaded := false


static func enrich_country_data(data: Dictionary) -> Dictionary:
	_ensure_world_capitals_loaded()
	_ensure_world_population_loaded()

	var country_id: String = str(data.get("id", ""))
	var meta: Dictionary = DATA.get(country_id, {})
	var world_meta: Dictionary = _world_capitals.get(country_id, {})

	var capital_name: String = str(meta.get("capital", world_meta.get("capital", "")))
	var lon: float = float(meta.get("lon", world_meta.get("lon", data.get("label_lon", 0.0))))
	var lat: float = float(meta.get("lat", world_meta.get("lat", data.get("label_lat", 0.0))))

	if capital_name.is_empty():
		capital_name = "k. A."

	data["capital_name"] = capital_name
	data["capital_position"] = GeoProjection.project(lon, lat)
	data["head_of_state"] = str(meta.get("head_of_state", "k. A."))
	data["government_type"] = str(meta.get("government", "k. A."))

	var wiki_population: int = int(_world_population.get(country_id, 0))
	if wiki_population > 0:
		data["population"] = wiki_population

	if not data.has("area_km2"):
		data["area_km2"] = 0.0

	return data


static func _ensure_world_capitals_loaded() -> void:
	if _world_capitals_loaded:
		return
	_world_capitals_loaded = true

	var file := FileAccess.open(WORLD_CAPITALS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not load world capitals: %s" % WORLD_CAPITALS_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_world_capitals = parsed


static func _ensure_world_population_loaded() -> void:
	if _world_population_loaded:
		return
	_world_population_loaded = true

	var file := FileAccess.open(WORLD_POPULATION_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not load world population: %s" % WORLD_POPULATION_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_world_population = parsed
