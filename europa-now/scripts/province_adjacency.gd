class_name ProvinceAdjacency
extends RefCounted

const SEGMENT_STEP := 0.12
const TOUCH_DISTANCE := 0.45

var _neighbors: Dictionary = {}
var _provinces_by_id: Dictionary = {}


static func build(provinces: Array[Province]) -> ProvinceAdjacency:
	var adjacency := ProvinceAdjacency.new()

	for province in provinces:
		adjacency._neighbors[province.province_id] = []
		adjacency._provinces_by_id[province.province_id] = province

	adjacency._build_from_segments(provinces)
	adjacency._build_from_touching(provinces)
	adjacency._build_cross_border_touching(provinces)
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


func _build_from_segments(provinces: Array[Province]) -> void:
	var segment_owners: Dictionary = {}

	for province in provinces:
		for segment in province.get_border_segments():
			if segment.size() < 2:
				continue
			var key: String = _segment_key(segment[0], segment[1])
			if key.is_empty():
				continue
			if not segment_owners.has(key):
				segment_owners[key] = []
			var owners: Array = segment_owners[key]
			if province.province_id not in owners:
				owners.append(province.province_id)

	for owners: Array in segment_owners.values():
		if owners.size() < 2:
			continue
		for i in owners.size():
			for j in range(i + 1, owners.size()):
				_add_neighbor(str(owners[i]), str(owners[j]))


func _build_from_touching(provinces: Array[Province]) -> void:
	const MAX_CENTER_DISTANCE := 55.0
	_build_touching_from_grid(provinces, MAX_CENTER_DISTANCE, TOUCH_DISTANCE, false)


func _build_cross_border_touching(provinces: Array[Province]) -> void:
	const MAX_CENTER_DISTANCE := 70.0
	const CROSS_BORDER_TOUCH := 1.5
	_build_touching_from_grid(provinces, MAX_CENTER_DISTANCE, CROSS_BORDER_TOUCH, true)


func _build_touching_from_grid(
	provinces: Array[Province],
	max_center_distance: float,
	touch_distance: float,
	cross_border_only: bool
) -> void:
	var cell_size := max_center_distance
	var grid: Dictionary = {}
	for index in provinces.size():
		var province: Province = provinces[index]
		var cell := Vector2i(
			floori(province.center.x / cell_size),
			floori(province.center.y / cell_size)
		)
		if not grid.has(cell):
			grid[cell] = []
		var bucket: Array = grid[cell]
		bucket.append(index)

	for i in provinces.size():
		var province_a: Province = provinces[i]
		var cell := Vector2i(
			floori(province_a.center.x / cell_size),
			floori(province_a.center.y / cell_size)
		)
		for cell_y in range(cell.y - 1, cell.y + 2):
			for cell_x in range(cell.x - 1, cell.x + 2):
				var candidates: Array = grid.get(Vector2i(cell_x, cell_y), [])
				for j in candidates:
					if j <= i:
						continue
					var province_b: Province = provinces[j]
					if cross_border_only:
						if province_a.country_id == province_b.country_id:
							continue
					elif province_a.country_id != province_b.country_id:
						continue
					if are_neighbors(province_a.province_id, province_b.province_id):
						continue
					if province_a.center.distance_to(province_b.center) > max_center_distance:
						continue
					if _polygons_touch(province_a, province_b, touch_distance):
						_add_neighbor(province_a.province_id, province_b.province_id)


func _polygons_touch(province_a: Province, province_b: Province, max_distance: float) -> bool:
	for segment_a in province_a.get_border_segments():
		if segment_a.size() < 2:
			continue
		for point in [segment_a[0], segment_a[1], (segment_a[0] + segment_a[1]) * 0.5]:
			if _point_near_province(point, province_b, max_distance):
				return true

	for segment_b in province_b.get_border_segments():
		if segment_b.size() < 2:
			continue
		for point in [segment_b[0], segment_b[1], (segment_b[0] + segment_b[1]) * 0.5]:
			if _point_near_province(point, province_a, max_distance):
				return true

	return false


func _point_near_province(point: Vector2, province: Province, max_distance: float) -> bool:
	for segment in province.get_border_segments():
		if segment.size() < 2:
			continue
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1])
		if point.distance_to(closest) <= max_distance:
			return true
	return false


static func _segment_key(a: Vector2, b: Vector2, step: float = SEGMENT_STEP) -> String:
	var qa := Vector2(round(a.x / step), round(a.y / step))
	var qb := Vector2(round(b.x / step), round(b.y / step))
	if qa == qb:
		return ""
	if qa.x < qb.x or (is_equal_approx(qa.x, qb.x) and qa.y < qb.y):
		return "%d:%d|%d:%d" % [int(qa.x), int(qa.y), int(qb.x), int(qb.y)]
	return "%d:%d|%d:%d" % [int(qb.x), int(qb.y), int(qa.x), int(qa.y)]


func _add_neighbor(a: String, b: String) -> void:
	var list_a: Array = _neighbors[a]
	var list_b: Array = _neighbors[b]
	if b not in list_a:
		list_a.append(b)
	if a not in list_b:
		list_b.append(a)
