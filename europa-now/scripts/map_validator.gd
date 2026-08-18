class_name MapValidator
extends RefCounted


static func validate(
	countries: Array[Country],
	provinces: Array[Province],
	province_adjacency: ProvinceAdjacency
) -> MapValidationReport:
	var report: MapValidationReport = MapValidationReport.new()
	report.country_count = countries.size()
	report.province_count = provinces.size()

	var country_ids: Dictionary = {}
	var province_ids: Dictionary = {}
	var provinces_per_country: Dictionary = {}

	for country in countries:
		if country_ids.has(country.country_id):
			report.duplicate_country_ids.append(country.country_id)
		country_ids[country.country_id] = true
		provinces_per_country[country.country_id] = 0

	for province in provinces:
		if province_ids.has(province.province_id):
			report.duplicate_province_ids.append(province.province_id)
		province_ids[province.province_id] = true

		if province.owner_country_id.is_empty():
			report.provinces_without_owner.append(province.province_id)
		elif provinces_per_country.has(province.owner_country_id):
			provinces_per_country[province.owner_country_id] = int(provinces_per_country[province.owner_country_id]) + 1

		if province.owner_country_id.is_empty() or not country_ids.has(province.owner_country_id):
			report.warnings.append(
				"Provinz %s hat ungueltigen Owner %s" % [province.province_id, province.owner_country_id]
			)

	for country_id in provinces_per_country:
		if int(provinces_per_country[country_id]) == 0:
			report.countries_without_provinces.append(country_id)

	if province_adjacency != null:
		for province in provinces:
			for neighbor_id: String in province_adjacency.get_neighbors(province.province_id):
				if not province_ids.has(neighbor_id):
					report.warnings.append(
						"Nachbar %s von %s existiert nicht" % [neighbor_id, province.province_id]
					)

	return report


static func format_report(report: MapValidationReport) -> String:
	var lines: Array[String] = []
	lines.append("Laender: %d | Provinzen: %d" % [report.country_count, report.province_count])
	if not report.countries_without_provinces.is_empty():
		lines.append("Laender ohne Provinzen: %d" % report.countries_without_provinces.size())
	if not report.duplicate_country_ids.is_empty():
		lines.append("Doppelte Country-IDs: %s" % ", ".join(report.duplicate_country_ids))
	if not report.duplicate_province_ids.is_empty():
		lines.append("Doppelte Province-IDs: %s" % ", ".join(report.duplicate_province_ids))
	if not report.provinces_without_owner.is_empty():
		lines.append("Provinzen ohne Owner: %d" % report.provinces_without_owner.size())
	if not report.warnings.is_empty() and report.warnings.size() <= 5:
		for warning in report.warnings:
			lines.append(warning)
	elif report.warnings.size() > 5:
		lines.append("%d Validierungswarnungen" % report.warnings.size())
	return "\n".join(lines)
