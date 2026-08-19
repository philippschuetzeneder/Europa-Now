class_name DiplomacyPanel
extends PanelContainer

signal closed

@onready var _title: Label = $Margin/VBox/Title
@onready var _relationship: Label = $Margin/VBox/Relationship
@onready var _status: Label = $Margin/VBox/Status
@onready var _alliance: Label = $Margin/VBox/Alliance
@onready var _nap: Label = $Margin/VBox/Nap
@onready var _war_button: Button = $Margin/VBox/Actions/DeclareWar
@onready var _peace_button: Button = $Margin/VBox/Actions/OfferPeace
@onready var _alliance_button: Button = $Margin/VBox/Actions/OfferAlliance
@onready var _nap_button: Button = $Margin/VBox/Actions/OfferNap
@onready var _close_button: Button = $Margin/VBox/Close

var _diplomacy_manager: DiplomacyManager
var _countries_by_id: Dictionary = {}
var _target_country_id := ""
var _confirmation_dialog: ConfirmationDialog


func _ready() -> void:
	_war_button.pressed.connect(_declare_war)
	_peace_button.pressed.connect(_offer_peace)
	_alliance_button.pressed.connect(_offer_alliance)
	_nap_button.pressed.connect(_offer_nap)
	_close_button.pressed.connect(_close)
	_confirmation_dialog = ConfirmationDialog.new()
	_confirmation_dialog.confirmed.connect(_confirm_war)
	add_child(_confirmation_dialog)
	visible = false


func setup(manager: DiplomacyManager, countries_by_id: Dictionary) -> void:
	_diplomacy_manager = manager
	_countries_by_id = countries_by_id
	if not _diplomacy_manager.relationship_changed.is_connected(_on_diplomacy_changed):
		_diplomacy_manager.relationship_changed.connect(_on_diplomacy_changed)
	if not _diplomacy_manager.treaty_created.is_connected(_on_treaty_changed):
		_diplomacy_manager.treaty_created.connect(_on_treaty_changed)
	if not _diplomacy_manager.treaty_expired.is_connected(_on_treaty_changed):
		_diplomacy_manager.treaty_expired.connect(_on_treaty_changed)


func show_for_country(country_id: String) -> void:
	if _diplomacy_manager == null:
		return
	if country_id == _diplomacy_manager.player_country_id:
		return
	_target_country_id = country_id
	visible = true
	_refresh()


func _refresh() -> void:
	var source := _diplomacy_manager.player_country_id
	var country: Country = _countries_by_id.get(_target_country_id)
	var target_name: String = country.display_name if country != null else _target_country_id
	_title.text = "Diplomatie: Deutschland – %s" % target_name
	_relationship.text = "Beziehung: %d" % _diplomacy_manager.get_relationship(source, _target_country_id)
	var at_war := _diplomacy_manager.is_at_war(source, _target_country_id)
	_status.text = "Status: %s" % ("Krieg" if at_war else "Frieden")
	_alliance.text = "Buendnis: %s" % ("Ja" if _diplomacy_manager.are_allied(source, _target_country_id) else "Nein")
	_nap.text = "Nichtangriffspakt: %s" % ("Ja" if _diplomacy_manager.have_non_aggression_pact(source, _target_country_id) else "Nein")
	_war_button.disabled = at_war
	_peace_button.disabled = not at_war
	_alliance_button.disabled = at_war or _diplomacy_manager.are_allied(source, _target_country_id)
	_nap_button.disabled = at_war or _diplomacy_manager.have_non_aggression_pact(source, _target_country_id)


func _declare_war() -> void:
	var country: Country = _countries_by_id.get(_target_country_id)
	var target_name: String = country.display_name if country != null else _target_country_id
	_confirmation_dialog.dialog_text = "Willst du %s den Krieg erklaeren?" % target_name
	_confirmation_dialog.popup_centered()


func _confirm_war() -> void:
	_diplomacy_manager.declare_war(
		_diplomacy_manager.player_country_id,
		_target_country_id
	)
	_refresh()


func _offer_peace() -> void:
	_diplomacy_manager.offer_peace(_diplomacy_manager.player_country_id, _target_country_id)
	_refresh()


func _offer_alliance() -> void:
	_diplomacy_manager.offer_alliance(_diplomacy_manager.player_country_id, _target_country_id)
	_refresh()


func _offer_nap() -> void:
	_diplomacy_manager.offer_non_aggression_pact(_diplomacy_manager.player_country_id, _target_country_id)
	_refresh()


func _close() -> void:
	close_panel()


func close_panel() -> void:
	visible = false
	if _confirmation_dialog != null:
		_confirmation_dialog.hide()
	closed.emit()


func _on_diplomacy_changed(_a: String, _b: String, _score: int) -> void:
	if visible:
		_refresh()


func _on_treaty_changed(_treaty: DiplomaticTreaty) -> void:
	if visible:
		_refresh()
