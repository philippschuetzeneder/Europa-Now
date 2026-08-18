class_name CombatCalculator
extends RefCounted

const MAX_COMBAT_DAYS := 5
const BROKEN_MORALE := 15.0
const BROKEN_ORGANIZATION := 15.0
const DAILY_CASUALTY_RATE := 0.04
const MIN_DAILY_LOSS_FRACTION := 0.005
const DAILY_MORALE_LOSS := 2.0
const DAILY_ORGANIZATION_LOSS := 3.0


static func morale_modifier(morale: float) -> float:
	return clampf(morale / 100.0, 0.1, 1.0)


static func organization_modifier(organization: float) -> float:
	return clampf(organization / 100.0, 0.1, 1.0)


static func combat_power_modifier(combat_power: int) -> float:
	return clampf(float(combat_power) / 100.0, 0.1, 2.0)


static func effective_strength(unit_data: UnitData) -> float:
	if unit_data.soldiers <= 0:
		return 0.0
	return (
		float(unit_data.soldiers)
		* combat_power_modifier(unit_data.combat_power)
		* morale_modifier(unit_data.morale)
		* organization_modifier(unit_data.organization)
	)


static func side_effective_strength(units: Array) -> float:
	var total := 0.0
	for unit in units:
		if unit is Unit:
			total += effective_strength(unit.data)
		elif unit is UnitData:
			total += effective_strength(unit)
	return total


static func side_soldiers(units: Array) -> int:
	var total := 0
	for unit in units:
		if unit is Unit:
			total += unit.data.soldiers
		elif unit is UnitData:
			total += unit.soldiers
	return total


static func calculate_daily_casualties(attacker_units: Array, defender_units: Array) -> Dictionary:
	var attacker_eff := side_effective_strength(attacker_units)
	var defender_eff := side_effective_strength(defender_units)
	var attacker_soldiers := side_soldiers(attacker_units)
	var defender_soldiers := side_soldiers(defender_units)

	if attacker_soldiers <= 0 and defender_soldiers <= 0:
		return {"attacker": 0, "defender": 0}

	var total_eff := attacker_eff + defender_eff
	if total_eff <= 0.0:
		return {"attacker": 0, "defender": 0}

	var attacker_share := defender_eff / total_eff
	var defender_share := attacker_eff / total_eff

	var attacker_loss := int(round(float(attacker_soldiers) * DAILY_CASUALTY_RATE * attacker_share))
	var defender_loss := int(round(float(defender_soldiers) * DAILY_CASUALTY_RATE * defender_share))

	attacker_loss = maxi(attacker_loss, int(float(attacker_soldiers) * MIN_DAILY_LOSS_FRACTION))
	defender_loss = maxi(defender_loss, int(float(defender_soldiers) * MIN_DAILY_LOSS_FRACTION))

	if attacker_soldiers <= 0:
		attacker_loss = 0
	if defender_soldiers <= 0:
		defender_loss = 0

	attacker_loss = mini(attacker_loss, attacker_soldiers)
	defender_loss = mini(defender_loss, defender_soldiers)

	return {"attacker": attacker_loss, "defender": defender_loss}


static func apply_daily_wear(unit_data: UnitData) -> void:
	unit_data.morale = maxf(0.0, unit_data.morale - DAILY_MORALE_LOSS)
	unit_data.organization = maxf(0.0, unit_data.organization - DAILY_ORGANIZATION_LOSS)


static func apply_casualties_to_side(units: Array, total_loss: int) -> int:
	if total_loss <= 0 or units.is_empty():
		return 0

	var living: Array = []
	var strength_sum := 0.0
	for unit in units:
		var data: UnitData = unit.data if unit is Unit else unit as UnitData
		if data.soldiers > 0:
			living.append(unit)
			strength_sum += maxf(effective_strength(data), 1.0)

	if living.is_empty():
		return 0

	var remaining_loss := total_loss
	var applied := 0
	for i in living.size():
		var unit = living[i]
		var data: UnitData = unit.data if unit is Unit else unit as UnitData
		var share: int
		if i == living.size() - 1:
			share = remaining_loss
		else:
			var weight := maxf(effective_strength(data), 1.0) / strength_sum
			share = int(round(float(total_loss) * weight))
		share = mini(share, remaining_loss)
		share = mini(share, data.soldiers)
		data.soldiers -= share
		data.casualties_this_battle += share
		applied += share
		remaining_loss -= share

	return applied


static func side_is_combat_broken(units: Array) -> bool:
	var has_fighters := false
	for unit in units:
		var data: UnitData = unit.data if unit is Unit else unit as UnitData
		if data.soldiers <= 0:
			continue
		has_fighters = true
		if data.morale < BROKEN_MORALE or data.organization < BROKEN_ORGANIZATION:
			return true
	return not has_fighters


static func side_has_soldiers(units: Array) -> bool:
	for unit in units:
		var data: UnitData = unit.data if unit is Unit else unit as UnitData
		if data.soldiers > 0:
			return true
	return false


static func determine_winner_side(attacker_units: Array, defender_units: Array) -> String:
	var attacker_eff := side_effective_strength(attacker_units)
	var defender_eff := side_effective_strength(defender_units)
	if is_equal_approx(attacker_eff, defender_eff):
		return "defender" if defender_eff >= attacker_eff else "attacker"
	return "attacker" if attacker_eff > defender_eff else "defender"


static func should_end_combat(
	attacker_units: Array,
	defender_units: Array,
	days_fought: int
) -> bool:
	if not side_has_soldiers(attacker_units) or not side_has_soldiers(defender_units):
		return true
	if side_is_combat_broken(attacker_units) or side_is_combat_broken(defender_units):
		return true
	return days_fought >= MAX_COMBAT_DAYS
