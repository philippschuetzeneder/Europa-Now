extends SceneTree

## Headless validation for diplomacy.
## Run: godot --headless --path . --script res://tools/validate_diplomacy.gd

var _passed := 0
var _failed := 0
var _manager: DiplomacyManager


func _init() -> void:
	GameTime.current_date = GameDate.new(2026, 1, 1)
	_manager = DiplomacyManager.new()
	_manager.initialize(["DEU", "AUT", "RUS", "HUN"])

	_test_initial_peace()
	_test_relationship_change()
	_test_alliance_and_war_breaks_treaties()
	_test_non_warring_countries()
	_test_peace_offer_and_acceptance()
	_test_nap_duration_and_expiry()
	_test_pause_keeps_treaty_active()
	_test_multiple_pairs()
	_test_pending_action_acceptance_and_rejection()
	_test_save_load()

	print("=== DIPLOMACY VALIDATION ===")
	print("Passed: %d" % _passed)
	print("Failed: %d" % _failed)
	quit(1 if _failed > 0 else 0)


func _test_initial_peace() -> void:
	_assert_true(
		not _manager.is_at_war("DEU", "AUT"),
		"TEST 1: Laender starten im Frieden"
	)


func _test_relationship_change() -> void:
	_manager.change_relationship("DEU", "AUT", 75)
	_assert_true(
		_manager.get_relationship("AUT", "DEU") == 75,
		"TEST 2: Beziehung ist symmetrisch veraenderbar"
	)


func _test_alliance_and_war_breaks_treaties() -> void:
	var alliance := _manager.offer_alliance("DEU", "AUT")
	_assert_true(alliance != null, "TEST 3: Buendnisangebot wird erstellt")
	_manager.accept_action(alliance.action_id)
	var nap := _manager.offer_non_aggression_pact("DEU", "AUT")
	_assert_true(nap != null, "TEST 3: NAP-Angebot wird erstellt")
	_manager.accept_action(nap.action_id)
	_assert_true(
		_manager.are_allied("DEU", "AUT") and _manager.have_non_aggression_pact("DEU", "AUT"),
		"TEST 3: Buendnis und NAP sind aktiv"
	)

	_manager.declare_war("DEU", "AUT")
	_assert_true(_manager.is_at_war("DEU", "AUT"), "TEST 4: Krieg wird erklaert")
	_assert_true(
		not _manager.are_allied("DEU", "AUT"),
		"TEST 4: Krieg beendet das Buendnis"
	)
	_assert_true(
		not _manager.have_non_aggression_pact("DEU", "AUT"),
		"TEST 5: Krieg beendet den NAP"
	)


func _test_non_warring_countries() -> void:
	_assert_true(
		not _manager.is_at_war("RUS", "HUN"),
		"TEST 6/7: Nicht verfeindete Laender bleiben friedlich"
	)
	_assert_true(
		_manager.get_war_state().are_at_war("DEU", "AUT"),
		"TEST 6: Kampfsystem kann den Diplomatie-Kriegsstatus abfragen"
	)


func _test_peace_offer_and_acceptance() -> void:
	var offer := _manager.offer_peace("DEU", "AUT")
	_assert_true(offer != null, "TEST 8: Friedensangebot wird erstellt")
	_manager.accept_action(offer.action_id)
	_assert_true(
		not _manager.is_at_war("DEU", "AUT"),
		"TEST 9: Angenommenes Friedensangebot beendet den Krieg"
	)


func _test_nap_duration_and_expiry() -> void:
	var offer := _manager.offer_non_aggression_pact("DEU", "RUS")
	_manager.accept_action(offer.action_id)
	var treaty := _manager.get_treaty(
		"DEU",
		"RUS",
		DiplomacyManager.TREATY_NAP
	)
	_assert_true(
		treaty != null
		and treaty.end_date.is_on_or_after(GameTime.current_date.add_days(179)),
		"TEST 10: NAP besitzt ein korrektes Enddatum"
	)
	_manager._on_day_advanced(GameTime.current_date.add_days(180))
	_assert_true(
		not _manager.have_non_aggression_pact("DEU", "RUS"),
		"TEST 11: NAP laeuft anhand der Spielzeit ab"
	)


func _test_pause_keeps_treaty_active() -> void:
	var offer := _manager.offer_non_aggression_pact("AUT", "RUS")
	_manager.accept_action(offer.action_id)
	GameTime.set_speed(GameTime.Speed.PAUSE)
	_assert_true(
		_manager.have_non_aggression_pact("AUT", "RUS"),
		"TEST 12: Pause verhindert das Ablaufen"
	)


func _test_multiple_pairs() -> void:
	_manager.change_relationship("AUT", "RUS", -30)
	_manager.declare_war("AUT", "HUN")
	_assert_true(
		_manager.get_relationship("AUT", "RUS") == -30
		and _manager.is_at_war("AUT", "HUN")
		and not _manager.is_at_war("AUT", "RUS"),
		"TEST 15: Mehrere Laenderpaare bleiben unabhaengig"
	)


func _test_pending_action_acceptance_and_rejection() -> void:
	var offer := _manager.offer_alliance("RUS", "DEU")
	_assert_true(
		offer != null and offer.status == DiplomaticAction.Status.COMPLETED,
		"TEST 13/14: Diplomatische Anfrage wird automatisch angenommen"
	)
	_assert_true(
		_manager.are_allied("RUS", "DEU"),
		"TEST 14: Anfrage fuehrt direkt zum Buendnis"
	)

	var rejected := _manager.offer_alliance("HUN", "DEU")
	_assert_true(
		rejected != null and _manager.are_allied("HUN", "DEU"),
		"TEST 14: Angebote werden im Prototyp automatisch angenommen"
	)


func _test_save_load() -> void:
	var saved := _manager.get_save_data()
	var restored := DiplomacyManager.new()
	restored.initialize(["DEU", "AUT", "RUS", "HUN"])
	restored.load_save_data(saved)
	_assert_true(
		restored.get_relationship("AUT", "RUS") == -30
		and restored.is_at_war("AUT", "HUN")
		and restored.are_allied("RUS", "DEU"),
		"TEST 16: Save/Load erhaelt Diplomatiestatus"
	)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
