class_name UnitData
extends RefCounted

var unit_id: String
var unit_type: String
var owner_country_id: String
var current_province_id: String
var is_moving := false
var destination_province_id := ""
var arrival_date: GameDate
var soldiers: int = 100_000
var combat_power: int = 100
var morale: float = 100.0
var organization: float = 100.0
var is_in_combat := false
var combat_id := ""
var is_retreating := false
var retreat_destination_id := ""
var retreat_arrival_date: GameDate
var casualties_this_battle: int = 0


func _init(
	id: String,
	type: String,
	owner_id: String,
	start_province_id: String,
	p_soldiers: int = 100_000,
	p_combat_power: int = 100
) -> void:
	unit_id = id
	unit_type = type
	owner_country_id = owner_id
	current_province_id = start_province_id
	soldiers = p_soldiers
	combat_power = p_combat_power


func reset_battle_stats() -> void:
	casualties_this_battle = 0
	morale = 100.0
	organization = 100.0


func effective_strength() -> float:
	return CombatCalculator.effective_strength(self)


func to_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"unit_type": unit_type,
		"owner_country_id": owner_country_id,
		"current_province_id": current_province_id,
		"is_moving": is_moving,
		"destination_province_id": destination_province_id,
		"arrival_date": _date_to_dict(arrival_date),
		"soldiers": soldiers,
		"combat_power": combat_power,
		"morale": morale,
		"organization": organization,
		"is_in_combat": is_in_combat,
		"combat_id": combat_id,
		"is_retreating": is_retreating,
		"retreat_destination_id": retreat_destination_id,
		"retreat_arrival_date": _date_to_dict(retreat_arrival_date),
		"casualties_this_battle": casualties_this_battle,
	}


static func from_dict(data: Dictionary) -> UnitData:
	var unit := UnitData.new(
		str(data.get("unit_id", "")),
		str(data.get("unit_type", "Army")),
		str(data.get("owner_country_id", "")),
		str(data.get("current_province_id", "")),
		int(data.get("soldiers", 100_000)),
		int(data.get("combat_power", 100))
	)
	unit.is_moving = bool(data.get("is_moving", false))
	unit.destination_province_id = str(data.get("destination_province_id", ""))
	unit.arrival_date = _date_from_dict(data.get("arrival_date", {}))
	unit.morale = float(data.get("morale", 100.0))
	unit.organization = float(data.get("organization", 100.0))
	unit.is_in_combat = bool(data.get("is_in_combat", false))
	unit.combat_id = str(data.get("combat_id", ""))
	unit.is_retreating = bool(data.get("is_retreating", false))
	unit.retreat_destination_id = str(data.get("retreat_destination_id", ""))
	unit.retreat_arrival_date = _date_from_dict(data.get("retreat_arrival_date", {}))
	unit.casualties_this_battle = int(data.get("casualties_this_battle", 0))
	return unit


static func _date_to_dict(date: GameDate) -> Dictionary:
	if date == null:
		return {}
	return {"year": date.year, "month": date.month, "day": date.day}


static func _date_from_dict(data: Dictionary) -> GameDate:
	if data.is_empty():
		return null
	return GameDate.new(int(data.get("year", 2022)), int(data.get("month", 1)), int(data.get("day", 1)))
