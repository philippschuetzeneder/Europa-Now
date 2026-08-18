class_name PolarRegionsLayer
extends Node2D

const POLAR_COLORS := {
	"ATA": Color(0.90, 0.94, 0.98, 0.95),
	"GRL": Color(0.78, 0.86, 0.92, 0.92),
}


func build_from_data(regions: Array[Dictionary]) -> void:
	for child in get_children():
		child.queue_free()

	for data in regions:
		var region_id: String = str(data.get("id", ""))
		var color: Color = POLAR_COLORS.get(region_id, Color(0.85, 0.9, 0.95, 0.9))
		for ring in data.get("rings", []):
			if ring is not PackedVector2Array or ring.size() < 3:
				continue

			var fill := Polygon2D.new()
			fill.polygon = ring
			fill.color = color
			add_child(fill)

			var border := Line2D.new()
			border.points = ring
			border.closed = true
			border.default_color = Color(0.12, 0.16, 0.22, 0.7)
			border.width = 1.2
			border.antialiased = true
			add_child(border)
