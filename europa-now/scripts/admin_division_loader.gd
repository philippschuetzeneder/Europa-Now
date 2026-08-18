class_name AdminDivisionLoader
extends RefCounted

const COUNTRY_PATHS := {
	"USA": "res://data/admin_1_deu_aut_usa.geojson",
	"DEU": "res://data/admin_deu_bundeslaender.geojson",
	"AUT": "res://data/admin_aut_bundeslaender.geojson",
}

const ADMIN1_FALLBACK_PATH := "res://data/ne_110m_admin_1_states_provinces.geojson"

const ADMIN1_COUNTRIES := ["USA", "DEU", "AUT"]

const AUT_ISO_TO_SLUG := {
	"1": "burgenland",
	"2": "kaernten",
	"3": "niederoesterreich",
	"4": "oberoesterreich",
	"5": "salzburg",
	"6": "steiermark",
	"7": "tirol",
	"8": "vorarlberg",
	"9": "wien",
}


static func can_load(country_id: String) -> bool:
	return country_id in ADMIN1_COUNTRIES


static func load_provinces(country_data: Dictionary) -> Array[Dictionary]:
	var country_id: String = country_data["id"]
	if not can_load(country_id):
		return []

	var parsed: Variant = _load_geojson(country_id)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return []

	var base_color: Color = country_data["color"]
	var country_rings: Array = country_data.get("rings", [])
	var provinces: Array[Dictionary] = []
	var features: Array = parsed.get("features", [])

	for feature in features:
		if typeof(feature) != TYPE_DICTIONARY:
			continue
		var properties: Dictionary = feature.get("properties", {})
		if country_id == "USA" and str(properties.get("adm0_a3", "")) != country_id:
			continue

		var geometry: Dictionary = feature.get("geometry", {})
		var rings: Array = _extract_rings(geometry)
		if rings.is_empty():
			continue

		var slug: String = _slug_from_properties(country_id, properties)
		var name: String = _display_name(country_id, slug, properties)
		var clipped: Array = ProvinceGenerator.clip_to_country(rings, country_rings)
		if clipped.is_empty():
			continue

		provinces.append({
			"id": "%s_%s" % [country_id, slug],
			"name": name,
			"country_id": country_id,
			"owner_country_id": country_id,
			"controller_country_id": country_id,
			"center": _rings_center(clipped),
			"primary_city": name,
			"rings": clipped,
			"color": base_color,
		})

	return provinces


static func _load_geojson(country_id: String) -> Variant:
	var path: String = str(COUNTRY_PATHS.get(country_id, ""))
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null and country_id == "USA":
		file = FileAccess.open(ADMIN1_FALLBACK_PATH, FileAccess.READ)
	if file == null:
		push_warning("Admin division GeoJSON missing for %s" % country_id)
		return null
	return JSON.parse_string(file.get_as_text())


static func _display_name(country_id: String, slug: String, properties: Dictionary) -> String:
	if AdminDivisionSeeds.has_admin_divisions(country_id):
		for seed in AdminDivisionSeeds.seeds_for_country(country_id):
			if str(seed.get("slug", "")) == slug:
				return str(seed.get("name", properties.get("name", slug)))
	return str(properties.get("name", slug))


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


static func _slug_from_properties(country_id: String, properties: Dictionary) -> String:
	if country_id == "DEU":
		var de_id := str(properties.get("id", ""))
		if de_id.contains("-"):
			return de_id.split("-")[1].to_lower()
	if country_id == "AUT":
		var iso := str(properties.get("iso", ""))
		if AUT_ISO_TO_SLUG.has(iso):
			return AUT_ISO_TO_SLUG[iso]
	if country_id == "USA":
		var postal := str(properties.get("postal", ""))
		if not postal.is_empty() and postal != "-99":
			return postal.to_lower().replace(".", "_")
		var code := str(properties.get("iso_3166_2", ""))
		if code.contains("-"):
			return code.split("-")[1].to_lower()
	var name := str(properties.get("name", "region"))
	return name.to_lower().replace(" ", "_").replace(".", "")


static func _rings_center(rings: Array) -> Vector2:
	var best: PackedVector2Array = PackedVector2Array()
	var best_size := 0
	for ring in rings:
		if ring is PackedVector2Array and ring.size() > best_size:
			best_size = ring.size()
			best = ring
	if best.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point in best:
		sum += point
	return sum / float(best.size())
