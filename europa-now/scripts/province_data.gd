class_name ProvinceData
extends RefCounted

var province_id: String
var display_name: String
var country_id: String
var owner_country_id: String
var center: Vector2
var primary_city: String
var terrain: String
var population: int
var economic_value: int


func _init(
	id: String,
	name: String,
	country: String,
	owner: String = ""
) -> void:
	province_id = id
	display_name = name
	country_id = country
	owner_country_id = owner if not owner.is_empty() else country
	primary_city = ""
	terrain = "plains"
	population = 0
	economic_value = 0
