extends PanelContainer

@onready var _flag: TextureRect = $VBoxContainer/Header/FlagRect
@onready var _country_name: Label = $VBoxContainer/Header/CountryNameLabel
@onready var _province_label: Label = $VBoxContainer/ProvinceLabel
@onready var _head_of_state_label: Label = $VBoxContainer/HeadOfStateLabel
@onready var _government_label: Label = $VBoxContainer/GovernmentLabel
@onready var _population_label: Label = $VBoxContainer/PopulationLabel
@onready var _gdp_label: Label = $VBoxContainer/GdpLabel
@onready var _continent_label: Label = $VBoxContainer/ContinentLabel
@onready var _economy_label: Label = $VBoxContainer/EconomyLabel
@onready var _combat_label: Label = $VBoxContainer/CombatLabel
@onready var _war_label: Label = $VBoxContainer/WarLabel
@onready var _treasury_label: Label = $VBoxContainer/TreasuryLabel
@onready var _income_label: Label = $VBoxContainer/IncomeLabel
@onready var _expenses_label: Label = $VBoxContainer/ExpensesLabel
@onready var _military_budget_label: Label = $VBoxContainer/MilitaryBudgetLabel
@onready var _recruitable_label: Label = $VBoxContainer/RecruitableLabel
@onready var _recruitment_header: Label = $VBoxContainer/RecruitmentHeader
@onready var _recruit_province_label: Label = $VBoxContainer/RecruitProvinceLabel
@onready var _recruit_soldiers: SpinBox = $VBoxContainer/RecruitSoldiersSpinBox
@onready var _recruit_cost_label: Label = $VBoxContainer/RecruitCostLabel
@onready var _recruit_duration_label: Label = $VBoxContainer/RecruitDurationLabel
@onready var _recruit_manpower_label: Label = $VBoxContainer/RecruitManpowerLabel
@onready var _recruit_button: Button = $VBoxContainer/RecruitButton
@onready var _recruit_error_label: Label = $VBoxContainer/RecruitErrorLabel
@onready var _diplomacy_header: Label = $VBoxContainer/DiplomacyHeader
@onready var _diplomacy_target: OptionButton = $VBoxContainer/DiplomacyTargetOption
@onready var _diplomacy_relations: Label = $VBoxContainer/DiplomacyRelationsLabel
@onready var _diplomacy_relations_toggle: Button = $VBoxContainer/DiplomacyRelationsToggle
@onready var _diplomacy_relations_scroll: ScrollContainer = $VBoxContainer/DiplomacyRelationsScroll
@onready var _diplomacy_all_relations: Label = $VBoxContainer/DiplomacyRelationsScroll/DiplomacyAllRelationsLabel
@onready var _diplomacy_relationship: Label = $VBoxContainer/DiplomacyRelationshipLabel
@onready var _diplomacy_status: Label = $VBoxContainer/DiplomacyStatusLabel
@onready var _diplomacy_alliance: Label = $VBoxContainer/DiplomacyAllianceLabel
@onready var _diplomacy_nap: Label = $VBoxContainer/DiplomacyNapLabel
@onready var _declare_war_button: Button = $VBoxContainer/DiplomacyActionGrid/DeclareWarButton
@onready var _offer_peace_button: Button = $VBoxContainer/DiplomacyActionGrid/OfferPeaceButton
@onready var _offer_alliance_button: Button = $VBoxContainer/DiplomacyActionGrid/OfferAllianceButton
@onready var _offer_nap_button: Button = $VBoxContainer/DiplomacyActionGrid/OfferNapButton
@onready var _diplomacy_pending_label: Label = $VBoxContainer/DiplomacyPendingLabel
@onready var _accept_diplomacy_button: Button = $VBoxContainer/AcceptDiplomacyButton
@onready var _reject_diplomacy_button: Button = $VBoxContainer/RejectDiplomacyButton

var _countries_by_id: Dictionary = {}
var _economy_manager: EconomyManager
var _diplomacy_manager: DiplomacyManager
var _selected_country_id := ""
var _selected_province: Province
var _diplomacy_target_id := ""
var _diplomacy_view_country_id := ""
var _pending_diplomatic_action_id := ""
var _confirmation_dialog: ConfirmationDialog


func _ready() -> void:
	_recruit_button.pressed.connect(_on_recruit_button_pressed)
	_recruit_soldiers.value_changed.connect(_on_recruit_amount_changed)
	_diplomacy_target.item_selected.connect(_on_diplomacy_target_selected)
	_diplomacy_relations_toggle.pressed.connect(_on_relations_toggle_pressed)
	_declare_war_button.pressed.connect(_on_declare_war_pressed)
	_offer_peace_button.pressed.connect(_on_offer_peace_pressed)
	_offer_alliance_button.pressed.connect(_on_offer_alliance_pressed)
	_offer_nap_button.pressed.connect(_on_offer_nap_pressed)
	_accept_diplomacy_button.pressed.connect(_on_accept_diplomacy_pressed)
	_reject_diplomacy_button.pressed.connect(_on_reject_diplomacy_pressed)
	_confirmation_dialog = ConfirmationDialog.new()
	_confirmation_dialog.confirmed.connect(_on_war_confirmed)
	add_child(_confirmation_dialog)
	_hide_diplomacy_controls()
	_hide_recruitment_controls()
	_combat_label.visible = false
	for detail_label in [
		_head_of_state_label,
		_government_label,
		_population_label,
		_gdp_label,
		_economy_label,
		_war_label,
		_treasury_label,
		_income_label,
		_expenses_label,
		_military_budget_label,
		_recruitable_label,
	]:
		detail_label.add_theme_font_size_override("font_size", 12)
	show_empty()


func set_countries_lookup(countries_by_id: Dictionary) -> void:
	_countries_by_id = countries_by_id


func set_economy_manager(manager: EconomyManager) -> void:
	_economy_manager = manager
	if not _selected_country_id.is_empty():
		refresh_economy(_selected_country_id)


func set_diplomacy_manager(manager: DiplomacyManager) -> void:
	_diplomacy_manager = manager
	if _diplomacy_manager != null:
		_diplomacy_manager.relationship_changed.connect(_on_diplomacy_changed)
		_diplomacy_manager.treaty_created.connect(_on_treaty_changed)
		_diplomacy_manager.treaty_expired.connect(_on_treaty_changed)
		_diplomacy_manager.diplomatic_action_received.connect(_on_action_changed)
		_diplomacy_manager.diplomatic_action_resolved.connect(_on_action_changed)
		refresh_diplomacy()


func show_country(country: Country, keep_province: bool = false) -> void:
	_selected_country_id = country.country_id
	_flag.texture = FlagFactory.get_flag_texture(country)
	_country_name.text = country.display_name
	_head_of_state_label.text = "Staatsoberhaupt: %s" % country.head_of_state
	_government_label.text = "Regierung: %s" % country.government_type
	_population_label.text = "Bevoelkerung (2024): %s" % _format_population(country.population)
	_gdp_label.text = "BIP: %s" % _format_gdp(country.gdp_million)
	_continent_label.text = "Kontinent: %s" % country.continent
	_economy_label.text = "Wirtschaft: %s" % _clean_economy_label(country.economy)
	_province_label.visible = false
	_set_details_visible(true)
	refresh_economy(country.country_id)
	refresh_diplomacy_for_country(country.country_id)
	if not keep_province:
		_selected_province = null
		_hide_recruitment_controls()


func show_province(province: Province) -> void:
	_selected_province = province
	_province_label.text = "Provinz: %s (Kontrolle: %s)" % [province.display_name, province.controller_country_id]
	_province_label.visible = true


func show_recruitment_for_province(province: Province) -> void:
	_selected_province = province
	_recruitment_header.visible = true
	_recruit_province_label.visible = true
	_recruit_soldiers.visible = true
	_recruit_cost_label.visible = true
	_recruit_duration_label.visible = true
	_recruit_manpower_label.visible = true
	_recruit_button.visible = true
	_recruit_error_label.visible = true
	_recruit_province_label.text = "Provinz: %s" % province.display_name
	_recruit_error_label.text = ""
	_update_recruitment_preview()


func refresh_recruitment() -> void:
	if _selected_province != null:
		show_recruitment_for_province(_selected_province)


func show_recruitment_error(message: String) -> void:
	_recruit_error_label.text = message
	_recruit_error_label.visible = true


func refresh_economy(country_id: String) -> void:
	if _economy_manager == null or country_id.is_empty():
		return
	var economy: CountryEconomy = _economy_manager.get_economy(country_id)
	if economy == null:
		return
	_treasury_label.text = "Staatskasse: %s" % _format_money(economy.treasury)
	_income_label.text = "Einkommen: %s / Monat" % _format_money(economy.income)
	_expenses_label.text = "Ausgaben: %s / Monat" % _format_money(economy.expenses)
	_military_budget_label.text = "Militaerbudget: %s" % _format_money(economy.military_budget)
	_recruitable_label.text = (
		"Rekrutierbares Personal: %s"
		% _format_population(economy.available_recruitable_population())
	)
	_treasury_label.visible = true
	_income_label.visible = true
	_expenses_label.visible = true
	_military_budget_label.visible = true
	_recruitable_label.visible = true
	_update_recruitment_preview()


func _on_recruit_button_pressed() -> void:
	if _economy_manager == null or _selected_province == null:
		return
	var order: RecruitmentOrder = _economy_manager.create_recruitment_order(
		_selected_country_id,
		_selected_province.province_id,
		int(_recruit_soldiers.value)
	)
	if order == null:
		return
	_recruit_error_label.text = "Auftrag angenommen: %s" % order.completion_date.format_long()
	refresh_economy(_selected_country_id)
	refresh_recruitment()


func _on_recruit_amount_changed(_value: float) -> void:
	_update_recruitment_preview()


func _update_recruitment_preview() -> void:
	if _economy_manager == null or _selected_country_id.is_empty():
		return
	var preview: Dictionary = _economy_manager.preview_recruitment(
		_selected_country_id,
		int(_recruit_soldiers.value)
	)
	_recruit_cost_label.text = "Kosten: %s" % _format_money(int(preview["cost"]))
	_recruit_duration_label.text = "Ausbildungszeit: %d Tage" % int(preview["days"])
	var economy: CountryEconomy = _economy_manager.get_economy(_selected_country_id)
	if economy != null:
		_recruit_manpower_label.text = (
			"Verfuegbar: %s"
			% _format_population(economy.available_recruitable_population())
		)
	_recruit_button.disabled = (
		_selected_province == null
		or _selected_province.controller_country_id != _selected_country_id
	)


func show_war_status(country_id: String, war_state: WarState) -> void:
	if war_state == null:
		_war_label.visible = false
		return
	var enemies: Array[String] = war_state.get_enemies(country_id)
	if enemies.is_empty():
		_war_label.text = "Krieg: Frieden"
	else:
		var names: PackedStringArray = []
		for enemy_id in enemies:
			var country: Country = _countries_by_id.get(enemy_id)
			names.append(country.display_name if country != null else enemy_id)
		_war_label.text = "Krieg gegen: %s" % ", ".join(names)
	_war_label.visible = true


func show_unit(unit: Unit) -> void:
	var country: Country = _countries_by_id.get(unit.data.owner_country_id)
	if country != null:
		show_country(country, true)
	_combat_label.text = (
		"Einheit: %s\nSoldaten: %s\nKampfst. %.0f\nMoral: %.0f\nOrganisation: %.0f\nVerluste: %s"
		% [
			unit.data.unit_id,
			_format_population(unit.data.soldiers),
			unit.data.effective_strength(),
			unit.data.morale,
			unit.data.organization,
			_format_population(unit.data.casualties_this_battle),
		]
	)
	_combat_label.visible = true


func show_combat(combat: CombatState, unit_manager: UnitManager) -> void:
	if combat == null:
		hide_combat()
		return

	var lines: PackedStringArray = []
	lines.append("KAMPF")
	lines.append("")
	lines.append(_format_combat_side("Angreifer", combat.attacker_country_ids, combat.attacker_unit_ids, combat.attacker_casualties, unit_manager))
	lines.append("")
	lines.append(_format_combat_side("Verteidiger", combat.defender_country_ids, combat.defender_unit_ids, combat.defender_casualties, unit_manager))
	lines.append("")
	lines.append("Kampfdauer: %dh" % combat.get_duration_hours())
	lines.append("Status: %s" % _combat_status_text(combat, unit_manager))
	_combat_label.text = "\n".join(lines)
	_combat_label.visible = true


func hide_combat() -> void:
	_combat_label.text = ""
	_combat_label.visible = false


func show_empty() -> void:
	_flag.texture = FlagFactory.get_placeholder_texture()
	_country_name.text = "Kein Land ausgewaehlt"
	_province_label.visible = false
	_war_label.visible = false
	hide_combat()
	_hide_recruitment_controls()
	_treasury_label.visible = false
	_income_label.visible = false
	_expenses_label.visible = false
	_military_budget_label.visible = false
	_recruitable_label.visible = false
	_hide_diplomacy_controls()
	_set_details_visible(false)


func refresh_diplomacy_for_country(country_id: String) -> void:
	if _diplomacy_manager == null:
		return
	_diplomacy_view_country_id = country_id
	if country_id == _diplomacy_manager.player_country_id:
		_select_first_diplomacy_target()
	else:
		_set_diplomacy_target(country_id)
	refresh_diplomacy()


func refresh_diplomacy() -> void:
	if _diplomacy_manager == null or _countries_by_id.is_empty():
		return
	_diplomacy_header.visible = true
	_diplomacy_target.visible = true
	_diplomacy_relations.visible = true
	_diplomacy_relations_toggle.visible = true
	_diplomacy_relations_scroll.visible = false
	_diplomacy_relationship.visible = true
	_diplomacy_status.visible = true
	_diplomacy_alliance.visible = true
	_diplomacy_nap.visible = true
	_declare_war_button.visible = true
	_offer_peace_button.visible = true
	_offer_alliance_button.visible = true
	_offer_nap_button.visible = true
	_diplomacy_pending_label.visible = false
	_diplomacy_target.clear()
	for country_id in _countries_by_id:
		if str(country_id) == _diplomacy_manager.player_country_id:
			continue
		var country: Country = _countries_by_id[country_id]
		_diplomacy_target.add_item(country.display_name)
		_diplomacy_target.set_item_metadata(_diplomacy_target.item_count - 1, country.country_id)
	if _diplomacy_target_id.is_empty() or _countries_by_id.get(_diplomacy_target_id) == null:
		_select_first_diplomacy_target()
	else:
		_select_diplomacy_option(_diplomacy_target_id)
	_update_diplomacy_details()


func _update_diplomacy_details() -> void:
	if _diplomacy_manager == null or _diplomacy_target_id.is_empty():
		return
	var source: String = _diplomacy_manager.player_country_id
	var relation_source: String = (
		_diplomacy_view_country_id
		if not _diplomacy_view_country_id.is_empty()
		else source
	)
	var target: String = _diplomacy_target_id
	var target_country: Country = _countries_by_id.get(target)
	var target_name: String = target_country.display_name if target_country != null else target
	_diplomacy_relationship.text = (
		"Beziehung zu %s: %d" % [target_name, _diplomacy_manager.get_relationship(source, target)]
	)
	var relation_source_country: Country = _countries_by_id.get(relation_source)
	var relation_source_name: String = (
		relation_source_country.display_name
		if relation_source_country != null
		else relation_source
	)
	var priority_lines: PackedStringArray = [
		"Wichtige Beziehungen von %s:" % relation_source_name
	]
	var all_relation_lines: PackedStringArray = []
	for country_id in _countries_by_id:
		var relation_country_id: String = str(country_id)
		if relation_country_id == relation_source:
			continue
		var relation_country: Country = _countries_by_id[country_id]
		var relation_name: String = (
			relation_country.display_name
			if relation_country != null
			else relation_country_id
		)
		var relation_score: int = _diplomacy_manager.get_relationship(
			relation_source,
			relation_country_id
		)
		var is_priority: bool = (
			relation_score != 0
			or _diplomacy_manager.is_at_war(relation_source, relation_country_id)
			or _diplomacy_manager.are_allied(relation_source, relation_country_id)
			or _diplomacy_manager.have_non_aggression_pact(relation_source, relation_country_id)
		)
		var relation_text: String = "%s: %d" % [relation_name, relation_score]
		all_relation_lines.append(relation_text)
		if is_priority:
			priority_lines.append(
				relation_text
			)
	_diplomacy_relations.text = "\n".join(priority_lines)
	if priority_lines.size() == 1:
		_diplomacy_relations.text = (
			"Wichtige Beziehungen von %s: keine" % relation_source_name
		)
	_diplomacy_all_relations.text = "\n".join(all_relation_lines)
	_diplomacy_relations_toggle.text = (
		"Alle Beziehungen anzeigen (%d)" % all_relation_lines.size()
	)
	_diplomacy_status.text = (
		"Status: Krieg" if _diplomacy_manager.is_at_war(source, target) else "Status: Frieden"
	)
	_diplomacy_alliance.text = (
		"Buendnis: %s" % ("Ja" if _diplomacy_manager.are_allied(source, target) else "Nein")
	)
	_diplomacy_nap.text = (
		"Nichtangriffspakt: %s"
		% ("Ja" if _diplomacy_manager.have_non_aggression_pact(source, target) else "Nein")
	)
	_declare_war_button.disabled = _diplomacy_manager.is_at_war(source, target)
	_offer_peace_button.disabled = not _diplomacy_manager.is_at_war(source, target)
	_offer_alliance_button.disabled = (
		_diplomacy_manager.is_at_war(source, target)
		or _diplomacy_manager.are_allied(source, target)
	)
	_offer_nap_button.disabled = (
		_diplomacy_manager.is_at_war(source, target)
		or _diplomacy_manager.have_non_aggression_pact(source, target)
	)
	_update_pending_action()


func _select_first_diplomacy_target() -> void:
	if _diplomacy_manager == null:
		return
	for country_id in _countries_by_id:
		if str(country_id) != _diplomacy_manager.player_country_id:
			_diplomacy_target_id = str(country_id)
			return


func _set_diplomacy_target(country_id: String) -> void:
	if country_id != _diplomacy_manager.player_country_id:
		_diplomacy_target_id = country_id


func _select_diplomacy_option(country_id: String) -> void:
	for index in _diplomacy_target.item_count:
		if str(_diplomacy_target.get_item_metadata(index)) == country_id:
			_diplomacy_target.select(index)
			return


func _on_diplomacy_target_selected(index: int) -> void:
	_diplomacy_target_id = str(_diplomacy_target.get_item_metadata(index))
	_update_diplomacy_details()


func _on_relations_toggle_pressed() -> void:
	_diplomacy_relations_scroll.visible = not _diplomacy_relations_scroll.visible
	_diplomacy_relations_toggle.text = (
		"Beziehungen einklappen"
		if _diplomacy_relations_scroll.visible
		else "Alle Beziehungen anzeigen (%d)" % (_countries_by_id.size() - 1)
	)


func _on_declare_war_pressed() -> void:
	if _diplomacy_manager == null:
		return
	var target_country: Country = _countries_by_id.get(_diplomacy_target_id)
	var target_name: String = _diplomacy_target_id
	if target_country != null:
		target_name = target_country.display_name
	_confirmation_dialog.dialog_text = "Willst du %s den Krieg erklaeren?" % target_name
	_confirmation_dialog.popup_centered()


func _on_war_confirmed() -> void:
	_diplomacy_manager.declare_war(
		_diplomacy_manager.player_country_id,
		_diplomacy_target_id
	)


func _on_offer_peace_pressed() -> void:
	_diplomacy_manager.offer_peace(
		_diplomacy_manager.player_country_id,
		_diplomacy_target_id
	)


func _on_offer_alliance_pressed() -> void:
	_diplomacy_manager.offer_alliance(
		_diplomacy_manager.player_country_id,
		_diplomacy_target_id
	)


func _on_offer_nap_pressed() -> void:
	_diplomacy_manager.offer_non_aggression_pact(
		_diplomacy_manager.player_country_id,
		_diplomacy_target_id
	)


func _update_pending_action() -> void:
	_pending_diplomatic_action_id = ""
	_diplomacy_pending_label.text = ""
	_diplomacy_pending_label.visible = false
	_accept_diplomacy_button.visible = false
	_reject_diplomacy_button.visible = false
	for action in _diplomacy_manager.get_pending_actions():
		if (
			action.target_country_id == _diplomacy_manager.player_country_id
			and action.source_country_id == _diplomacy_target_id
		):
			_pending_diplomatic_action_id = action.action_id
			_diplomacy_pending_label.text = (
				"%s bietet %s an."
				% [action.source_country_id, _action_name(action.action_type)]
			)
			_diplomacy_pending_label.visible = true
			_accept_diplomacy_button.visible = true
			_reject_diplomacy_button.visible = true
			return


func _on_accept_diplomacy_pressed() -> void:
	if not _pending_diplomatic_action_id.is_empty():
		_diplomacy_manager.accept_action(_pending_diplomatic_action_id)


func _on_reject_diplomacy_pressed() -> void:
	if not _pending_diplomatic_action_id.is_empty():
		_diplomacy_manager.reject_action(_pending_diplomatic_action_id)


func _action_name(action_type: String) -> String:
	match action_type:
		DiplomacyManager.ACTION_OFFER_NAP:
			return "einen Nichtangriffspakt"
		DiplomacyManager.ACTION_OFFER_ALLIANCE:
			return "ein Buendnis"
		DiplomacyManager.ACTION_OFFER_PEACE:
			return "Frieden"
		_:
			return action_type


func _hide_diplomacy_controls() -> void:
	_diplomacy_header.visible = false
	_diplomacy_target.visible = false
	_diplomacy_relations.visible = false
	_diplomacy_relations_toggle.visible = false
	_diplomacy_relations_scroll.visible = false
	_diplomacy_relationship.visible = false
	_diplomacy_status.visible = false
	_diplomacy_alliance.visible = false
	_diplomacy_nap.visible = false
	_declare_war_button.visible = false
	_offer_peace_button.visible = false
	_offer_alliance_button.visible = false
	_offer_nap_button.visible = false
	_diplomacy_pending_label.visible = false
	_accept_diplomacy_button.visible = false
	_reject_diplomacy_button.visible = false


func _on_diplomacy_changed(_country_a: String, _country_b: String, _score: int) -> void:
	refresh_diplomacy()


func _on_treaty_changed(_treaty: DiplomaticTreaty) -> void:
	refresh_diplomacy()


func _on_action_changed(_action: DiplomaticAction) -> void:
	refresh_diplomacy()


func _hide_recruitment_controls() -> void:
	_recruitment_header.visible = false
	_recruit_province_label.visible = false
	_recruit_soldiers.visible = false
	_recruit_cost_label.visible = false
	_recruit_duration_label.visible = false
	_recruit_manpower_label.visible = false
	_recruit_button.visible = false
	_recruit_error_label.visible = false


func _set_details_visible(visible: bool) -> void:
	_head_of_state_label.visible = visible
	_government_label.visible = visible
	_population_label.visible = visible
	_gdp_label.visible = visible
	_continent_label.visible = false
	_economy_label.visible = visible


func _format_money(value: int) -> String:
	return "€ %s" % _format_compact(value)


func _format_combat_side(
	side_label: String,
	country_ids: Array[String],
	unit_ids: Array[String],
	casualties: int,
	unit_manager: UnitManager
) -> String:
	var country_names: PackedStringArray = []
	for country_id in country_ids:
		var country: Country = _countries_by_id.get(country_id)
		country_names.append(country.display_name if country != null else country_id)

	var soldiers := 0
	var strength := 0.0
	var morale_sum := 0.0
	var org_sum := 0.0
	var count := 0
	for unit_id in unit_ids:
		var unit: Unit = unit_manager.get_unit(unit_id)
		if unit == null:
			continue
		soldiers += unit.data.soldiers
		strength += unit.data.effective_strength()
		morale_sum += unit.data.morale
		org_sum += unit.data.organization
		count += 1

	var morale := morale_sum / maxf(float(count), 1.0)
	var org := org_sum / maxf(float(count), 1.0)
	return (
		"%s: %s\n%s Soldaten\nKampfst. %.0f\nMoral: %.0f\nOrganisation: %.0f\nVerluste: %s"
		% [
			side_label,
			", ".join(country_names),
			_format_population(soldiers),
			strength,
			morale,
			org,
			_format_population(casualties),
		]
	)


func _combat_status_text(combat: CombatState, unit_manager: UnitManager) -> String:
	if not combat.is_active():
		if combat.winner_side == "attacker":
			return _country_names(combat.attacker_country_ids) + " siegt"
		return _country_names(combat.defender_country_ids) + " siegt"

	var attacker_units: Array = _get_units(combat.attacker_unit_ids, unit_manager)
	var defender_units: Array = _get_units(combat.defender_unit_ids, unit_manager)
	var attacker_eff: float = CombatCalculator.side_effective_strength(attacker_units)
	var defender_eff: float = CombatCalculator.side_effective_strength(defender_units)
	if attacker_eff > defender_eff:
		return _country_names(combat.attacker_country_ids) + " gewinnt"
	if defender_eff > attacker_eff:
		return _country_names(combat.defender_country_ids) + " gewinnt"
	return "Ausgeglichen"


func _country_names(country_ids: Array[String]) -> String:
	var names: PackedStringArray = []
	for country_id in country_ids:
		var country: Country = _countries_by_id.get(country_id)
		names.append(country.display_name if country != null else country_id)
	return ", ".join(names)


func _get_units(unit_ids: Array[String], unit_manager: UnitManager) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit_id in unit_ids:
		var unit: Unit = unit_manager.get_unit(unit_id)
		if unit != null:
			result.append(unit)
	return result


func _format_population(value: int) -> String:
	if value <= 0:
		return "0"
	return _format_compact(value)


func _format_gdp(value: int) -> String:
	if value <= 0:
		return "k. A."
	if value >= 1_000_000:
		return "$%.1f Bio." % (value / 1_000_000.0)
	if value >= 1_000:
		return "$%.1f Mrd." % (value / 1_000.0)
	return "$%s Mio." % _with_thousands_separator(value)


func _with_thousands_separator(value: int) -> String:
	var text := str(value)
	var result := ""
	for i in text.length():
		if i > 0 and (text.length() - i) % 3 == 0:
			result += "."
		result += text[i]
	return result


func _format_compact(value: int) -> String:
	var absolute_value := absi(value)
	var number := float(absolute_value)
	var suffix := ""
	if absolute_value >= 1_000_000_000:
		number /= 1_000_000_000.0
		suffix = " Mrd."
	elif absolute_value >= 1_000_000:
		number /= 1_000_000.0
		suffix = " Mio."
	elif absolute_value >= 1_000:
		number /= 1_000.0
		suffix = " K"
	if suffix.is_empty():
		return str(value)
	return "%s%.1f%s" % ["-" if value < 0 else "", number, suffix]


func _clean_economy_label(raw: String) -> String:
	if raw.is_empty():
		return "k. A."
	var parts := raw.split(": ", false, 1)
	if parts.size() == 2:
		return parts[1]
	return raw
