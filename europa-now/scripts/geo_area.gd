class_name GeoArea
extends RefCounted

const EARTH_RADIUS_KM := 6371.0


static func ring_area_km2(coordinates: Array) -> float:
	if coordinates.size() < 3:
		return 0.0

	var area := 0.0
	for i in coordinates.size():
		var j: int = (i + 1) % coordinates.size()
		var lon1: float = deg_to_rad(float(coordinates[i][0]))
		var lat1: float = deg_to_rad(float(coordinates[i][1]))
		var lon2: float = deg_to_rad(float(coordinates[j][0]))
		var lat2: float = deg_to_rad(float(coordinates[j][1]))
		area += (lon2 - lon1) * (2.0 + sin(lat1) + sin(lat2))

	return abs(area) * EARTH_RADIUS_KM * EARTH_RADIUS_KM * 0.5


static func geometry_area_km2(geometry: Dictionary) -> float:
	var geometry_type := str(geometry.get("type", ""))
	var coordinates: Array = geometry.get("coordinates", [])
	var total := 0.0

	match geometry_type:
		"Polygon":
			if not coordinates.is_empty():
				total += ring_area_km2(coordinates[0])
		"MultiPolygon":
			for polygon in coordinates:
				if polygon is Array and not polygon.is_empty():
					total += ring_area_km2(polygon[0])

	return total


static func geometry_bbox_area_km2(geometry: Dictionary) -> float:
	var bounds := geometry_bounds(geometry)
	if bounds.size == Vector2.ZERO:
		return 0.0

	var lat_span: float = absf(bounds.position.y - bounds.end.y)
	var lon_span: float = absf(bounds.end.x - bounds.position.x)
	var avg_lat: float = deg_to_rad((bounds.position.y + bounds.end.y) * 0.5)
	var lat_km: float = lat_span * 111.0
	var lon_km: float = lon_span * 111.0 * cos(avg_lat)
	return lat_km * lon_km


static func geometry_bounds(geometry: Dictionary) -> Rect2:
	var geometry_type := str(geometry.get("type", ""))
	var coordinates: Array = geometry.get("coordinates", [])
	var bounds := Rect2()

	match geometry_type:
		"Polygon":
			if not coordinates.is_empty():
				bounds = _expand_bounds_with_ring(bounds, coordinates[0])
		"MultiPolygon":
			for polygon in coordinates:
				if polygon is Array and not polygon.is_empty():
					bounds = _expand_bounds_with_ring(bounds, polygon[0])

	return bounds


static func _expand_bounds_with_ring(bounds: Rect2, ring: Array) -> Rect2:
	for coord in ring:
		if coord is Array and coord.size() >= 2:
			var lon := float(coord[0])
			var lat := float(coord[1])
			var point := Vector2(lon, lat)
			if bounds.size == Vector2.ZERO:
				bounds = Rect2(point, Vector2.ZERO)
			else:
				bounds = bounds.expand(point)
	return bounds
