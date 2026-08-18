class_name UnitData
extends RefCounted

var unit_id: String
var unit_type: String
var owner_country_id: String
var current_country_id: String


func _init(
	id: String,
	type: String,
	owner_id: String,
	current_id: String = ""
) -> void:
	unit_id = id
	unit_type = type
	owner_country_id = owner_id
	current_country_id = current_id if not current_id.is_empty() else owner_id
