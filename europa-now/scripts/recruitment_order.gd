class_name RecruitmentOrder
extends RefCounted

enum Status { RECRUITING, COMPLETED, CANCELLED }

var order_id: String
var country_id: String
var province_id: String
var soldiers: int
var cost: int
var start_date: GameDate
var completion_date: GameDate
var status: Status = Status.RECRUITING


func is_active() -> bool:
	return status == Status.RECRUITING


func to_dict() -> Dictionary:
	return {
		"order_id": order_id,
		"country_id": country_id,
		"province_id": province_id,
		"soldiers": soldiers,
		"cost": cost,
		"start_date": _date_to_dict(start_date),
		"completion_date": _date_to_dict(completion_date),
		"status": status,
	}


static func from_dict(data: Dictionary) -> RecruitmentOrder:
	var order := RecruitmentOrder.new()
	order.order_id = str(data.get("order_id", ""))
	order.country_id = str(data.get("country_id", ""))
	order.province_id = str(data.get("province_id", ""))
	order.soldiers = int(data.get("soldiers", 0))
	order.cost = int(data.get("cost", 0))
	order.start_date = _date_from_dict(data.get("start_date", {}))
	order.completion_date = _date_from_dict(data.get("completion_date", {}))
	order.status = int(data.get("status", Status.RECRUITING))
	return order


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
