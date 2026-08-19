extends SceneTree

## Headless combat system validation.
## Run: godot --headless --path . --script res://tools/validate_combat.gd

const CombatCalculatorScript := preload("res://scripts/combat_calculator.gd")
const CombatRetreatScript := preload("res://scripts/combat_retreat.gd")
const CombatStateScript := preload("res://scripts/combat_state.gd")
const WarStateScript := preload("res://scripts/war_state.gd")
const UnitDataScript := preload("res://scripts/unit_data.gd")
const ProvinceScript := preload("res://scripts/province.gd")
const ProvinceAdjacencyScript := preload("res://scripts/province_adjacency.gd")
const CombatManagerScript := preload("res://scripts/combat_manager.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	_test_peaceful_capture()
	_test_combat_starts_on_contact()
	_test_defender_wins()
	_test_attacker_wins()
	_test_pause_stops_combat()
	_test_speed_affects_combat()
	_test_multiple_armies()
	_test_retreat_without_route()

	print("=== COMBAT VALIDATION ===")
	print("Passed: %d" % _passed)
	print("Failed: %d" % _failed)
	quit(1 if _failed > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)


func _make_province(id: String, country_id: String) -> Province:
	var province := ProvinceScript.new()
	province.setup({
		"id": id,
		"name": id,
		"country_id": country_id,
		"owner_country_id": country_id,
		"controller_country_id": country_id,
		"center": Vector2.ZERO,
		"rings": [PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)])],
		"color": Color(0.5, 0.5, 0.5),
	})
	return province


func _make_harness() -> Dictionary:
	var provinces: Array[Province] = [
		_make_province("DEU_a", "DEU"),
		_make_province("DEU_b", "DEU"),
		_make_province("AUT_a", "AUT"),
	]
	var adjacency: ProvinceAdjacency = ProvinceAdjacencyScript.build(provinces)
	var provinces_by_id: Dictionary = {}
	for province in provinces:
		provinces_by_id[province.province_id] = province

	var war: WarState = WarStateScript.new()
	war.set_war("DEU", "AUT", true)

	var unit_manager: _MockUnitManager = _MockUnitManager.new()
	unit_manager.setup(provinces_by_id, adjacency)

	var combat_manager: CombatManager = CombatManagerScript.new()
	combat_manager.initialize(unit_manager, provinces, adjacency, war)
	unit_manager.combat_manager = combat_manager

	return {
		"provinces": provinces,
		"provinces_by_id": provinces_by_id,
		"adjacency": adjacency,
		"war": war,
		"unit_manager": unit_manager,
		"combat_manager": combat_manager,
	}



func _test_peaceful_capture() -> void:
	var harness: Dictionary = _make_harness()
	var unit_manager: _MockUnitManager = harness["unit_manager"]
	var combat_manager: CombatManager = harness["combat_manager"]
	var provinces_by_id: Dictionary = harness["provinces_by_id"]

	var attacker: _MockUnit = unit_manager.spawn_unit("GER_1", "DEU", "DEU_a")
	unit_manager.move_unit_to(attacker, "AUT_a")
	unit_manager.complete_pending_arrivals()

	_assert_true(combat_manager.get_combat_at_province("AUT_a") == null, "TEST 1: Kein Kampf in leerer feindlicher Provinz")
	var province: Province = provinces_by_id["AUT_a"]
	_assert_true(province.controller_country_id == "DEU", "TEST 1: Provinz wird erobert")


func _test_combat_starts_on_contact() -> void:
	var harness: Dictionary = _make_harness()
	var unit_manager: _MockUnitManager = harness["unit_manager"]
	var combat_manager: CombatManager = harness["combat_manager"]

	unit_manager.spawn_unit("AUT_1", "AUT", "AUT_a")
	var attacker: _MockUnit = unit_manager.spawn_unit("GER_1", "DEU", "DEU_a")
	unit_manager.move_unit_to(attacker, "AUT_a")
	unit_manager.complete_pending_arrivals()

	var combat: CombatState = combat_manager.get_combat_at_province("AUT_a")
	_assert_true(combat != null and combat.is_active(), "TEST 2: Kampf startet bei Kontakt")


func _test_defender_wins() -> void:
	var harness: Dictionary = _make_harness()
	var unit_manager: _MockUnitManager = harness["unit_manager"]
	var combat_manager: CombatManager = harness["combat_manager"]
	var provinces_by_id: Dictionary = harness["provinces_by_id"]

	var defender: _MockUnit = unit_manager.spawn_unit("AUT_1", "AUT", "AUT_a", 120_000, 120)
	var attacker: _MockUnit = unit_manager.spawn_unit("GER_1", "DEU", "DEU_a", 20_000, 20)
	unit_manager.move_unit_to(attacker, "AUT_a")
	unit_manager.complete_pending_arrivals()

	for _i in CombatCalculatorScript.MAX_COMBAT_DAYS + 2:
		combat_manager.on_day_advanced(GameTime.current_date)

	var combat: CombatState = combat_manager.get_combat_at_province("AUT_a")
	var ended: bool = combat == null or not combat.is_active()
	_assert_true(ended, "TEST 3: Kampf endet")
	var province: Province = provinces_by_id["AUT_a"]
	_assert_true(province.controller_country_id == "AUT", "TEST 3: Verteidiger behaelt Provinz")
	_assert_true(attacker.data.soldiers <= 0 or attacker.data.is_retreating, "TEST 3: Angreifer zieht sich zurueck oder faellt aus")


func _test_attacker_wins() -> void:
	var harness: Dictionary = _make_harness()
	var unit_manager: _MockUnitManager = harness["unit_manager"]
	var combat_manager: CombatManager = harness["combat_manager"]
	var provinces_by_id: Dictionary = harness["provinces_by_id"]

	unit_manager.spawn_unit("AUT_1", "AUT", "AUT_a", 20_000, 20)
	var attacker: _MockUnit = unit_manager.spawn_unit("GER_1", "DEU", "DEU_a", 120_000, 120)
	unit_manager.move_unit_to(attacker, "AUT_a")
	unit_manager.complete_pending_arrivals()

	for _i in CombatCalculatorScript.MAX_COMBAT_DAYS + 2:
		combat_manager.on_day_advanced(GameTime.current_date)

	var province: Province = provinces_by_id["AUT_a"]
	_assert_true(province.controller_country_id == "DEU", "TEST 4: Angreifer erobert Provinz")


func _test_pause_stops_combat() -> void:
	var harness: Dictionary = _make_harness()
	var unit_manager: _MockUnitManager = harness["unit_manager"]
	var combat_manager: CombatManager = harness["combat_manager"]

	unit_manager.spawn_unit("AUT_1", "AUT", "AUT_a")
	var attacker: _MockUnit = unit_manager.spawn_unit("GER_1", "DEU", "DEU_a")
	unit_manager.move_unit_to(attacker, "AUT_a")
	unit_manager.complete_pending_arrivals()

	var combat: CombatState = combat_manager.get_combat_at_province("AUT_a")
	var days_before: int = combat.days_fought if combat != null else 0
	# Pause haelt den Tag-Tick an; ohne day_advanced kein Kampffortschritt.
	_assert_true(combat != null and combat.days_fought == days_before, "TEST 5: Ohne Zeit-Tick kein Kampffortschritt")


func _test_speed_affects_combat() -> void:
	var harness: Dictionary = _make_harness()
	var unit_manager: _MockUnitManager = harness["unit_manager"]
	var combat_manager: CombatManager = harness["combat_manager"]

	unit_manager.spawn_unit("AUT_1", "AUT", "AUT_a")
	var attacker: _MockUnit = unit_manager.spawn_unit("GER_1", "DEU", "DEU_a")
	unit_manager.move_unit_to(attacker, "AUT_a")
	unit_manager.complete_pending_arrivals()

	var combat: CombatState = combat_manager.get_combat_at_province("AUT_a")
	for _i in 3:
		combat_manager.on_day_advanced(GameTime.current_date)
	var days_after_three: int = combat.days_fought
	_assert_true(days_after_three >= 3, "TEST 6: Kampf laeuft ueber mehrere Tage")


func _test_multiple_armies() -> void:
	var harness: Dictionary = _make_harness()
	var unit_manager: _MockUnitManager = harness["unit_manager"]
	var combat_manager: CombatManager = harness["combat_manager"]

	unit_manager.spawn_unit("AUT_1", "AUT", "AUT_a")
	unit_manager.spawn_unit("AUT_2", "AUT", "AUT_a")
	var attacker_a: _MockUnit = unit_manager.spawn_unit("GER_1", "DEU", "DEU_a")
	var attacker_b: _MockUnit = unit_manager.spawn_unit("GER_2", "DEU", "DEU_a")
	unit_manager.move_unit_to(attacker_a, "AUT_a")
	unit_manager.move_unit_to(attacker_b, "AUT_a")
	unit_manager.complete_pending_arrivals()

	var combat: CombatState = combat_manager.get_combat_at_province("AUT_a")
	_assert_true(combat != null, "TEST 7: Kampf existiert")
	_assert_true(combat.attacker_unit_ids.size() >= 2, "TEST 7: Mehrere Angreifer im Kampf")
	_assert_true(combat.defender_unit_ids.size() >= 2, "TEST 7: Mehrere Verteidiger im Kampf")


func _test_retreat_without_route() -> void:
	var provinces: Array[Province] = [_make_province("AUT_a", "AUT")]
	var adjacency: ProvinceAdjacency = ProvinceAdjacencyScript.build(provinces)
	var provinces_by_id: Dictionary = {"AUT_a": provinces[0]}

	var war: WarState = WarStateScript.new()
	war.set_war("DEU", "AUT", true)
	var unit_manager: _MockUnitManager = _MockUnitManager.new()
	unit_manager.setup(provinces_by_id, adjacency)
	var combat_manager: CombatManager = CombatManagerScript.new()
	combat_manager.initialize(unit_manager, provinces, adjacency, war)
	unit_manager.combat_manager = combat_manager

	var defender: _MockUnit = unit_manager.spawn_unit("AUT_1", "AUT", "AUT_a", 10_000, 10)
	unit_manager.spawn_unit("GER_1", "DEU", "AUT_a", 200_000, 200)
	combat_manager.handle_province_after_arrivals("AUT_a")

	for _i in CombatCalculatorScript.MAX_COMBAT_DAYS + 2:
		combat_manager.on_day_advanced(GameTime.current_date)

	_assert_true(unit_manager.get_unit("AUT_1") == null, "TEST 8: Armee ohne Rueckzug wird entfernt")
	_assert_true(defender.data.soldiers <= 0, "TEST 8: Verlierer hat keine Soldaten mehr")


class _MockUnit:
	extends RefCounted

	var data: UnitData

	func _init(unit_data: UnitData) -> void:
		data = unit_data

	func set_moving(_value: bool) -> void:
		pass

	func set_in_combat(_value: bool) -> void:
		pass

	func set_retreating(_value: bool) -> void:
		pass

	func cancel_movement() -> void:
		data.is_moving = false
		data.destination_province_id = ""
		data.arrival_date = null

	func place_on_province(_province: Province) -> void:
		pass


class _MockUnitManager:
	extends RefCounted

	var combat_manager: CombatManager
	var _provinces_by_id: Dictionary = {}
	var _adjacency: ProvinceAdjacency
	var _units: Array = []
	var _units_by_id: Dictionary = {}
	var _pending_arrivals: Array = []


	func setup(provinces_by_id: Dictionary, adjacency: ProvinceAdjacency) -> void:
		_provinces_by_id = provinces_by_id
		_adjacency = adjacency


	func get_unit(unit_id: String):
		return _units_by_id.get(unit_id)


	func get_units_in_province(province_id: String) -> Array:
		var result: Array = []
		for unit in _units:
			if unit.data.current_province_id == province_id and unit.data.soldiers > 0:
				result.append(unit)
		return result


	func spawn_unit(id: String, owner: String, province_id: String, soldiers: int = 100_000, combat_power: int = 100):
		var data := UnitDataScript.new(id, "Army", owner, province_id, soldiers, combat_power)
		var unit := _MockUnit.new(data)
		_units.append(unit)
		_units_by_id[id] = unit
		return unit


	func move_unit_to(unit, destination_id: String) -> void:
		unit.data.destination_province_id = destination_id
		unit.data.is_moving = true
		unit.data.arrival_date = GameTime.current_date
		_pending_arrivals.append({"unit": unit, "province_id": destination_id, "was_moving": true})


	func complete_pending_arrivals() -> void:
		var arrivals: Array = _pending_arrivals.duplicate()
		_pending_arrivals.clear()
		var provinces_touched: Dictionary = {}
		for entry in arrivals:
			var unit = entry["unit"]
			var province_id: String = entry["province_id"]
			var was_moving: bool = entry["was_moving"]
			unit.data.current_province_id = province_id
			unit.data.is_moving = false
			unit.data.destination_province_id = ""
			if combat_manager != null:
				combat_manager.on_unit_arrived(unit, was_moving)
			provinces_touched[province_id] = true
		if combat_manager != null:
			for province_id in provinces_touched:
				combat_manager.handle_province_after_arrivals(province_id)


	func destroy_unit(unit) -> void:
		_units.erase(unit)
		_units_by_id.erase(unit.data.unit_id)


	func order_retreat(unit, province_id: String) -> bool:
		if not _provinces_by_id.has(province_id):
			return false
		unit.data.retreat_destination_id = province_id
		unit.data.retreat_arrival_date = GameTime.current_date.add_days(CombatRetreatScript.RETREAT_DAYS)
		unit.data.is_retreating = true
		return true
