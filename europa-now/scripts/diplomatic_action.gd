class_name DiplomaticAction
extends RefCounted

enum Status { PENDING, ACCEPTED, REJECTED, COMPLETED }

var action_id: String
var action_type: String
var source_country_id: String
var target_country_id: String
var date: GameDate
var status: Status = Status.PENDING


func to_dict() -> Dictionary:
	return {
		"action_id": action_id,
		"action_type": action_type,
		"source_country_id": source_country_id,
		"target_country_id": target_country_id,
		"date": _date_to_dict(date),
		"status": status,
	}


static func from_dict(data: Dictionary) -> DiplomaticAction:
	var action := DiplomaticAction.new()
	action.action_id = str(data.get("action_id", ""))
	action.action_type = str(data.get("action_type", ""))
	action.source_country_id = str(data.get("source_country_id", ""))
	action.target_country_id = str(data.get("target_country_id", ""))
	action.date = _date_from_dict(data.get("date", {}))
	action.status = int(data.get("status", Status.PENDING))
	return action


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
