class_name MapUiScale
extends RefCounted

## Keeps on-map markers at a consistent screen size across zoom levels.


static func screen_scale(
	zoom_level: float,
	world_radius: float,
	target_screen_radius_px: float,
	max_scale: float = 4.0
) -> float:
	if zoom_level <= 0.0 or world_radius <= 0.0:
		return 1.0
	return minf(target_screen_radius_px / (world_radius * zoom_level), max_scale)
