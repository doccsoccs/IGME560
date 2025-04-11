extends Node2D

@onready var grid = $"../IsometricGrid"

var units: Array[Unit]
var player_units: Array[Unit]
var enemy_units: Array[Unit]

# Type Multipliers
const neutral: float = 1.0
const effective: float = 2.0
const ineffective: float = 0.5

func _ready():
	# Get an array containing all player units
	for unit in get_children():
		if unit is Unit:
			units.push_back(unit)
			if unit.is_player:
				player_units.push_back(unit)

# Returns an array containing all positions of active units
func get_all_unit_positions() -> Array[Vector2i]:
	var unit_positions: Array[Vector2i] = []
	for unit in units:
		unit_positions.push_back(unit.current_tile)
	return unit_positions

# Checks the full unit array for a unit at some position
# Returns that unit if exists
func get_unit_at_tile(tile: Vector2i) -> Unit:
	for unit in units:
		if unit.current_tile == tile:
			return unit
	return null

# Returns an array of units that are detected within a set of tiles
func get_units_in_tile_list(tiles: Array[Vector2i]) -> Array[Unit]:
	var attacked_units: Array[Unit] = []
	for tile in tiles:
		var temp: Unit = get_unit_at_tile(tile)
		if temp != null:
			attacked_units.push_back(temp)
	return attacked_units

# Returns a multiplier based on type matchup
# Neutral = 1.0, Ineffective = 0.5, Effective = 2.0
func type_matchup(attacker: Unit, defender: Unit) -> float:
	# Water > Earth
	if attacker.attack_type == Unit.typing.water and defender.type == Unit.typing.earth:
		return effective
	elif attacker.attack_type == Unit.typing.earth and defender.type == Unit.typing.water:
		return ineffective
	
	# Earth > Fire
	elif attacker.attack_type == Unit.typing.earth and defender.type == Unit.typing.fire:
		return effective
	elif attacker.attack_type == Unit.typing.fire and defender.type == Unit.typing.earth:
		return ineffective
	
	# Fire > Air
	elif attacker.attack_type == Unit.typing.fire and defender.type == Unit.typing.air:
		return effective
	elif attacker.attack_type == Unit.typing.air and defender.type == Unit.typing.fire:
		return ineffective
	
	# Air > Water
	elif attacker.attack_type == Unit.typing.air and defender.type == Unit.typing.water:
		return effective
	elif attacker.attack_type == Unit.typing.water and defender.type == Unit.typing.air:
		return ineffective
	
	# Shadow > Light & Light > Shadow
	elif attacker.attack_type == Unit.typing.shadow and defender.type == Unit.typing.light:
		return effective
	elif attacker.attack_type == Unit.typing.light and defender.type == Unit.typing.shadow:
		return effective
	
	# Neutral matchup
	else:
		return neutral

# Recieves references to two different units
# returns the damage that the attacker would deal to the defender
func calc_damage_for_display(attacker: Unit, defender: Unit) -> int:
	# Damage = ({[base power * (attack/defense)]/50} + 2) * (TYPE)
	var f: float = ((float(attacker.attack_base_power) \
			* (float(attacker.attack)/float(defender.defense)))/50 + 2) \
			* type_matchup(attacker, defender)
	return int(f)

func calc_damage(attacker: Unit, defender: Unit):
	# Crit change = (attacker.skill/2) / 100
	var crit: float = 1.0
	if randf_range(0,100) < float(attacker.skill)/2:
		crit = 1.5
	
	# Damage = ({[base power * (attack/defense)]/50} + 2) * (TYPE) * (RANDOM) * (CRIT)
	var f: float = ((float(attacker.attack_base_power) \
			* (float(attacker.attack)/float(defender.defense)))/50 + 2) \
			* type_matchup(attacker, defender) \
			* randf_range(0.9, 1.1) \
			* crit
	return int(f)
