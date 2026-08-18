class_name MapValidationReport
extends RefCounted

var country_count := 0
var province_count := 0
var countries_without_provinces: Array[String] = []
var provinces_without_owner: Array[String] = []
var duplicate_country_ids: Array[String] = []
var duplicate_province_ids: Array[String] = []
var excluded_microstates: Array[String] = []
var warnings: Array[String] = []
