class_name GeoProjection
extends RefCounted

## Simple equirectangular projection centered on Europe.
const CENTER_LON := 15.0
const CENTER_LAT := 54.0
const SCALE := 72.0


static func project(lon: float, lat: float) -> Vector2:
	return Vector2((lon - CENTER_LON) * SCALE, -(lat - CENTER_LAT) * SCALE)


static func project_ring(coordinates: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(coordinates.size())
	for i in coordinates.size():
		var coord: Array = coordinates[i]
		points[i] = project(coord[0], coord[1])
	return points


static func europe_view_bounds() -> Rect2:
	var north_west := project(-25.0, 72.0)
	var south_east := project(45.0, 34.0)
	return Rect2(north_west, south_east - north_west)
