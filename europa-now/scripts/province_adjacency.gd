class_name ProvinceAdjacency
extends RefCounted

const GRID_STEP := 0.28
const MIN_SHARED_BORDER_POINTS := 2

var _neighbors: Dictionary = {}


static func build(provinces: Array[Province]) -> ProvinceAdjacency:
	var adjacency := ProvinceAdjacency.new()
	var point_hits: Dictionary = {}

	for province in provinces:
		adjacency._neighbors[province.province_id] = []

		for segment in province.get_border_segments():
			for point in segment:
				var key := _point_key(point, GRID_STEP)
				if not point_hits.has(key):
					point_hits[key] = []
				var owners: Array = point_hits[key]
				if province.province_id not in owners:
					owners.append(province.province_id)

	var pair_counts: Dictionary = {}
	for owners: Array in point_hits.values():
		if owners.size() < 2:
			continue
		for i in owners.size():
			for j in range(i + 1, owners.size()):
				var pair_key := _pair_key(str(owners[i]), str(owners[j]))
				pair_counts[pair_key] = pair_counts.get(pair_key, 0) + 1

	for pair_key in pair_counts:
		if pair_counts[pair_key] >= MIN_SHARED_BORDER_POINTS:
			var parts: PackedStringArray = pair_key.split("|")
			adjacency._add_neighbor(parts[0], parts[1])

	return adjacency


func are_neighbors(province_a: String, province_b: String) -> bool:
	if province_a == province_b:
		return false
	var neighbors: Array = _neighbors.get(province_a, [])
	return province_b in neighbors


func get_neighbors(province_id: String) -> Array[String]:
	var result: Array[String] = []
	for neighbor in _neighbors.get(province_id, []):
		result.append(neighbor)
	return result


static func _point_key(point: Vector2, step: float) -> String:
	return "%d:%d" % [int(round(point.x / step)), int(round(point.y / step))]


static func _pair_key(a: String, b: String) -> String:
	if a < b:
		return "%s|%s" % [a, b]
	return "%s|%s" % [b, a]


func _add_neighbor(a: String, b: String) -> void:
	var list_a: Array = _neighbors[a]
	var list_b: Array = _neighbors[b]
	if b not in list_a:
		list_a.append(b)
	if a not in list_b:
		list_b.append(a)
