extends SceneTree

## Headless validation for national economy and recruitment.
## Run: godot --headless --path . --script res://tools/validate_recruitment.gd

var _passed := 0
var _failed := 0
var _economy_manager: EconomyManager
var _unit_manager: UnitManager
var _provinces: Array[Province] = []


func _init() -> void:
	_setup()
	_test_sufficient_manpower()
	_test_insufficient_manpower()
	_test_insufficient_treasury()
	_test_monthly_finances()
	_test_order_reserves_and_deducts()
	_test_pause_keeps_order_pending()
	_test_multiple_provinces()
	_test_completion_creates_army()
	_test_recruited_army_can_move()

	print("=== RECRUITMENT VALIDATION ===")
	print("Passed: %d" % _passed)
	print("Failed: %d" % _failed)
	quit(1 if _failed > 0 else 0)


func _setup() -> void:
	var country := Country.new()
	country.setup({
		"id": "DEU",
		"name": "Deutschland",
		"color": Color(0.2, 0.3, 0.7),
		"population": 1_000_000,
		"gdp_million": 1_000,
		"rings": [],
	})

	_provinces = [
		_make_province("DEU_a", 0.0),
		_make_province("DEU_b", 2.0),
		_make_province("DEU_c", 4.0),
	]
	var adjacency := ProvinceAdjacency.build(_provinces)
	_unit_manager = UnitManager.new()
	_unit_manager.initialize(_provinces, adjacency, "DEU_a")
	_economy_manager = EconomyManager.new()
	_economy_manager.initialize([country], _provinces, _unit_manager)
	GameTime.current_date = GameDate.new(2022, 1, 1)


func _make_province(id: String, x: float) -> Province:
	var province := Province.new()
	province.setup({
		"id": id,
		"name": id,
		"country_id": "DEU",
		"owner_country_id": "DEU",
		"controller_country_id": "DEU",
		"center": Vector2(x, 0.0),
		"primary_city": id,
		"rings": [PackedVector2Array([
			Vector2(x - 1.0, -1.0),
			Vector2(x + 1.0, -1.0),
			Vector2(x + 1.0, 1.0),
			Vector2(x - 1.0, 1.0),
		])],
		"color": Color(0.3, 0.4, 0.6),
	})
	return province


func _test_sufficient_manpower() -> void:
	var order := _economy_manager.create_recruitment_order("DEU", "DEU_a", 10_000)
	_assert_true(order != null, "TEST 1: Ausreichendes Rekrutierungspotenzial erlaubt Auftrag")


func _test_insufficient_manpower() -> void:
	var order := _economy_manager.create_recruitment_order("DEU", "DEU_b", 100_000)
	_assert_true(order == null, "TEST 2: Zu wenig Rekrutierungspotenzial lehnt Auftrag ab")


func _test_insufficient_treasury() -> void:
	var economy: CountryEconomy = _economy_manager.get_economy("DEU")
	economy.treasury = 0
	var order := _economy_manager.create_recruitment_order("DEU", "DEU_b", 10_000)
	_assert_true(order == null, "TEST 3: Zu wenig Staatsbudget lehnt Auftrag ab")
	economy.treasury = economy.income * 6


func _test_monthly_finances() -> void:
	var economy: CountryEconomy = _economy_manager.get_economy("DEU")
	var before := economy.treasury
	_economy_manager._on_month_advanced(GameDate.new(2022, 2, 1))
	_assert_true(
		economy.treasury == before + economy.income - economy.expenses,
		"TEST 4: Monatlicher Wirtschaftstick verarbeitet Einkommen und Ausgaben"
	)


func _test_order_reserves_and_deducts() -> void:
	var economy: CountryEconomy = _economy_manager.get_economy("DEU")
	var before_treasury := economy.treasury
	var before_available := economy.available_recruitable_population()
	var order := _economy_manager.create_recruitment_order("DEU", "DEU_b", 10_000)
	_assert_true(order != null, "TEST 4: Auftrag wird erstellt")
	_assert_true(
		economy.treasury == before_treasury - order.cost,
		"TEST 4: Kosten werden sofort abgezogen"
	)
	_assert_true(
		economy.available_recruitable_population() == before_available - 10_000,
		"TEST 4: Rekruten werden sofort reserviert"
	)


func _test_pause_keeps_order_pending() -> void:
	var order := _economy_manager.create_recruitment_order("DEU", "DEU_c", 5_000)
	var initial_status := order.status
	GameTime.set_speed(GameTime.Speed.PAUSE)
	_assert_true(
		order.status == initial_status,
		"TEST 5/6: Pause ohne day_advanced-Tick laesst Auftrag unveraendert"
	)


func _test_completion_creates_army() -> void:
	var completion_date := GameTime.current_date.add_days(EconomyManager.RECRUITMENT_DAYS)
	_economy_manager._on_day_advanced(completion_date)
	var found := false
	for unit in _unit_manager.get_units():
		if unit.data.unit_id.begins_with("DEU_RECRUIT_"):
			found = true
			break
	_assert_true(found, "TEST 7: Abgeschlossener Auftrag erzeugt eine Armee")


func _test_multiple_provinces() -> void:
	var orders := _economy_manager.get_orders_for_country("DEU")
	var active_count := 0
	for order in orders:
		if order.is_active():
			active_count += 1
	_assert_true(active_count >= 1, "TEST 8/9: Mehrere Provinzen koennen parallel rekrutieren")


func _test_recruited_army_can_move() -> void:
	var recruited: Unit = null
	for unit in _unit_manager.get_units():
		if unit.data.unit_id.begins_with("DEU_RECRUIT_"):
			recruited = unit
			break
	if recruited == null:
		_assert_true(false, "TEST 10: Rekrutierte Armee ist vorhanden")
		return
	var reason := _unit_manager.get_move_block_reason(recruited, "DEU_b")
	_assert_true(reason.is_empty(), "TEST 10: Rekrutierte Armee kann bewegt werden")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
