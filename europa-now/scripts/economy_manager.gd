class_name EconomyManager
extends Node

signal economy_updated(country_id: String)
signal recruitment_order_created(order: RecruitmentOrder)
signal recruitment_completed(order: RecruitmentOrder, unit: Unit)
signal recruitment_rejected(reason: String)

const RECRUITMENT_COST_PER_SOLDIER := 2
const RECRUITMENT_DAYS := 30

var _economies: Dictionary = {}
var _orders: Dictionary = {}
var _order_counter := 0
var _countries_by_id: Dictionary = {}
var _provinces_by_id: Dictionary = {}
var _unit_manager: UnitManager


func initialize(
	countries: Array[Country],
	provinces: Array[Province],
	unit_manager: UnitManager
) -> void:
	_countries_by_id.clear()
	_provinces_by_id.clear()
	_economies.clear()
	_orders.clear()
	_unit_manager = unit_manager

	for country in countries:
		_countries_by_id[country.country_id] = country
		var economy := CountryEconomy.new()
		economy.setup(
			country.country_id,
			country.population,
			country.gdp_million
		)
		_economies[country.country_id] = economy

	for province in provinces:
		_provinces_by_id[province.province_id] = province

	if not GameTime.day_advanced.is_connected(_on_day_advanced):
		GameTime.day_advanced.connect(_on_day_advanced)
	if not GameTime.month_advanced.is_connected(_on_month_advanced):
		GameTime.month_advanced.connect(_on_month_advanced)


func get_economy(country_id: String) -> CountryEconomy:
	return _economies.get(country_id)


func get_active_orders() -> Array[RecruitmentOrder]:
	var result: Array[RecruitmentOrder] = []
	for order: RecruitmentOrder in _orders.values():
		if order.is_active():
			result.append(order)
	return result


func get_orders_for_country(country_id: String) -> Array[RecruitmentOrder]:
	var result: Array[RecruitmentOrder] = []
	for order: RecruitmentOrder in _orders.values():
		if order.country_id == country_id and order.is_active():
			result.append(order)
	return result


func preview_recruitment(
	country_id: String,
	soldiers: int
) -> Dictionary:
	var amount := maxi(soldiers, 0)
	return {
		"valid_amount": amount >= 1_000,
		"cost": amount * RECRUITMENT_COST_PER_SOLDIER,
		"days": RECRUITMENT_DAYS,
		"country_id": country_id,
		"soldiers": amount,
	}


func create_recruitment_order(
	country_id: String,
	province_id: String,
	soldiers: int
) -> RecruitmentOrder:
	var economy: CountryEconomy = _economies.get(country_id)
	var province: Province = _provinces_by_id.get(province_id)
	var amount := maxi(soldiers, 0)
	var cost := amount * RECRUITMENT_COST_PER_SOLDIER

	if economy == null:
		return _reject("Unbekanntes Land.")
	if province == null:
		return _reject("Unbekannte Provinz.")
	if province.controller_country_id != country_id:
		return _reject("Nur eigene kontrollierte Provinzen koennen rekrutieren.")
	if amount < 1_000:
		return _reject("Mindestens 1.000 Soldaten erforderlich.")
	if economy.available_recruitable_population() < amount:
		return _reject("Nicht genuegend Rekrutierungspotenzial.")
	if economy.treasury < cost:
		return _reject("Nicht genuegend Staatsbudget.")

	if not economy.reserve_recruits(amount):
		return _reject("Nicht genuegend Rekrutierungspotenzial.")
	economy.treasury -= cost

	_order_counter += 1
	var order := RecruitmentOrder.new()
	order.order_id = "recruitment_%d" % _order_counter
	order.country_id = country_id
	order.province_id = province_id
	order.soldiers = amount
	order.cost = cost
	order.start_date = GameTime.current_date.duplicate_date()
	order.completion_date = GameTime.current_date.add_days(RECRUITMENT_DAYS)
	_orders[order.order_id] = order

	recruitment_order_created.emit(order)
	economy_updated.emit(country_id)
	return order


func get_save_data() -> Dictionary:
	var economy_data: Dictionary = {}
	for country_id in _economies:
		var economy: CountryEconomy = _economies[country_id]
		economy_data[str(country_id)] = economy.to_dict()
	var order_data: Array = []
	for order: RecruitmentOrder in _orders.values():
		order_data.append(order.to_dict())
	return {
		"economies": economy_data,
		"orders": order_data,
		"order_counter": _order_counter,
	}


func load_save_data(data: Dictionary) -> void:
	for country_id in data.get("economies", {}):
		var saved: Dictionary = data["economies"][country_id]
		_economies[str(country_id)] = CountryEconomy.from_dict(saved)
	_orders.clear()
	for entry in data.get("orders", []):
		var order := RecruitmentOrder.from_dict(entry)
		_orders[order.order_id] = order
	_order_counter = int(data.get("order_counter", 0))


func _on_day_advanced(date: GameDate) -> void:
	var completed: Array[RecruitmentOrder] = []
	for order: RecruitmentOrder in _orders.values():
		if order.is_active() and date.is_on_or_after(order.completion_date):
			completed.append(order)

	for order in completed:
		_complete_order(order)


func _on_month_advanced(_date: GameDate) -> void:
	for country_id in _economies:
		var economy: CountryEconomy = _economies[country_id]
		economy.apply_monthly_finances()
		economy_updated.emit(str(country_id))


func _complete_order(order: RecruitmentOrder) -> void:
	var economy: CountryEconomy = _economies.get(order.country_id)
	if economy == null or _unit_manager == null:
		return

	order.status = RecruitmentOrder.Status.COMPLETED
	economy.consume_reserved_recruits(order.soldiers)
	var unit: Unit = _unit_manager.create_recruited_army(
		order.country_id,
		order.province_id,
		order.soldiers
	)
	if unit == null:
		order.status = RecruitmentOrder.Status.CANCELLED
		economy.release_reserved_recruits(order.soldiers)
		economy.treasury += order.cost
		economy_updated.emit(order.country_id)
		return

	economy_updated.emit(order.country_id)
	recruitment_completed.emit(order, unit)


func _reject(reason: String) -> RecruitmentOrder:
	recruitment_rejected.emit(reason)
	return null
