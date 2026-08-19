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
	"ALB": {"capital": "Tirana", "head_of_state": "Bajram Begaj", "government": "Parlamentarische Republik"},
	"AND": {"capital": "Andorra la Vella", "head_of_state": "Co-Fürsten von Andorra", "government": "Parlamentarisches Co-Fürstentum"},
	"BEL": {"capital": "Brüssel", "head_of_state": "König Philippe", "government": "Föderale konstitutionelle Monarchie"},
	"BIH": {"capital": "Sarajevo", "head_of_state": "Präsidium von Bosnien und Herzegowina", "government": "Parlamentarische Republik"},
	"BLR": {"capital": "Minsk", "head_of_state": "Alexander Lukaschenko", "government": "Präsidentielle Republik"},
	"BGR": {"capital": "Sofia", "head_of_state": "Iliana Iwanowa", "government": "Parlamentarische Republik"},
	"CHE": {"capital": "Bern", "head_of_state": "Bundesrat der Schweiz", "government": "Direkte Demokratie"},
	"CYP": {"capital": "Nikosia", "head_of_state": "Nikos Christodoulides", "government": "Präsidentielle Republik"},
	"GEO": {"capital": "Tiflis", "head_of_state": "Mikheil Kavelashvili", "government": "Parlamentarische Republik"},
	"HRV": {"capital": "Zagreb", "head_of_state": "Zoran Milanović", "government": "Parlamentarische Republik"},
	"CZE": {"capital": "Prag", "head_of_state": "Petr Pavel", "government": "Parlamentarische Republik"},
	"DNK": {"capital": "Kopenhagen", "head_of_state": "König Frederik X.", "government": "Konstitutionelle Monarchie"},
	"ESP": {"capital": "Madrid", "head_of_state": "König Felipe VI.", "government": "Parlamentarische Monarchie"},
	"EST": {"capital": "Tallinn", "head_of_state": "Alar Karis", "government": "Parlamentarische Republik"},
	"FIN": {"capital": "Helsinki", "head_of_state": "Alexander Stubb", "government": "Parlamentarische Republik"},
	"GRC": {"capital": "Athen", "head_of_state": "Konstantinos Tasoulas", "government": "Parlamentarische Republik"},
	"HUN": {"capital": "Budapest", "head_of_state": "Tamás Sulyok", "government": "Parlamentarische Republik"},
	"IRL": {"capital": "Dublin", "head_of_state": "Catherine Connolly", "government": "Parlamentarische Republik"},
	"ISL": {"capital": "Reykjavik", "head_of_state": "Halla Tómasdóttir", "government": "Parlamentarische Republik"},
	"ITA": {"capital": "Rom", "head_of_state": "Sergio Mattarella", "government": "Parlamentarische Republik"},
	"LTU": {"capital": "Vilnius", "head_of_state": "Gitanas Nausėda", "government": "Parlamentarische Republik"},
	"LUX": {"capital": "Luxemburg", "head_of_state": "Großherzog Guillaume", "government": "Parlamentarische Monarchie"},
	"LVA": {"capital": "Riga", "head_of_state": "Edgars Rinkēvičs", "government": "Parlamentarische Republik"},
	"LIE": {"capital": "Vaduz", "head_of_state": "Erbprinz Alois von Liechtenstein", "government": "Konstitutionelle Monarchie"},
	"MDA": {"capital": "Chișinău", "head_of_state": "Maia Sandu", "government": "Parlamentarische Republik"},
	"MCO": {"capital": "Monaco", "head_of_state": "Fürst Albert II.", "government": "Konstitutionelle Monarchie"},
	"MKD": {"capital": "Skopje", "head_of_state": "Gordana Siljanovska-Davkova", "government": "Parlamentarische Republik"},
	"MLT": {"capital": "Valletta", "head_of_state": "Myriam Spiteri Debono", "government": "Parlamentarische Republik"},
	"MNE": {"capital": "Podgorica", "head_of_state": "Jakov Milatović", "government": "Parlamentarische Republik"},
	"NLD": {"capital": "Amsterdam", "head_of_state": "König Willem-Alexander", "government": "Parlamentarische Monarchie"},
	"NOR": {"capital": "Oslo", "head_of_state": "König Harald V.", "government": "Konstitutionelle Monarchie"},
	"POL": {"capital": "Warschau", "head_of_state": "Karol Nawrocki", "government": "Parlamentarische Republik"},
	"PRT": {"capital": "Lissabon", "head_of_state": "Marcelo Rebelo de Sousa", "government": "Parlamentarische Republik"},
	"ROU": {"capital": "Bukarest", "head_of_state": "Nicușor Dan", "government": "Semipräsidentielle Republik"},
	"SRB": {"capital": "Belgrad", "head_of_state": "Aleksandar Vučić", "government": "Parlamentarische Republik"},
	"SVK": {"capital": "Bratislava", "head_of_state": "Peter Pellegrini", "government": "Parlamentarische Republik"},
	"SVN": {"capital": "Ljubljana", "head_of_state": "Nataša Pirc Musar", "government": "Parlamentarische Republik"},
	"SWE": {"capital": "Stockholm", "head_of_state": "König Carl XVI. Gustaf", "government": "Konstitutionelle Monarchie"},
	"TUR": {"capital": "Ankara", "head_of_state": "Recep Tayyip Erdoğan", "government": "Präsidentielle Republik"},
	"UKR": {"capital": "Kyjiw", "head_of_state": "Wolodymyr Selenskyj", "government": "Semipräsidentielle Republik"},
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
	var head_of_state: String = str(meta.get("head_of_state", data.get("head_of_state", "")))
	if head_of_state.is_empty() or head_of_state == "k. A.":
		head_of_state = "Staatsoberhaupt von %s" % str(data.get("name", country_id))
	data["head_of_state"] = head_of_state
	var government_type: String = str(meta.get("government", data.get("government_type", "")))
	if government_type.is_empty() or government_type == "k. A.":
		government_type = "Staatsform nicht spezifiziert"
	data["government_type"] = government_type

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
