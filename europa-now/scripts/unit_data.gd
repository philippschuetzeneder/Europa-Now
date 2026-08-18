class_name UnitData
extends RefCounted

var unit_id: String
var unit_type: String
var owner_country_id: String
var current_province_id: String
var is_moving := false
var destination_province_id := ""
var arrival_date: GameDate


func _init(
	id: String,
	type: String,
	owner_id: String,
	start_province_id: String
) -> void:
	unit_id = id
	unit_type = type
	owner_country_id = owner_id
	current_province_id = start_province_id
