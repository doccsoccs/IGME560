extends Node2D

@onready var grid = $"../IsometricGrid"

@export_category("AI")
@export var ai_type: ai_types
enum ai_types{
	point_values,
	damage_only,
	random
}
# Modifiers for "point based" utility decision making
const util_players_damaged: int = 1
const util_players_killed: int = 10
const util_enemies_damaged: int = -2
const util_enemies_killed: int = -20
const util_damage: float = 0.25

# Tracks units and subgroups of units
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
			else:
				enemy_units.push_back(unit)
	
	ResultsTracker.ai_type_used = ai_type

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
	var detected_units: Array[Unit] = []
	for tile in tiles:
		var temp: Unit = get_unit_at_tile(tile)
		if temp != null:
			detected_units.push_back(temp)
	return detected_units

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

# Actual damage calculation
func calc_damage(attacker: Unit, defender: Unit) -> int:
	# Crit change = (attacker.skill/2) / 100
	var crit: float = 1.0
	if randf_range(0,100) < float(attacker.skill)/2:
		crit = 1.5
		defender.crit_indicator.display_crit()
	
	# Damage = ({[base power * (attack/defense)]/50} + 2) * (TYPE) * (RANDOM) * (CRIT)
	var f: float = ((float(attacker.attack_base_power) \
			* (float(attacker.attack)/float(defender.defense)))/50 + 2) \
			* type_matchup(attacker, defender) \
			* randf_range(0.9, 1.1) \
			* crit
	return int(f)

# Checks to see if all units on a side have expended their turn
# Switch turns if they are all expended
func handle_end_turn(player_turn: bool):
	if player_turn:
		for unit in player_units:
			if unit.current_game_state != unit.game_state.expended:
				await get_tree().create_timer(1.0).timeout
				grid.camera_component.move_camera(unit.current_tile)
				grid.move_selector(unit.current_tile)
				grid.set_control_mode(grid.control_mode.free)
				return
		
		# If all units are expended, switch turns
		grid.toggle_turn()
		
		# Start enemy unit turns
		next_enemy_move()
	
	# Checks during enemy turn
	else:
		await get_tree().create_timer(1.0).timeout
		emit_signal("enemy_finished_move")
		for unit in enemy_units:
			if unit.current_game_state != unit.game_state.expended:
				return
		grid.toggle_turn()

# Initiates the next enemy move during the enemy turn
func next_enemy_move():
	await get_tree().create_timer(1.2).timeout
	for enemy in enemy_units:
		grid.camera_component.move_camera(enemy.current_tile)
		await get_tree().create_timer(0.5).timeout
		if enemy.current_game_state != enemy.game_state.expended:
			# Retrieves a dictionary of potential movements the enemy can take
			# Contains the details for attacking in a given direction 
			var move_dictionary = create_move_dictionary(enemy)
			
			# Holds the next move
			var next_move
			
			# CASE: MAKE RANDOM MOVES
			if ai_type == ai_types.random:
				next_move = get_random_move(move_dictionary)
			
			# CASE: NON-RANDOM MOVE
			# Determine the best position to move and attack to based on this dictionary
			else:
				next_move = get_best_move(move_dictionary, enemy)
			
			# Perform the move by doing the following:
			# 1) move IF the tile to move to is different from the current
			# 2) attack in the given direction UNLESS the output was -1, then wait
			var new_tile: Vector2i = next_move[0]
			var attack_direction: int = next_move[1]
			
			# Get A* path and initialize unit movement
			enemy.init_moving(grid.get_path_astar(\
					grid.get_tilenode_from_coord_map(enemy.current_tile), \
					grid.get_tilenode_from_coord_map(new_tile)), \
				attack_direction)
			
			await enemy_finished_move
			await get_tree().create_timer(1.5).timeout

# Returns a dictionary containing a set of tiles a given unit can reach
# tile keys link to an int array containing data used to make optimal decisions.
# Called at the start of each enemy's turn.
# PARAM: Active Enemy Unit
# OUTPUT: Dictionary[Tile -> Dictionary[ORIENTATION -> Array]] 
# Array of [# Players Hit, # Players Killed, # Enemies Hit, # Enemies Killed, Damage]
func create_move_dictionary(current_enemy: Unit) -> Dictionary:
	var move_dictionary: Dictionary = {}
	
	# Retrieves the set of all tiles the unit can move to
	var movement_set: Array[Vector2i] = \
		grid.project_movement(current_enemy.range_stat, current_enemy.current_tile, true)
	
	# Cycle through the movement set and assign dictionary values
	for tile in movement_set:
		
		# Retrieve an array of tile positions indicating 
		# where the unit can attack given each of 4 directions
		# Down = 0, Up = 1, Left = 2, Right = 3
		var temp_dictionary: Dictionary = {}
		var attack_set: Array[Array] = current_enemy.get_attack_patterns(true, tile)
		var attack_direction: int = 0
		
		# Create a new sub dictionary per attack set
		for attack_tiles in attack_set:
			
			# Determine the following for each attack set:
			# - # Players Hit
			# - # Players Killed
			# - # Enemies Hit
			# - # Enemies Killed
			# - Total Advantageous Damage
			var data: Array[int] = []
			
			# Retrieve all units in tile list
			var units_hit: Array[Unit] = get_units_in_tile_list(attack_tiles)
			var players_hit: int = 0
			var players_killed: int = 0
			var enemies_hit: int = 0
			var enemies_killed: int = 0
			var total_damage: int = 0
			
			# Get the # of players hit
			for unit in units_hit:
				# Get the potential damage without variance
				var damage: int = calc_damage_for_display(current_enemy, unit)
				
				# Player Case
				if unit.is_player:
					players_hit += 1
					total_damage += damage
					if unit.hp - damage <= 0:
						players_killed += 1
				
				# Enemy Case; SUBTRACT damage dealt since is non-advantageous
				else:
					enemies_hit += 1
					total_damage -= damage
					if unit.hp - damage <= 0:
						enemies_killed += 1
			
			# Construct value for key
			data.push_back(players_hit)
			data.push_back(players_killed)
			data.push_back(enemies_hit)
			data.push_back(enemies_killed)
			data.push_back(total_damage)
			
			# Assign Key to Value
			temp_dictionary[attack_direction] = data
			move_dictionary[tile] = temp_dictionary
			
			# Increment the attack direction counter
			attack_direction += 1
	
	return move_dictionary

# Returns a list containing the following:
# 1) optimal position for the enemy to move to
# 2) optimal direction for the enemy to attack / SET TO -1 to WAIT !!!
func get_best_move(move_dict: Dictionary, enemy: Unit) -> Array:
	
	# Save a reference to the best key/value pair
	var best_move: Array = []
	var best_tile: Vector2i = move_dict.keys()[0]
	var best_direction: int = -1
	var best_utiliy: float = -INF
	
	# Choose the best move using one of the following methods
	match ai_type:
		
		# Uses advantageous damage as the only metric for deciding on a move 
		ai_types.damage_only:
			
			# Evaluate the best possible move
			# Loop through each position, and each attack direction therein
			for tile in move_dict.values():
				for direction in 4:
					
					# Gets the Array[int] of data from the layered Dictionary
					# Array of [# Players Hit, # Players Killed, # Enemies Hit, # Enemies Killed, Damage]
					var data = tile[direction]
					
					# Measures the utility of this decision making algorithm
					var utility: int = data[4]
					
					# Damage utility must be greater than 0
					if utility > best_utiliy and utility > 0:
						best_tile = move_dict.find_key(tile)
						best_utiliy = utility
						best_direction = direction
			
			if best_utiliy <= 0:
				best_direction = -1
				best_tile = find_closest_tile(enemy, move_dict.keys())
		
		# Uses a point based utility metric to decide on a move
		ai_types.point_values:
			
			# Evaluate the best possible move
			# Loop through each position, and each attack direction therein
			for tile in move_dict.values():
				for direction in 4:
					
					# Gets the Array[int] of data from the layered Dictionary
					# Array of [# Players Hit, # Players Killed, # Enemies Hit, # Enemies Killed, Damage]
					var data = tile[direction]
					
					# Measures the utility of this decision making algorithm
					var players_hit: int = data[0]
					var utility: float = (data[0] * util_players_damaged) + \
									   (data[1] * util_players_killed) + \
									   (data[2] * util_enemies_damaged) + \
									   (data[3] * util_enemies_killed) + \
									   (data[4] * util_damage)
					
					# Check for best utiltiy
					if utility > best_utiliy:
						best_tile = move_dict.find_key(tile)
						best_utiliy = utility
						
						# Only set a direction if hitting players with the attack
						if players_hit > 0:
							best_direction = direction
						else:
							best_direction = -1
							best_tile = find_closest_tile(enemy, move_dict.keys())
	
	# Create the Array[TILE, DIRECTION] to return
	best_move.push_back(best_tile)
	best_move.push_back(best_direction)
	
	return best_move

# Finds a tile in the given move set closest to the nearest player unit 
func find_closest_tile(searching_unit: Unit, tiles: Array) -> Vector2i:
	var best_tile: Vector2i = tiles[0]
	
	# Get a reference to the closest player unit
	var closest_unit: Unit = player_units[0]
	var best_distance: float = INF
	for unit in player_units:
		if abs(Vector2(searching_unit.current_tile.x, searching_unit.current_tile.y).distance_squared_to\
		(Vector2(unit.current_tile.x, unit.current_tile.y)))\
		< best_distance:
			
			closest_unit = unit
			best_distance = abs(Vector2(searching_unit.current_tile.x, searching_unit.current_tile.y).distance_squared_to\
							(Vector2(unit.current_tile.x, unit.current_tile.y)))
	
	# Find a tile within the valid move tile array closest to the closest unit
	best_distance = INF
	for tile in tiles:
		if abs(Vector2(tile.x,tile.y).distance_squared_to(closest_unit.current_tile)) < best_distance:
			best_tile = tile
			best_distance = abs(Vector2(tile.x,tile.y).distance_squared_to(closest_unit.current_tile))
	
	return best_tile

# Selects a random move to execute
func get_random_move(move_dict: Dictionary) -> Array:
	var random_move: Array = []
	var random_tile: Vector2i = move_dict.keys()[0]
	var random_direction: int = -1
	
	random_tile = move_dict.keys()[randi_range(0,move_dict.size() - 1)]
	random_direction = randi_range(-1,3)
	
	random_move.push_back(random_tile)
	random_move.push_back(random_direction)
	return random_move

signal enemy_finished_move()
