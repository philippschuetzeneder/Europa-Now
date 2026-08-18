class_name ProvinceGenerator
extends RefCounted

const MICROSTATES := ["MCO", "VAT", "SMR", "AND", "LIE", "MLT"]

const AUSTRIA_SEEDS: Array[Dictionary] = [
	{"slug": "wien", "name": "Wien", "lon": 16.37, "lat": 48.21},
	{"slug": "niederoesterreich", "name": "Niederoesterreich", "lon": 15.55, "lat": 48.30},
	{"slug": "oberoesterreich", "name": "Oberoesterreich", "lon": 14.10, "lat": 48.20},
	{"slug": "steiermark", "name": "Steiermark", "lon": 15.20, "lat": 47.35},
	{"slug": "kaernten", "name": "Kaernten", "lon": 14.10, "lat": 46.75},
	{"slug": "salzburg", "name": "Salzburg", "lon": 13.05, "lat": 47.70},
	{"slug": "tirol", "name": "Tirol", "lon": 11.40, "lat": 47.10},
	{"slug": "vorarlberg", "name": "Vorarlberg", "lon": 9.90, "lat": 47.20},
	{"slug": "burgenland", "name": "Burgenland", "lon": 16.45, "lat": 47.55},
]


static func reference_area_from_countries(countries_data: Array[Dictionary]) -> float:
	for country_data in countries_data:
		if country_data["id"] == "AUT":
			return _polygon_area(_largest_ring(country_data["rings"]))
	return 1.0


static func generate_for_country(country_data: Dictionary, reference_area: float) -> Array[Dictionary]:
	var country_id: String = country_data["id"]
	var rings: Array = country_data["rings"]
	if rings.is_empty():
		return []

	var area := _polygon_area(_largest_ring(rings))
	var target := _target_province_count(country_id, area, reference_area)
	var base_color: Color = country_data["color"]
	var seeds := _build_seeds(country_id, rings, target)

	if seeds.is_empty():
		return []

	var subdivided := _subdivide(rings, seeds)
	var provinces: Array[Dictionary] = []

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
			"center": entry["center"],
			"primary_city": province_name,
			"rings": entry["rings"],
			"color": base_color.lightened(tint),
		})

	return provinces


static func _target_province_count(country_id: String, area: float, reference_area: float) -> int:
	if country_id == "AUT":
		return 9
	if country_id in MICROSTATES:
		return 1

	if reference_area <= 0.0:
		reference_area = 1.0

	var estimated := maxi(1, int(round(area / reference_area * 9.0)))

	if area < reference_area * 0.35:
		return clampi(estimated, 1, 5)
	if area < reference_area * 1.8:
		return clampi(estimated, 3, 12)
	if area < reference_area * 6.0:
		return clampi(estimated, 6, 28)
	if area < reference_area * 20.0:
		return clampi(estimated, 10, 45)
	return clampi(estimated, 15, 80)


static func _build_seeds(country_id: String, rings: Array, target: int) -> Array[Dictionary]:
	if country_id == "AUT":
		return _austria_seeds()

	if target <= 1:
		var center := _polygon_centroid(_largest_ring(rings))
		return [{
			"slug": "core",
			"name": "Kerngebiet",
			"position": center,
		}]

	return _generate_auto_seeds(rings, target)


static func _austria_seeds() -> Array[Dictionary]:
	var seeds: Array[Dictionary] = []
	for entry in AUSTRIA_SEEDS:
		seeds.append({
			"slug": entry["slug"],
			"name": entry["name"],
			"position": GeoProjection.project(entry["lon"], entry["lat"]),
		})
	return seeds


static func _generate_auto_seeds(rings: Array, count: int) -> Array[Dictionary]:
	var main_ring := _largest_ring(rings)
	var bounds := _ring_bounds(main_ring)
	var candidates: Array[Vector2] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(bounds.position) + str(count))

	for _attempt in 5000:
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


static func _subdivide(rings: Array, seeds: Array[Dictionary]) -> Array[Dictionary]:
	var main_ring := _largest_ring(rings)
	var bounds := _ring_bounds(main_ring)
	var grid_size := clampi(int(sqrt(seeds.size()) * 26.0), 36, 96)
	var cell_w := bounds.size.x / float(grid_size)
	var cell_h := bounds.size.y / float(grid_size)
	if cell_w <= 0.0 or cell_h <= 0.0:
		return []

	var labels: Array = []
	labels.resize(grid_size)
	for gy in grid_size:
		labels[gy] = []
		labels[gy].resize(grid_size)
		for gx in grid_size:
			var point := Vector2(
				bounds.position.x + (float(gx) + 0.5) * cell_w,
				bounds.position.y + (float(gy) + 0.5) * cell_h
			)
			if not _point_in_country(point, rings):
				labels[gy][gx] = -1
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

	var result: Array[Dictionary] = []
	for seed_index in seeds.size():
		var province_rings := _rings_from_grid(labels, grid_size, cell_w, cell_h, bounds.position, seed_index, rings)
		var center: Vector2 = seeds[seed_index]["position"]
		if not province_rings.is_empty():
			center = _polygon_centroid(province_rings[0])
		result.append({
			"seed_index": seed_index,
			"center": center,
			"rings": province_rings,
		})

	return result


static func _rings_from_grid(
	labels: Array,
	grid_size: int,
	cell_w: float,
	cell_h: float,
	origin: Vector2,
	province_index: int,
	country_rings: Array
) -> Array:
	var segments: Array = []

	for gy in grid_size:
		for gx in grid_size:
			if labels[gy][gx] != province_index:
				continue

			var x0 := origin.x + float(gx) * cell_w
			var y0 := origin.y + float(gy) * cell_h
			var x1 := x0 + cell_w
			var y1 := y0 + cell_h

			if gy == 0 or labels[gy - 1][gx] != province_index:
				segments.append([Vector2(x0, y0), Vector2(x1, y0)])
			if gy == grid_size - 1 or labels[gy + 1][gx] != province_index:
				segments.append([Vector2(x0, y1), Vector2(x1, y1)])
			if gx == 0 or labels[gy][gx - 1] != province_index:
				segments.append([Vector2(x0, y0), Vector2(x0, y1)])
			if gx == grid_size - 1 or labels[gy][gx + 1] != province_index:
				segments.append([Vector2(x1, y0), Vector2(x1, y1)])

	var loops := _segments_to_polygons(segments)
	var valid_rings: Array = []
	for loop in loops:
		if loop is PackedVector2Array and loop.size() >= 3:
			var centroid := _polygon_centroid(loop)
			if _point_in_country(centroid, country_rings):
				valid_rings.append(loop)
	return valid_rings


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
		var j := (i + 1) % points.size()
		area += points[i].x * points[j].y
		area -= points[j].x * points[i].y
	return abs(area) * 0.5


static func _point_in_country(point: Vector2, rings: Array) -> bool:
	for ring in rings:
		if ring is PackedVector2Array and Geometry2D.is_point_in_polygon(point, ring):
			return true
	return false
