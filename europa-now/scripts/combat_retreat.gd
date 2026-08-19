class_name CombatRetreat
extends RefCounted

const RETREAT_DAYS := 2


static func find_retreat_province(
	unit_data: UnitData,
	current_province_id: String,
	adjacency: ProvinceAdjacency,
	provinces_by_id: Dictionary
) -> String:
	var neighbors: Array[String] = adjacency.get_neighbors(current_province_id)
	var owned_neighbors: Array[String] = []

	for neighbor_id in neighbors:
		if not provinces_by_id.has(neighbor_id):
			continue
		var province: Province = provinces_by_id[neighbor_id]
		if province.controller_country_id == unit_data.owner_country_id:
			owned_neighbors.append(neighbor_id)

	if not owned_neighbors.is_empty():
		return _pick_best_neighbor(owned_neighbors, provinces_by_id)

	var fallback_candidates: Array[String] = []
	for province_id in provinces_by_id:
		var province: Province = provinces_by_id[province_id]
		if str(province_id) == current_province_id:
			continue
		if province.controller_country_id == unit_data.owner_country_id:
			fallback_candidates.append(str(province_id))
	if fallback_candidates.is_empty():
		return ""
	return _pick_nearest_province(current_province_id, fallback_candidates, provinces_by_id)


static func _pick_best_neighbor(neighbor_ids: Array[String], provinces_by_id: Dictionary) -> String:
	if neighbor_ids.is_empty():
		return ""
	if neighbor_ids.size() == 1:
		return neighbor_ids[0]

	var best_id := neighbor_ids[0]
	var best_population := -1
	for neighbor_id in neighbor_ids:
		var province: Province = provinces_by_id[neighbor_id]
		var score := province.display_name.length()
		if province.primary_city.length() > 0:
			score += 10
		if score > best_population:
			best_population = score
			best_id = neighbor_id
	return best_id


static func _pick_nearest_province(
	current_province_id: String,
	candidate_ids: Array[String],
	provinces_by_id: Dictionary
) -> String:
	var current: Province = provinces_by_id.get(current_province_id)
	if current == null:
		return ""
	var best_id := ""
	var best_distance := INF
	for candidate_id in candidate_ids:
		var candidate: Province = provinces_by_id.get(candidate_id)
		if candidate == null:
			continue
		var distance: float = current.center.distance_squared_to(candidate.center)
		if distance < best_distance:
			best_distance = distance
			best_id = candidate_id
	return best_id
