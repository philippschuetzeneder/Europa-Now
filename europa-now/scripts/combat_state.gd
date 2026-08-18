class_name CombatState
extends RefCounted

enum Status { ACTIVE, ENDED }

var combat_id: String
var province_id: String
var attacker_country_ids: Array[String] = []
var defender_country_ids: Array[String] = []
var attacker_unit_ids: Array[String] = []
var defender_unit_ids: Array[String] = []
var start_date: GameDate
var days_fought: int = 0
var status: Status = Status.ACTIVE
var attacker_casualties: int = 0
var defender_casualties: int = 0
var winner_side: String = ""


func is_active() -> bool:
	return status == Status.ACTIVE


func get_duration_hours() -> int:
	return days_fought * 24


func to_dict() -> Dictionary:
	return {
		"combat_id": combat_id,
		"province_id": province_id,
		"attacker_country_ids": attacker_country_ids,
		"defender_country_ids": defender_country_ids,
		"attacker_unit_ids": attacker_unit_ids,
		"defender_unit_ids": defender_unit_ids,
		"start_date": _date_to_dict(start_date),
		"days_fought": days_fought,
		"status": status,
		"attacker_casualties": attacker_casualties,
		"defender_casualties": defender_casualties,
		"winner_side": winner_side,
	}


static func from_dict(data: Dictionary) -> CombatState:
	var combat := CombatState.new()
	combat.combat_id = str(data.get("combat_id", ""))
	combat.province_id = str(data.get("province_id", ""))
	combat.attacker_country_ids.assign(data.get("attacker_country_ids", []))
	combat.defender_country_ids.assign(data.get("defender_country_ids", []))
	combat.attacker_unit_ids.assign(data.get("attacker_unit_ids", []))
	combat.defender_unit_ids.assign(data.get("defender_unit_ids", []))
	combat.start_date = _date_from_dict(data.get("start_date", {}))
	combat.days_fought = int(data.get("days_fought", 0))
	combat.status = int(data.get("status", Status.ACTIVE))
	combat.attacker_casualties = int(data.get("attacker_casualties", 0))
	combat.defender_casualties = int(data.get("defender_casualties", 0))
	combat.winner_side = str(data.get("winner_side", ""))
	return combat


static func _date_to_dict(date: GameDate) -> Dictionary:
	if date == null:
		return {}
	return {"year": date.year, "month": date.month, "day": date.day}


static func _date_from_dict(data: Dictionary) -> GameDate:
	if data.is_empty():
		return GameDate.new()
	return GameDate.new(int(data.get("year", 2022)), int(data.get("month", 1)), int(data.get("day", 1)))
