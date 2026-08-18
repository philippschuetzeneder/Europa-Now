class_name GeoProjection
extends RefCounted

## Global equirectangular projection for the world map.
const CENTER_LON := 10.0
const CENTER_LAT := 20.0
const SCALE := 11.0

const VIEW_NORTH_LAT := 84.0
const VIEW_SOUTH_LAT := -78.0


static func project(lon: float, lat: float) -> Vector2:
	return Vector2((lon - CENTER_LON) * SCALE, -(lat - CENTER_LAT) * SCALE)


static func project_ring(coordinates: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(coordinates.size())
	for i in coordinates.size():
		var coord: Array = coordinates[i]
		points[i] = project(coord[0], coord[1])
	return points


static func world_width() -> float:
	return 360.0 * SCALE


static func map_min_x() -> float:
	return project(-180.0, 0.0).x


static func wrap_x(x: float) -> float:
	var width: float = world_width()
	var min_x: float = map_min_x()
	var relative: float = fmod(x - min_x, width)
	if relative < 0.0:
		relative += width
	return min_x + relative


static func wrap_offsets() -> Array[float]:
	var width: float = world_width()
	return [0.0, -width, width]


static func world_view_bounds() -> Rect2:
	var north_west := project(-180.0, VIEW_NORTH_LAT)
	var south_east := project(180.0, VIEW_SOUTH_LAT)
	return Rect2(north_west, south_east - north_west)


static func europe_bavaria_view_bounds() -> Rect2:
	var north_west := project(-2.0, 54.0)
	var south_east := project(20.0, 45.0)
	return Rect2(north_west, south_east - north_west)
