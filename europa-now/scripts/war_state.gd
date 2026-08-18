class_name WarState
extends RefCounted

## Tracks which countries are at war. Neutral countries are not pulled into combat.

var _war_pairs: Dictionary = {}


func set_war(country_a: String, country_b: String, at_war: bool = true) -> void:
	if country_a == country_b:
		return
	var key := _pair_key(country_a, country_b)
	if at_war:
		_war_pairs[key] = true
	elif _war_pairs.has(key):
		_war_pairs.erase(key)


func are_at_war(country_a: String, country_b: String) -> bool:
	if country_a == country_b:
		return false
	return _war_pairs.has(_pair_key(country_a, country_b))


func get_enemies(country_id: String) -> Array[String]:
	var result: Array[String] = []
	for key in _war_pairs:
		var parts: PackedStringArray = key.split("|")
		if parts.size() != 2:
			continue
		if parts[0] == country_id:
			result.append(parts[1])
		elif parts[1] == country_id:
			result.append(parts[0])
	return result


func to_dict() -> Dictionary:
	return {"war_pairs": _war_pairs.keys()}


func load_from_dict(data: Dictionary) -> void:
	_war_pairs.clear()
	for key in data.get("war_pairs", []):
		_war_pairs[str(key)] = true


static func _pair_key(country_a: String, country_b: String) -> String:
	if country_a < country_b:
		return "%s|%s" % [country_a, country_b]
	return "%s|%s" % [country_b, country_a]
