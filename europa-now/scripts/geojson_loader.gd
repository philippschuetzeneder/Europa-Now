class_name GeoJsonLoader
extends RefCounted

const GEOJSON_PATH := "res://data/ne_110m_admin_0_countries.geojson"
const MIN_AREA_KM2 := 500.0

const EXCLUDED_ISO := {
	"ATA": true,  # Rendered as polar visual layer
	"GRL": true,  # Rendered as polar visual layer
	"ATF": true,  # French Southern Territories
	"NCL": true,  # New Caledonia
	"PRI": true,  # Puerto Rico
	"FLK": true,  # Falkland Islands
	"CYN": true,  # Northern Cyprus
	"SOL": true,  # Somaliland (not UN member)
}

const POLAR_VISUAL_ONLY := ["ATA", "GRL"]

const FORCE_INCLUDE_ISO := {
	"TWN": true,
	"KOS": true,
	"ISR": true,
	"PSX": true,
	"SAH": true,
}

const PLAYABLE_TYPES := {
	"Sovereign country": true,
	"Sovereignty": true,
	"Country": true,
	"Disputed": true,
	"Indeterminate": true,
}

const MAP_PALETTE: Array[Color] = [
	Color(0.82, 0.47, 0.42),
	Color(0.56, 0.74, 0.47),
	Color(0.47, 0.63, 0.80),
	Color(0.90, 0.78, 0.43),
	Color(0.73, 0.56, 0.74),
	Color(0.48, 0.78, 0.74),
	Color(0.93, 0.62, 0.47),
	Color(0.62, 0.62, 0.72),
	Color(0.78, 0.69, 0.53),
]


static func load_world_countries() -> Array[Dictionary]:
	var file := FileAccess.open(GEOJSON_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open GeoJSON: %s" % GEOJSON_PATH)
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid GeoJSON file.")
		return []

	var features: Array = parsed.get("features", [])
	var countries: Array[Dictionary] = []

	for feature in features:
		if typeof(feature) != TYPE_DICTIONARY:
			continue

		var properties: Dictionary = feature.get("properties", {})
		var geometry: Dictionary = feature.get("geometry", {})
		var area_km2: float = GeoArea.geometry_area_km2(geometry)
		if area_km2 <= 0.0:
			area_km2 = GeoArea.geometry_bbox_area_km2(geometry)

		if not _is_playable_country(properties, area_km2):
			continue

		var rings: Array = _extract_rings(geometry)
		if rings.is_empty():
			continue

		var iso: String = _resolve_iso(properties)

		countries.append(CountryMetadata.enrich_country_data({
			"id": iso,
			"name": str(properties.get("ADMIN", properties.get("NAME", iso))),
			"iso_a2": str(properties.get("ISO_A2", "")),
			"population": int(properties.get("POP_EST", 0)),
			"gdp_million": int(properties.get("GDP_MD", 0)),
			"continent": str(properties.get("CONTINENT", "")),
			"region": str(properties.get("REGION_UN", properties.get("SUBREGION", ""))),
			"economy": str(properties.get("ECONOMY", "")),
			"area_km2": area_km2,
			"label_lon": float(properties.get("LABEL_X", 0.0)),
			"label_lat": float(properties.get("LABEL_Y", 0.0)),
			"color": _color_for_properties(properties),
			"rings": rings,
		}))

	countries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["name"] < b["name"]
	)
	return countries


static func load_polar_regions() -> Array[Dictionary]:
	var file := FileAccess.open(GEOJSON_PATH, FileAccess.READ)
	if file == null:
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return []

	var features: Array = parsed.get("features", [])
	var regions: Array[Dictionary] = []

	for feature in features:
		if typeof(feature) != TYPE_DICTIONARY:
			continue

		var properties: Dictionary = feature.get("properties", {})
		var iso: String = _resolve_iso(properties)
		if iso not in POLAR_VISUAL_ONLY:
			continue

		var geometry: Dictionary = feature.get("geometry", {})
		var rings: Array = _extract_rings(geometry)
		if rings.is_empty():
			continue

		regions.append({
			"id": iso,
			"name": str(properties.get("ADMIN", iso)),
			"rings": rings,
		})

	return regions


static func load_european_countries() -> Array[Dictionary]:
	return load_world_countries()


static func _resolve_iso(properties: Dictionary) -> String:
	var iso := str(properties.get("ADM0_A3", properties.get("ISO_A3", "")))
	if iso == "-99" or iso.is_empty():
		iso = str(properties.get("BRK_A3", "UNK"))
	return iso


static func _is_playable_country(properties: Dictionary, area_km2: float) -> bool:
	var iso := _resolve_iso(properties)
	if EXCLUDED_ISO.has(iso):
		return false
	if FORCE_INCLUDE_ISO.has(iso):
		return area_km2 >= MIN_AREA_KM2
	if area_km2 < MIN_AREA_KM2:
		return false

	var country_type := str(properties.get("TYPE", ""))
	if not PLAYABLE_TYPES.has(country_type):
		return false

	if country_type == "Indeterminate" and not FORCE_INCLUDE_ISO.has(iso):
		return false

	return true


static func _extract_rings(geometry: Dictionary) -> Array:
	var geometry_type := str(geometry.get("type", ""))
	var coordinates: Array = geometry.get("coordinates", [])
	var rings: Array = []

	match geometry_type:
		"Polygon":
			if not coordinates.is_empty():
				rings.append(GeoProjection.project_ring(coordinates[0]))
		"MultiPolygon":
			for polygon in coordinates:
				if polygon is Array and not polygon.is_empty():
					rings.append(GeoProjection.project_ring(polygon[0]))

	return rings


static func _color_for_properties(properties: Dictionary) -> Color:
	var map_color := int(properties.get("MAPCOLOR9", 1))
	if map_color < 1 or map_color > MAP_PALETTE.size():
		map_color = 1
	return MAP_PALETTE[map_color - 1]
