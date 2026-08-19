class_name CountryEconomy
extends RefCounted

var country_id: String
var population: int
var gdp: int
var treasury: int
var income: int
var expenses: int
var military_budget: int
var recruitable_population: int
var reserved_recruitable_population: int = 0


func setup(
	id: String,
	country_population: int,
	country_gdp_million: int
) -> void:
	country_id = id
	population = maxi(country_population, 0)
	gdp = maxi(country_gdp_million, 0) * 1_000_000
	recruitable_population = maxi(int(round(float(population) * 0.05)), 0)
	income = maxi(int(round(float(gdp) * 0.01)), 1_000)
	expenses = maxi(int(round(float(income) * 0.60)), 0)
	military_budget = maxi(int(round(float(income) * 0.20)), 0)
	treasury = maxi(income * 6, 0)


func available_recruitable_population() -> int:
	return maxi(recruitable_population - reserved_recruitable_population, 0)


func reserve_recruits(amount: int) -> bool:
	if amount <= 0 or available_recruitable_population() < amount:
		return false
	reserved_recruitable_population += amount
	return true


func consume_reserved_recruits(amount: int) -> void:
	reserved_recruitable_population = maxi(
		reserved_recruitable_population - maxi(amount, 0),
		0
	)
	recruitable_population = maxi(recruitable_population - maxi(amount, 0), 0)


func release_reserved_recruits(amount: int) -> void:
	reserved_recruitable_population = maxi(
		reserved_recruitable_population - maxi(amount, 0),
		0
	)


func apply_monthly_finances() -> void:
	treasury += income
	treasury -= expenses


func to_dict() -> Dictionary:
	return {
		"country_id": country_id,
		"population": population,
		"gdp": gdp,
		"treasury": treasury,
		"income": income,
		"expenses": expenses,
		"military_budget": military_budget,
		"recruitable_population": recruitable_population,
		"reserved_recruitable_population": reserved_recruitable_population,
	}


static func from_dict(data: Dictionary) -> CountryEconomy:
	var economy := CountryEconomy.new()
	economy.country_id = str(data.get("country_id", ""))
	economy.population = int(data.get("population", 0))
	economy.gdp = int(data.get("gdp", 0))
	economy.treasury = int(data.get("treasury", 0))
	economy.income = int(data.get("income", 0))
	economy.expenses = int(data.get("expenses", 0))
	economy.military_budget = int(data.get("military_budget", 0))
	economy.recruitable_population = int(data.get("recruitable_population", 0))
	economy.reserved_recruitable_population = int(
		data.get("reserved_recruitable_population", 0)
	)
	return economy
