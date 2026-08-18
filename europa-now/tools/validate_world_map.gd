extends SceneTree

## Headless validation for the global world map.
## Run: godot --headless --path . --script res://tools/validate_world_map.gd


func _init() -> void:
	var country_data := GeoJsonLoader.load_world_countries()
	var reference_area := ProvinceGenerator.reference_area_from_countries(country_data)

	var all_provinces: Array[Dictionary] = []
	var province_counts: Dictionary = {}

	for data in country_data:
		var generated := ProvinceGenerator.generate_for_country(data, reference_area)
		province_counts[data["id"]] = generated.size()
		for province_data in generated:
			all_provinces.append(province_data)

	var countries: Array[Country] = []
	for data in country_data:
		var country := Country.new()
		country.setup(data)
		countries.append(country)

	var provinces: Array[Province] = []
	for province_data in all_provinces:
		var province := Province.new()
		province.setup(province_data)
		provinces.append(province)

	var province_adjacency := ProvinceAdjacency.build(provinces)
	var report := MapValidator.validate(countries, provinces, province_adjacency)

	print("=== WORLD MAP VALIDATION ===")
	print("Countries: %d" % report.country_count)
	print("Provinces: %d" % report.province_count)
	print("Countries without provinces: %s" % str(report.countries_without_provinces))
	print("Duplicate country IDs: %s" % str(report.duplicate_country_ids))
	print("Duplicate province IDs: %s" % str(report.duplicate_province_ids))
	print("Provinces without owner: %d" % report.provinces_without_owner.size())
	print("Warnings: %d" % report.warnings.size())

	var top: Array = []
	for country_id in province_counts:
		top.append({"id": country_id, "count": province_counts[country_id]})
	top.sort_custom(func(a, b): return a["count"] > b["count"])
	print("Top provinces:")
	for i in mini(10, top.size()):
		print("  %s: %d" % [top[i]["id"], top[i]["count"]])

	var excluded_micro := [
		"MCO", "VAT", "SMR", "AND", "LIE", "MLT", "ATA",
	]
	var present_excluded: Array[String] = []
	for iso in excluded_micro:
		for data in country_data:
			if data["id"] == iso:
				present_excluded.append(iso)
	print("Excluded microstates still present: %s" % str(present_excluded))

	quit()
