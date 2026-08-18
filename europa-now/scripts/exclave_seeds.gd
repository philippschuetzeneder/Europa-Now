class_name ExclaveSeeds
extends RefCounted

## Strategically important islands and exclaves as dedicated province seeds (WGS84).


static func seeds_for_country(country_id: String) -> Array[Dictionary]:
	if not _EXCLAVES.has(country_id):
		return []
	return _from_entries(_EXCLAVES[country_id])


static func name_for_point(country_id: String, point: Vector2, max_distance: float = 2.5) -> String:
	for entry in seeds_for_country(country_id):
		var seed_position: Vector2 = entry["position"]
		if seed_position.distance_to(point) <= max_distance:
			return str(entry["name"])
	return ""


const _EXCLAVES: Dictionary = {
	"RUS": [
		{"slug": "crimea", "name": "Krim", "lon": 34.10, "lat": 45.35},
		{"slug": "kaliningrad", "name": "Kaliningrad", "lon": 20.51, "lat": 54.71},
	],
	"FRA": [
		{"slug": "corsica", "name": "Korsika", "lon": 9.00, "lat": 42.15},
	],
	"ITA": [
		{"slug": "sicily", "name": "Sizilien", "lon": 14.02, "lat": 37.60},
		{"slug": "sardinia", "name": "Sardinien", "lon": 9.00, "lat": 40.00},
	],
	"DNK": [
		{"slug": "sjaelland", "name": "Seeland", "lon": 11.75, "lat": 55.55},
		{"slug": "bornholm", "name": "Bornholm", "lon": 15.00, "lat": 55.10},
		{"slug": "fyn", "name": "Fünen", "lon": 10.45, "lat": 55.35},
	],
	"GRC": [
		{"slug": "crete", "name": "Kreta", "lon": 24.90, "lat": 35.20},
	],
	"GBR": [
		{"slug": "northern_ireland", "name": "Nordirland", "lon": -7.00, "lat": 54.65},
	],
	"ESP": [
		{"slug": "balearics", "name": "Balearen", "lon": 2.90, "lat": 39.60},
		{"slug": "canaries", "name": "Kanaren", "lon": -16.00, "lat": 28.30},
	],
	"PRT": [
		{"slug": "azores", "name": "Azoren", "lon": -28.00, "lat": 38.50},
		{"slug": "madeira", "name": "Madeira", "lon": -17.00, "lat": 32.75},
	],
}


static func _from_entries(entries: Array) -> Array[Dictionary]:
	var seeds: Array[Dictionary] = []
	for entry in entries:
		seeds.append({
			"slug": str(entry["slug"]),
			"name": str(entry["name"]),
			"position": GeoProjection.project(float(entry["lon"]), float(entry["lat"])),
			"is_exclave": true,
		})
	return seeds
