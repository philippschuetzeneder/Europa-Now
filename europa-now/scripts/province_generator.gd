class_name ProvinceGenerator
extends RefCounted

const AUSTRIA_AREA_KM2 := 83879.0

const MEGA_COUNTRY_CAPS := {
	"RUS": 120,
	"USA": 85,
	"CHN": 85,
	"CAN": 75,
	"BRA": 65,
	"IND": 65,
	"AUS": 50,
	"IDN": 50,
	"KAZ": 45,
	"ARG": 40,
	"MEX": 40,
	"SAU": 35,
	"ZAF": 35,
	"IRN": 35,
	"TUR": 35,
	"COD": 35,
	"SDN": 30,
}

const STAN_STATE_IDS := ["AFG", "KAZ", "KGZ", "TJK", "TKM", "UZB"]

const HALF_DENSITY_COUNTRY_IDS := ["PAK", "OMN", "YEM"]

const SOUTHEAST_ASIA_IDS := [
	"THA", "VNM", "MMR", "KHM", "LAO", "MYS", "IDN", "PHL", "BRN", "TLS",
]

const THIRD_DENSITY_REGIONS := ["Central America", "Caribbean"]

const GLOBAL_CELL_SIZE := 0.36
const ADMIN_CELL_SIZE := 0.22


static func reference_area_from_countries(countries_data: Array[Dictionary]) -> float:
	for country_data in countries_data:
		if country_data["id"] == "AUT":
			var area_km2: float = float(country_data.get("area_km2", 0.0))
			if area_km2 > 0.0:
				return area_km2
			var rings: Array = country_data.get("rings", [])
			return _polygon_area(_largest_ring(rings))
	return AUSTRIA_AREA_KM2


static func generate_for_country(country_data: Dictionary, reference_area_km2: float) -> Array[Dictionary]:
	var country_id: String = country_data["id"]
	var rings: Array = country_data["rings"]
	if rings.is_empty():
		return []

	var area_km2: float = float(country_data.get("area_km2", 0.0))
	if area_km2 <= 0.0:
		area_km2 = _polygon_area(_largest_ring(rings))

	var target: int = _target_province_count(country_id, area_km2, reference_area_km2, country_data)
	var base_color: Color = country_data["color"]
	var seeds: Array[Dictionary] = _build_seeds(country_id, rings, target, country_data)
	if seeds.is_empty():
		return _fill_uncovered_country_rings([], rings, country_id, base_color)

	var provinces: Array[Dictionary] = []
	var subdivided: Array[Dictionary] = _subdivide(rings, seeds, target, country_id)
	for i in subdivided.size():
		var entry: Dictionary = subdivided[i]
		if entry["rings"].is_empty():
			continue
		var seed: Dictionary = seeds[entry["seed_index"]]
		var slug: String = str(seed.get("slug", "region_%02d" % (i + 1)))
		var province_name: String = str(seed.get("name", "%s %d" % [country_data["name"], i + 1]))
		var tint := 0.04 * float(i % 5) - 0.08
		provinces.append({
			"id": "%s_%s" % [country_id, slug],
			"name": province_name,
			"country_id": country_id,
			"owner_country_id": country_id,
			"controller_country_id": country_id,
			"center": entry["center"],
			"primary_city": province_name,
			"rings": entry["rings"],
			"color": base_color.lightened(tint),
		})

	return _fill_uncovered_country_rings(provinces, rings, country_id, base_color)


static func _target_province_count(
	country_id: String,
	area_km2: float,
	reference_area_km2: float,
	country_data: Dictionary
) -> int:
	if country_id == "AUT" or country_id == "DEU" or country_id == "USA":
		return AdminDivisionSeeds.division_count(country_id)

	if reference_area_km2 <= 0.0:
		reference_area_km2 = AUSTRIA_AREA_KM2

	var estimated: int = maxi(1, int(round(area_km2 / reference_area_km2 * 9.0)))
	var result: int = 1

	if area_km2 < 2500.0:
		result = clampi(estimated, 1, 3)
	elif area_km2 < reference_area_km2 * 0.35:
		result = clampi(estimated, 1, 5)
	elif area_km2 < reference_area_km2 * 1.8:
		result = clampi(estimated, 3, 12)
	elif area_km2 < reference_area_km2 * 6.0:
		result = clampi(estimated, 6, 28)
	elif area_km2 < reference_area_km2 * 20.0:
		result = clampi(estimated, 10, 45)
	else:
		result = clampi(estimated, 15, 80)
		if MEGA_COUNTRY_CAPS.has(country_id):
			result = mini(result, int(MEGA_COUNTRY_CAPS[country_id]))

	return _apply_density_adjustments(country_id, country_data, result)


static func _apply_density_adjustments(country_id: String, country_data: Dictionary, count: int) -> int:
	if country_id == "BEL" or country_id == "NLD":
		return maxi(1, int(round(float(count) * 2.0)))
	if country_id == "DNK":
		return maxi(1, int(round(float(count) * 1.5)))
	if country_id == "RUS":
		return count
	if _uses_half_density(country_data):
		return maxi(1, int(round(float(count) / 2.0)))
	if _uses_third_density(country_data):
		return maxi(1, int(round(float(count) / 3.0)))
	return count


static func _uses_half_density(country_data: Dictionary) -> bool:
	var country_id: String = str(country_data.get("id", ""))
	if country_id in HALF_DENSITY_COUNTRY_IDS:
		return true
	if country_id in SOUTHEAST_ASIA_IDS:
		return true
	return false


static func _uses_third_density(country_data: Dictionary) -> bool:
	if _uses_half_density(country_data):
		return false

	var country_id: String = str(country_data.get("id", ""))
	var continent: String = str(country_data.get("continent", ""))
	var region: String = str(country_data.get("region", ""))

	if continent == "Africa" or continent == "South America":
		return true
	if country_id in ["CAN", "MNG", "MEX"]:
		return true
	if region in THIRD_DENSITY_REGIONS:
		return true
	if country_id in STAN_STATE_IDS:
		return true
	return false


static func _build_seeds(country_id: String, rings: Array, target: int, country_data: Dictionary) -> Array[Dictionary]:
	if AdminDivisionSeeds.has_admin_divisions(country_id):
		return AdminDivisionSeeds.seeds_for_country(country_id)

	var seeds: Array[Dictionary] = []
	if country_id == "RUS":
		seeds = _russia_seeds(rings, target)
	elif target <= 1:
		var center: Vector2 = _polygon_centroid(_largest_ring(rings))
		seeds = [{
			"slug": "core",
			"name": "Kerngebiet",
			"position": center,
		}]
	else:
		seeds = _generate_auto_seeds(rings, target)

	return seeds


static func _russia_seeds(rings: Array, target: int) -> Array[Dictionary]:
	var ural_x: float = GeoProjection.project(60.0, 55.0).x
	var west_count: int = maxi(1, int(round(float(target) * 0.38)))
	var east_count: int = maxi(1, int(round(float(target) * 0.62 / 3.0)))
	return _generate_auto_seeds_split(rings, west_count, east_count, ural_x)


static func _generate_auto_seeds_split(
	rings: Array,
	west_count: int,
	east_count: int,
	split_x: float
) -> Array[Dictionary]:
	var west_seeds: Array[Dictionary] = _generate_auto_seeds_filtered(
		rings, west_count, func(point: Vector2) -> bool: return point.x < split_x, "west"
	)
	var east_seeds: Array[Dictionary] = _generate_auto_seeds_filtered(
		rings, east_count, func(point: Vector2) -> bool: return point.x >= split_x, "east"
	)
	if west_seeds.is_empty() and not east_seeds.is_empty():
		return east_seeds
	if east_seeds.is_empty() and not west_seeds.is_empty():
		return west_seeds
	return west_seeds + east_seeds


static func _generate_auto_seeds_filtered(
	rings: Array,
	count: int,
	filter: Callable,
	region_slug: String
) -> Array[Dictionary]:
	var main_ring: PackedVector2Array = _largest_ring(rings)
	var bounds: Rect2 = _ring_bounds(main_ring)
	var candidates: Array[Vector2] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(bounds.position) + str(count) + region_slug)
	var attempts: int = mini(2500, maxi(400, count * 120))

	for _attempt in attempts:
		var point := Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y)
		)
		if not _point_in_country(point, rings):
			continue
		if not filter.call(point):
			continue
		candidates.append(point)

	if candidates.is_empty():
		return []

	var chosen: Array[Vector2] = [candidates[rng.randi_range(0, candidates.size() - 1)]]
	while chosen.size() < count and chosen.size() < candidates.size():
		var best_point := candidates[0]
		var best_score := -1.0
		for candidate in candidates:
			var nearest := INF
			for existing in chosen:
				nearest = minf(nearest, candidate.distance_squared_to(existing))
			if nearest > best_score:
				best_score = nearest
				best_point = candidate
		if best_point in chosen:
			break
		chosen.append(best_point)

	var seeds: Array[Dictionary] = []
	for i in chosen.size():
		seeds.append({
			"slug": "%s_%02d" % [region_slug, i + 1],
			"name": "Region %d" % (i + 1),
			"position": chosen[i],
		})
	return seeds


static func _generate_auto_seeds(rings: Array, count: int) -> Array[Dictionary]:
	var main_ring: PackedVector2Array = _largest_ring(rings)
	var bounds: Rect2 = _ring_bounds(main_ring)
	var candidates: Array[Vector2] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(bounds.position) + str(count))
	var attempts: int = mini(2500, maxi(400, count * 120))

	for _attempt in attempts:
		var point := Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y)
		)
		if _point_in_country(point, rings):
			candidates.append(point)

	if candidates.is_empty():
		return [{
			"slug": "core",
			"name": "Kerngebiet",
			"position": _polygon_centroid(main_ring),
		}]

	var chosen: Array[Vector2] = [candidates[rng.randi_range(0, candidates.size() - 1)]]
	while chosen.size() < count and chosen.size() < candidates.size():
		var best_point := candidates[0]
		var best_score := -1.0
		for candidate in candidates:
			var nearest := INF
			for existing in chosen:
				nearest = minf(nearest, candidate.distance_squared_to(existing))
			if nearest > best_score:
				best_score = nearest
				best_point = candidate
		if best_point in chosen:
			break
		chosen.append(best_point)

	var seeds: Array[Dictionary] = []
	for i in chosen.size():
		seeds.append({
			"slug": "region_%02d" % (i + 1),
			"name": "Region %d" % (i + 1),
			"position": chosen[i],
		})
	return seeds


static func finalize_rings(
	source_rings: Array,
	country_rings: Array,
	simplify_tolerance: float,
	snap_to_border: bool = false
) -> Array:
	var clipped: Array = _clip_rings_to_country(source_rings, country_rings)
	if snap_to_border and simplify_tolerance > 0.0:
		var snapped: Array = []
		for ring in clipped:
			if ring is PackedVector2Array:
				snapped.append(
					_snap_ring_to_country_border(ring, country_rings, simplify_tolerance * 2.5)
				)
		clipped = snapped
	if simplify_tolerance > 0.0:
		return _simplify_rings(clipped, simplify_tolerance)
	return clipped


static func clip_to_country(source_rings: Array, country_rings: Array) -> Array:
	return _clip_rings_to_country(source_rings, country_rings)


static func _subdivide(
	rings: Array,
	seeds: Array[Dictionary],
	target: int,
	country_id: String
) -> Array[Dictionary]:
	var main_ring: PackedVector2Array = _largest_ring(rings)
	var bounds: Rect2 = _ring_bounds(main_ring)
	var cell_size: float = ADMIN_CELL_SIZE if AdminDivisionSeeds.has_admin_divisions(country_id) else GLOBAL_CELL_SIZE
	if target >= 40 and not AdminDivisionSeeds.has_admin_divisions(country_id):
		cell_size = GLOBAL_CELL_SIZE * 0.92
	elif target <= 6:
		cell_size = GLOBAL_CELL_SIZE * 1.15

	var cell_w: float = cell_size
	var cell_h: float = cell_size
	if cell_w <= 0.0 or cell_h <= 0.0 or bounds.size == Vector2.ZERO:
		return []

	var grid_origin := Vector2(
		floor(bounds.position.x / cell_w) * cell_w,
		floor(bounds.position.y / cell_h) * cell_h
	)
	var span_x: float = bounds.end.x - grid_origin.x
	var span_y: float = bounds.end.y - grid_origin.y
	var raw_x: float = span_x / cell_w
	var raw_y: float = span_y / cell_h
	var max_dim: float = maxf(raw_x, raw_y)
	if max_dim > 72.0:
		var scale: float = max_dim / 72.0
		cell_w *= scale
		cell_h *= scale
	var grid_size_x: int = clampi(maxi(1, int(ceil(span_x / cell_w))), 12, 72)
	var grid_size_y: int = clampi(maxi(1, int(ceil(span_y / cell_h))), 12, 72)

	var labels: Array = []
	labels.resize(grid_size_y)
	for gy in grid_size_y:
		labels[gy] = []
		labels[gy].resize(grid_size_x)
		for gx in grid_size_x:
			var x0: float = grid_origin.x + float(gx) * cell_w
			var y0: float = grid_origin.y + float(gy) * cell_h
			var x1: float = x0 + cell_w
			var y1: float = y0 + cell_h
			var point := Vector2(
				(x0 + x1) * 0.5,
				(y0 + y1) * 0.5
			)
			if not _point_in_country(point, rings):
				var inside_corners := 0
				var corner_sum := Vector2.ZERO
				for corner in [
					Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1),
					Vector2((x0 + x1) * 0.5, y0), Vector2(x1, (y0 + y1) * 0.5),
					Vector2((x0 + x1) * 0.5, y1), Vector2(x0, (y0 + y1) * 0.5),
				]:
					if _point_in_country(corner, rings):
						inside_corners += 1
						corner_sum += corner
				if inside_corners < 1:
					labels[gy][gx] = -1
					continue
				point = corner_sum / float(inside_corners)
			var best_index := 0
			var best_distance := INF
			for i in seeds.size():
				var seed_position: Vector2 = seeds[i]["position"]
				var distance := point.distance_squared_to(seed_position)
				if distance < best_distance:
					best_distance = distance
					best_index = i
			labels[gy][gx] = best_index

	_fill_grid_gaps(labels, grid_size_x, grid_size_y, cell_w, cell_h, grid_origin, rings, seeds)

	var result: Array[Dictionary] = []
	for seed_index in seeds.size():
		var province_rings: Array = _rings_from_grid(
			labels, grid_size_x, grid_size_y, cell_w, cell_h, grid_origin, seed_index, rings
		)
		var center: Vector2 = seeds[seed_index]["position"]
		if not province_rings.is_empty():
			center = _polygon_centroid(_largest_ring_from_array(province_rings))
		result.append({
			"seed_index": seed_index,
			"center": center,
			"rings": province_rings,
		})

	return result


static func _fill_grid_gaps(
	labels: Array,
	grid_size_x: int,
	grid_size_y: int,
	cell_w: float,
	cell_h: float,
	origin: Vector2,
	rings: Array,
	seeds: Array[Dictionary]
) -> void:
	for _pass in 8:
		var changed := false
		for gy in grid_size_y:
			for gx in grid_size_x:
				if labels[gy][gx] != -1:
					continue

				var x0: float = origin.x + float(gx) * cell_w
				var y0: float = origin.y + float(gy) * cell_h
				var point := Vector2(
					(x0 + x0 + cell_w) * 0.5,
					(y0 + y0 + cell_h) * 0.5
				)
				if not _point_in_country(point, rings):
					continue

				var neighbor_label := -1
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var ny: int = gy + dy
						var nx: int = gx + dx
						if ny < 0 or ny >= grid_size_y or nx < 0 or nx >= grid_size_x:
							continue
						var label_value: int = labels[ny][nx]
						if label_value != -1:
							neighbor_label = label_value
							break
					if neighbor_label != -1:
						break

				if neighbor_label != -1:
					labels[gy][gx] = neighbor_label
					changed = true
					continue

				var best_index := 0
				var best_distance := INF
				for i in seeds.size():
					var seed_position: Vector2 = seeds[i]["position"]
					var distance := point.distance_squared_to(seed_position)
					if distance < best_distance:
						best_distance = distance
						best_index = i
				labels[gy][gx] = best_index
				changed = true

		if not changed:
			break


static func _rings_from_grid(
	labels: Array,
	grid_size_x: int,
	grid_size_y: int,
	cell_w: float,
	cell_h: float,
	origin: Vector2,
	province_index: int,
	country_rings: Array
) -> Array:
	var segments: Array = []

	for gy in grid_size_y:
		for gx in grid_size_x:
			if labels[gy][gx] != province_index:
				continue

			var x0: float = origin.x + float(gx) * cell_w
			var y0: float = origin.y + float(gy) * cell_h
			var x1: float = x0 + cell_w
			var y1: float = y0 + cell_h

			if gy == 0 or labels[gy - 1][gx] != province_index:
				segments.append([Vector2(x0, y0), Vector2(x1, y0)])
			if gy == grid_size_y - 1 or labels[gy + 1][gx] != province_index:
				segments.append([Vector2(x0, y1), Vector2(x1, y1)])
			if gx == 0 or labels[gy][gx - 1] != province_index:
				segments.append([Vector2(x0, y0), Vector2(x0, y1)])
			if gx == grid_size_x - 1 or labels[gy][gx + 1] != province_index:
				segments.append([Vector2(x1, y0), Vector2(x1, y1)])

	var loops: Array = _segments_to_polygons(segments)
	var merged: Array = []
	for loop in loops:
		if loop is PackedVector2Array and loop.size() >= 3:
			var centroid: Vector2 = _polygon_centroid(loop)
			if _point_in_country(centroid, country_rings):
				merged.append(loop)

	var tolerance: float = minf(cell_w, cell_h) * 0.07
	if tolerance < 0.03:
		return clip_to_country(merged, country_rings)
	return finalize_rings(merged, country_rings, tolerance, false)


static func _segments_to_polygons(segments: Array) -> Array:
	var remaining: Array = segments.duplicate()
	var polygons: Array = []
	var epsilon := 0.05

	while not remaining.is_empty():
		var chain: Array = [remaining[0][0], remaining[0][1]]
		remaining.remove_at(0)
		var extended := true

		while extended:
			extended = false
			for i in range(remaining.size() - 1, -1, -1):
				var segment: Array = remaining[i]
				if segment[0].distance_to(chain[0]) < epsilon:
					chain.insert(0, segment[1])
					remaining.remove_at(i)
					extended = true
				elif segment[1].distance_to(chain[0]) < epsilon:
					chain.insert(0, segment[0])
					remaining.remove_at(i)
					extended = true
				elif segment[0].distance_to(chain[-1]) < epsilon:
					chain.append(segment[1])
					remaining.remove_at(i)
					extended = true
				elif segment[1].distance_to(chain[-1]) < epsilon:
					chain.append(segment[0])
					remaining.remove_at(i)
					extended = true

		if chain.size() >= 3:
			var packed := PackedVector2Array()
			for point in chain:
				packed.append(point)
			polygons.append(packed)

	return polygons


static func _clip_rings_to_country(source_rings: Array, country_rings: Array) -> Array:
	var result: Array = []
	const MIN_AREA := 0.2

	for source in source_rings:
		if source is not PackedVector2Array or source.size() < 3:
			continue
		for country_ring in country_rings:
			if country_ring is not PackedVector2Array or country_ring.size() < 3:
				continue
			var intersections: Array = Geometry2D.intersect_polygons(source, country_ring)
			for poly in intersections:
				if poly is PackedVector2Array and poly.size() >= 3 and _polygon_area(poly) >= MIN_AREA:
					result.append(poly)

	if result.size() > 24:
		result.sort_custom(func(a: PackedVector2Array, b: PackedVector2Array) -> bool:
			return _polygon_area(a) > _polygon_area(b)
		)
		result = result.slice(0, 24)

	return result


static func _simplify_rings(rings: Array, tolerance: float) -> Array:
	if tolerance <= 0.0:
		return rings
	var result: Array = []
	for ring in rings:
		if ring is not PackedVector2Array or ring.size() < 3:
			continue
		var simplified: PackedVector2Array = _douglas_peucker_ring(ring, tolerance)
		if simplified.size() >= 3:
			result.append(simplified)
	return result


static func _douglas_peucker_ring(points: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	if points.size() < 4:
		return points

	var closed := PackedVector2Array()
	for point in points:
		closed.append(point)
	closed.append(points[0])

	var simplified: PackedVector2Array = _douglas_peucker_open(closed, tolerance)
	if simplified.size() >= 2 and simplified[0].distance_to(simplified[-1]) <= tolerance:
		simplified.resize(simplified.size() - 1)
	return simplified


static func _douglas_peucker_open(points: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	if points.size() < 3:
		return points

	var max_distance := 0.0
	var index := 0
	var start: Vector2 = points[0]
	var end: Vector2 = points[points.size() - 1]

	for i in range(1, points.size() - 1):
		var distance: float = _point_line_distance(points[i], start, end)
		if distance > max_distance:
			max_distance = distance
			index = i

	if max_distance <= tolerance:
		var result := PackedVector2Array()
		result.append(start)
		result.append(end)
		return result

	var left: PackedVector2Array = _douglas_peucker_open(points.slice(0, index + 1), tolerance)
	var right: PackedVector2Array = _douglas_peucker_open(points.slice(index, points.size()), tolerance)
	var merged := PackedVector2Array()
	for i in left.size() - 1:
		merged.append(left[i])
	for i in right.size():
		merged.append(right[i])
	return merged


static func _point_line_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var line_length: float = start.distance_to(end)
	if line_length <= 0.0001:
		return point.distance_to(start)
	return abs((end - start).cross(point - start)) / line_length


static func _snap_ring_to_country_border(
	ring: PackedVector2Array,
	country_rings: Array,
	max_distance: float
) -> PackedVector2Array:
	if ring.size() < 3 or max_distance <= 0.0:
		return ring

	var snapped := PackedVector2Array()
	snapped.resize(ring.size())
	for i in ring.size():
		snapped[i] = _snap_point_to_country_border(ring[i], country_rings, max_distance)
	return snapped


static func _snap_point_to_country_border(
	point: Vector2,
	country_rings: Array,
	max_distance: float
) -> Vector2:
	var best := point
	var best_distance := max_distance

	for country_ring in country_rings:
		if country_ring is not PackedVector2Array or country_ring.size() < 2:
			continue
		for i in country_ring.size():
			var start: Vector2 = country_ring[i]
			var end: Vector2 = country_ring[(i + 1) % country_ring.size()]
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, start, end)
			var distance: float = point.distance_to(closest)
			if distance < best_distance:
				best_distance = distance
				best = closest

	return best


static func _largest_ring_from_array(ring_array: Array) -> PackedVector2Array:
	var best: PackedVector2Array = PackedVector2Array()
	var best_area := 0.0
	for ring in ring_array:
		if ring is not PackedVector2Array:
			continue
		var area := _polygon_area(ring)
		if area > best_area:
			best_area = area
			best = ring
	return best


static func _largest_ring(rings: Array) -> PackedVector2Array:
	var best: PackedVector2Array = PackedVector2Array()
	var best_size := 0
	for ring in rings:
		if ring is PackedVector2Array and ring.size() > best_size:
			best_size = ring.size()
			best = ring
	return best


static func _ring_bounds(ring: PackedVector2Array) -> Rect2:
	if ring.is_empty():
		return Rect2()
	var bounds := Rect2(ring[0], Vector2.ZERO)
	for point in ring:
		bounds = bounds.expand(point)
	return bounds


static func _polygon_centroid(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())


static func _polygon_area(points: PackedVector2Array) -> float:
	if points.size() < 3:
		return 0.0
	var area := 0.0
	for i in points.size():
		var j: int = (i + 1) % points.size()
		area += points[i].x * points[j].y
		area -= points[j].x * points[i].y
	return abs(area) * 0.5


static func ensure_full_country_coverage(
	provinces: Array[Dictionary],
	country_data: Dictionary
) -> Array[Dictionary]:
	return _fill_uncovered_country_rings(
		provinces,
		country_data.get("rings", []),
		str(country_data.get("id", "")),
		country_data.get("color", Color.WHITE)
	)


static func _rings_bounds(rings: Array) -> Rect2:
	var bounds := Rect2()
	for ring in rings:
		if ring is not PackedVector2Array:
			continue
		for point in ring:
			if bounds.size == Vector2.ZERO:
				bounds = Rect2(point, Vector2.ZERO)
			else:
				bounds = bounds.expand(point)
	return bounds


static func _generate_exclave_provinces(
	country_rings: Array,
	country_id: String,
	base_color: Color
) -> Array[Dictionary]:
	var provinces: Array[Dictionary] = []
	for exclave in ExclaveSeeds.seeds_for_country(country_id):
		var seed_position: Vector2 = exclave["position"]
		if not _point_in_country(seed_position, country_rings):
			continue

		var region_rings: Array = _rings_containing_point(country_rings, seed_position)
		if region_rings.is_empty():
			continue
		if _point_in_province_data(seed_position, provinces):
			continue

		var province_id: String = "%s_%s" % [country_id, exclave["slug"]]
		if _province_id_exists(provinces, province_id):
			continue

		provinces.append({
			"id": province_id,
			"name": str(exclave["name"]),
			"country_id": country_id,
			"owner_country_id": country_id,
			"controller_country_id": country_id,
			"center": _polygon_centroid(_largest_ring_from_array(region_rings)),
			"primary_city": str(exclave["name"]),
			"rings": region_rings,
			"color": base_color.lightened(0.05),
		})
	return provinces


static func _rings_containing_point(country_rings: Array, point: Vector2) -> Array:
	for ring in country_rings:
		if ring is PackedVector2Array and ring.size() >= 3:
			if Geometry2D.is_point_in_polygon(point, ring):
				return clip_to_country([ring], country_rings)
	return []


static func _fill_uncovered_country_rings(
	provinces: Array[Dictionary],
	country_rings: Array,
	country_id: String,
	base_color: Color
) -> Array[Dictionary]:
	if country_rings.is_empty():
		return provinces

	const MIN_RING_AREA := 1.0
	var island_index := 0
	for ring in country_rings:
		if ring is not PackedVector2Array or ring.size() < 3:
			continue
		if _polygon_area(ring) < MIN_RING_AREA:
			continue

		var centroid: Vector2 = _polygon_centroid(ring)
		var coverage: float = _ring_coverage_ratio(ring, provinces)
		if coverage >= 0.80:
			continue

		var exclave_name: String = ExclaveSeeds.name_for_point(country_id, centroid, 22.0)
		var clipped: Array = clip_to_country([ring], country_rings)
		if clipped.is_empty():
			continue

		if not exclave_name.is_empty() and _append_rings_to_named_province(provinces, exclave_name, clipped):
			continue

		island_index += 1
		var display_name: String = exclave_name if not exclave_name.is_empty() else "Region %d" % island_index
		var slug: String = _slugify(display_name if not exclave_name.is_empty() else "region_%02d" % island_index)
		var province_id: String = "%s_%s" % [country_id, slug]
		var suffix := 2
		while _province_id_exists(provinces, province_id):
			province_id = "%s_%s_%d" % [country_id, slug, suffix]
			suffix += 1

		provinces.append({
			"id": province_id,
			"name": display_name,
			"country_id": country_id,
			"owner_country_id": country_id,
			"controller_country_id": country_id,
			"center": _polygon_centroid(_largest_ring_from_array(clipped)),
			"primary_city": display_name,
			"rings": clipped,
			"color": base_color.lightened(0.04 * float(island_index % 5)),
		})

	return provinces


static func _ring_coverage_ratio(ring: PackedVector2Array, provinces: Array[Dictionary]) -> float:
	var bounds: Rect2 = _ring_bounds(ring)
	if bounds.size == Vector2.ZERO:
		return 0.0

	var samples := 0
	var covered := 0
	for sx in 4:
		for sy in 4:
			var sample_point := Vector2(
				bounds.position.x + bounds.size.x * (float(sx) + 0.5) / 4.0,
				bounds.position.y + bounds.size.y * (float(sy) + 0.5) / 4.0
			)
			if not Geometry2D.is_point_in_polygon(sample_point, ring):
				continue
			samples += 1
			if _point_in_province_data(sample_point, provinces):
				covered += 1
	if samples == 0:
		return 0.0
	return float(covered) / float(samples)


static func _append_rings_to_named_province(
	provinces: Array[Dictionary],
	province_name: String,
	rings: Array
) -> bool:
	for province_data in provinces:
		if str(province_data.get("name", "")) != province_name:
			continue
		var existing_rings: Array = province_data.get("rings", [])
		existing_rings.append_array(rings)
		province_data["rings"] = existing_rings
		return true
	return false


static func _slugify(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("ü", "ue").replace("ä", "ae").replace("ö", "oe")


static func _province_id_exists(provinces: Array[Dictionary], province_id: String) -> bool:
	for province_data in provinces:
		if str(province_data.get("id", "")) == province_id:
			return true
	return false


static func _point_in_province_data(point: Vector2, provinces: Array[Dictionary]) -> bool:
	for province_data in provinces:
		for ring in province_data.get("rings", []):
			if ring is PackedVector2Array and Geometry2D.is_point_in_polygon(point, ring):
				return true
	return false


static func _point_in_country(point: Vector2, rings: Array) -> bool:
	for ring in rings:
		if ring is PackedVector2Array and Geometry2D.is_point_in_polygon(point, ring):
			return true
	return false
