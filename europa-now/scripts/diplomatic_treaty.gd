class_name DiplomaticTreaty
extends RefCounted

enum Status { ACTIVE, EXPIRED, CANCELLED }

var treaty_id: String
var treaty_type: String
var country_a: String
var country_b: String
var start_date: GameDate
var end_date: GameDate
var status: Status = Status.ACTIVE


func is_active(on_date: GameDate = null) -> bool:
	if status != Status.ACTIVE:
		return false
	if end_date == null or on_date == null:
		return true
	return not on_date.is_on_or_after(end_date)


func includes_country(country_id: String) -> bool:
	return country_a == country_id or country_b == country_id


func other_country(country_id: String) -> String:
	if country_a == country_id:
		return country_b
	if country_b == country_id:
		return country_a
	return ""


func to_dict() -> Dictionary:
	return {
		"treaty_id": treaty_id,
		"treaty_type": treaty_type,
		"country_a": country_a,
		"country_b": country_b,
		"start_date": _date_to_dict(start_date),
		"end_date": _date_to_dict(end_date),
		"status": status,
	}


static func from_dict(data: Dictionary) -> DiplomaticTreaty:
	var treaty := DiplomaticTreaty.new()
	treaty.treaty_id = str(data.get("treaty_id", ""))
	treaty.treaty_type = str(data.get("treaty_type", ""))
	treaty.country_a = str(data.get("country_a", ""))
	treaty.country_b = str(data.get("country_b", ""))
	treaty.start_date = _date_from_dict(data.get("start_date", {}))
	treaty.end_date = _date_from_dict(data.get("end_date", {}))
	treaty.status = int(data.get("status", Status.ACTIVE))
	return treaty


static func _date_to_dict(date: GameDate) -> Dictionary:
	if date == null:
		return {}
	return {"year": date.year, "month": date.month, "day": date.day}


static func _date_from_dict(data: Dictionary) -> GameDate:
	if data.is_empty():
		return null
	return GameDate.new(
		int(data.get("year", 2022)),
		int(data.get("month", 1)),
		int(data.get("day", 1))
	)
