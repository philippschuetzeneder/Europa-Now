class_name GameDate
extends RefCounted

const MONTH_NAMES := [
	"Januar", "Februar", "Maerz", "April", "Mai", "Juni",
	"Juli", "August", "September", "Oktober", "November", "Dezember",
]

const DAYS_IN_MONTH := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

var year: int
var month: int
var day: int


func _init(p_year: int = 2022, p_month: int = 1, p_day: int = 1) -> void:
	year = p_year
	month = p_month
	day = p_day
	_normalize()


func duplicate_date() -> GameDate:
	return GameDate.new(year, month, day)


func add_days(amount: int) -> GameDate:
	var result := duplicate_date()
	var remaining := amount
	while remaining > 0:
		var days_in_month := _days_in_month(result.year, result.month)
		var days_left_in_month := days_in_month - result.day + 1
		if remaining < days_left_in_month:
			result.day += remaining
			remaining = 0
		else:
			remaining -= days_left_in_month
			result.month += 1
			if result.month > 12:
				result.month = 1
				result.year += 1
			result.day = 1
	return result


func is_on_or_after(other: GameDate) -> bool:
	if year != other.year:
		return year > other.year
	if month != other.month:
		return month > other.month
	return day >= other.day


func format_long() -> String:
	return "%02d. %s %d" % [day, MONTH_NAMES[month - 1], year]


func format_short() -> String:
	return "%02d.%02d.%d" % [day, month, year]


func _normalize() -> void:
	while month > 12:
		month -= 12
		year += 1
	while month < 1:
		month += 12
		year -= 1

	var max_day := _days_in_month(year, month)
	if day < 1:
		day = 1
	elif day > max_day:
		day = max_day


func _days_in_month(p_year: int, p_month: int) -> int:
	if p_month == 2 and _is_leap_year(p_year):
		return 29
	return DAYS_IN_MONTH[p_month - 1]


func _is_leap_year(p_year: int) -> bool:
	return p_year % 4 == 0 and (p_year % 100 != 0 or p_year % 400 == 0)
