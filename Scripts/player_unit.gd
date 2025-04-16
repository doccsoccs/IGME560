extends Sprite2D
class_name Unit

# PLAYER Z-INDECES
# Level 0 = 2, Level 1 = 5, Level 2 = 8

@export_category("UNIT")
@export var is_player: bool = true
var enemy_attack_dir: int = -1

#region UNIT STATISTICS
@export_category("STATS")
@export var max_hp: int = 20
var hp: int 
@export var range_stat: int = 4
@export var attack: int = 50
@export var defense: int = 50
@export var skill: int = 50
@export var type: typing

@export_category("ATTACK")
@export var attack_path: String
@export var attack_base_power: int
@export var attack_type: typing

@export_category("MAP POSITION")
@export var start_tile: Vector2i
@export var start_facing: facing_state

@export_category("MODULATE")
@export var end_turn_color: Color = Color.GRAY
#endregion

#region STATE MACHINES
enum game_state{
	waiting,
	hovering,
	selected,
	moving,
	select_action,
	expended,
	dead
}

enum anim_state{
	idle,
	idle_fb,
	walk,
	walk_fb
}

enum facing_state{
	down = 0,
	up = 1,
	left = 2,
	right = 3
}
var current_facing_state: facing_state

enum typing{
	water = 0,
	earth = 1,
	fire = 2,
	air = 3,
	shadow = 4,
	light = 5
}
#endregion

var prev_tile: Vector2i
var current_tile: Vector2i

#region MOVEMENT
const move_range: float = 55
var direction: Vector2
var velocity: Vector2
const min_dist_detection: float = 2

var moving: bool = false
var move_target: Vector2i
var move_path: Array[Vector2i]
#endregion

var current_game_state: game_state
const initial_game_state: game_state = game_state.waiting
const initial_anim: anim_state = anim_state.idle

var results_scene = preload("res://Scenes/results.tscn")

@onready var anim_player = $AnimationPlayer
@onready var select_key = $SelectKeyIndicator
@onready var move_ghost = $MovementGhost
@onready var action_buttons = $ActionButtons
@onready var damage_overhead = $DamageOverhead
@onready var damage_label = $DamageOverhead/DamageLabel
@onready var percent_to_hit_label = $DamageOverhead/PercentToHitLabel
@onready var health_label = $HealthBar/HealthLabel
@onready var type_indicator = $HealthBar/TypeIndicator
@onready var manager = $".."
@onready var particle_manager = $ParticleManager
@onready var crit_indicator = $CritIndicator

## SFX
@onready var select_sfx = $SelectSFX

func _ready():
	update_animations(initial_anim)
	current_facing_state = facing_state.down
	current_game_state = initial_game_state
	await get_tree().create_timer(0.1).timeout
	
	# Init stats
	hp = max_hp
	health_label.text = str(hp)
	type_indicator.frame = type
	
	# Set initial position
	position = map_to_loc(start_tile)
	current_tile = loc_to_map(global_position)
	prev_tile = current_tile
	
	# Set initial orientation
	set_facing(start_facing)

func _process(delta):
	# Moves the unit if movement has been initialized
	# only move if the size of the path given is positive and non-zero
	if move_path.size() > 1:
		# Move unit towards the next tile in the path
		direction = (Vector2)(map_to_loc(move_path[1]) - map_to_loc(move_path[0])).normalized()
		velocity = direction * move_range * delta
		position += velocity
		
		# Make sure unit locks onto each tile in path
		if position.distance_to(map_to_loc(move_path[1])) < min_dist_detection:
			position = map_to_loc(move_path[1])
			move_path.pop_front()
			if move_path.size() > 1:
				set_move_animation(move_path[1])
			else:
				if direction.y > 0:
					update_animations(anim_state.idle)
				else:
					update_animations(anim_state.idle_fb)
				if direction.x > 0:
					flip_h = true
				else:
					flip_h = false
		
		# Prepare to select an action after completing movement
		if move_path.size() == 1:
			prev_tile = current_tile
			current_tile = move_path[0]
			
			# Only transition to action select state if is a player
			if is_player:
				set_game_state(game_state.select_action)
			else:
				show_attack()

# Initializes the unit to be used during a round of play
func init_for_new_round():
	current_game_state = game_state.waiting
	self_modulate = Color.WHITE

# Called when this unit takes damage from an attack
func take_damage(damage: int, damage_type: typing, enemy_is_attacker: bool = false):
	particle_manager.emit_particles(damage_type)
	hp -= damage
	
	# Update result tracker accordingly
	if enemy_is_attacker:
		ResultsTracker.total_enemy_damage += damage
	
	if hp <= 0:
		hp = 0
		die()
	health_label.text = str(hp)

# Inform manager to change control mode to ATTACKING
# Project an attack
func show_attack():
	manager.grid.attack_patterns = get_attack_patterns()
	manager.grid.camera_component.move_camera(current_tile)
	
	if is_player: # Player Case
		manager.grid.current_ctrl_mode = manager.grid.control_mode.attacking
		manager.grid.project_attack(current_facing_state)
	else: # Enemy Case
		set_facing(enemy_attack_dir)
		if enemy_attack_dir > -1:
			manager.grid.project_attack(current_facing_state, self)
		else:
			end_turn()

# Ends the unit's "turn"
func end_turn():
	manager.grid.handle_end_turn()
	current_game_state = game_state.expended
	
	# ONLY MODULATE PLAYERS
	if is_player:
		self_modulate = end_turn_color
	
	manager.handle_end_turn(is_player)

# Moves the unit immediately to a particular tile
func move_to(target: Vector2i):
	position = map_to_loc(target)

# Moves a ghost of a player character unit
# Typically along with the cursor
func ghost_move_tile(new_tile: Vector2i):
	move_ghost.global_position = map_to_loc(new_tile)

# Show the damage indicator for some attack
func show_damage_indicator(attacking_unit: Unit):
	damage_label.text = str(manager.calc_damage_for_display(attacking_unit, self))
	damage_overhead.visible = true
	
	# Change label frame depending on type matchup
	match manager.type_matchup(attacking_unit, self):
		1.0:
			damage_overhead.frame = 0
			return
		2.0:
			damage_overhead.frame = 1
			return
		0.5:
			damage_overhead.frame = 2
			return
		_:
			damage_overhead.frame = 0

# Hide the damage indicator after an attack is declared 
# or when the projected attack stops hovering on unit
func hide_damage_indicator():
	damage_overhead.visible = false

# Returns an array of tile positions representing an attack pattern 
# facing down and centered at (0,0) 
func get_attack_patterns(use_override: bool = false, override_tile: Vector2i = Vector2.ZERO) -> Array[Array]:
	var file = FileAccess.open(attack_path, FileAccess.READ)
	var text = file.get_as_text()
	var s: Array[String] = []
	s.assign(text.split("|"))
	var rows: Array[String] = s
	var pattern_chars: Array[Array] = []
	var attack_tiles: Array[Vector2i] = []
	
	# Get 2D array of TXT file characters
	for i in rows.size():
		if rows.size() > 0:
			s = []
			s.assign(rows[i].split())
			pattern_chars.append(s)
		else:
			pattern_chars.append([rows[i]])
	
	# Find the origin
	var origin: Vector2i = Vector2i.ZERO
	for r in pattern_chars.size():
		if pattern_chars[r].has("c"):
			origin = Vector2i(pattern_chars[r].find("c"), r)
	
	# Generate attack pattern map
	for r in pattern_chars.size():
		for c in pattern_chars[r].size():
			if pattern_chars[r][c] == "x":
				attack_tiles.push_back(Vector2i(c,r) - origin)
	
	# Save the pattern angled in each of 4 directions
	var omni_dir_patterns: Array[Array] = []
	var adjustment_vector: Vector2i = current_tile
	if use_override:
		adjustment_vector = override_tile
	var temp: Array[Vector2i] = []
	for tile in attack_tiles:
		temp.push_back(tile + adjustment_vector)
	omni_dir_patterns.push_back(temp)
	temp = []
	
	# UP Direction (1)
	for tile in attack_tiles:
		var diff = (origin.y - tile.y) * 2
		temp.push_back(Vector2i(tile.x, tile.y + diff) + adjustment_vector)
	omni_dir_patterns.push_back(temp)
	temp = []
	
	# LEFT Direction (2)
	for tile in attack_tiles:
		var x_diff = origin.x - tile.x
		var y_diff = origin.y - tile.y
		temp.push_back(Vector2i(-origin.y + y_diff, -origin.x + x_diff) + adjustment_vector)
	omni_dir_patterns.push_back(temp)
	temp = []
	
	# RIGHT Direction (3)
	for tile in attack_tiles:
		var x_diff = origin.x - tile.x
		var y_diff = origin.y - tile.y
		temp.push_back(Vector2i(origin.y - y_diff, origin.x - x_diff) + adjustment_vector)
	omni_dir_patterns.push_back(temp)
	temp = []
	
	# Down = 0
	# Up = 1
	# Left = 2
	# Right = 3
	
	return omni_dir_patterns

# Sets the unit's game state
func set_game_state(new_state: game_state):
	current_game_state = new_state
	match current_game_state:
		# Default State, has not taken a turn
		game_state.waiting:
			cancel()
			return
		# Selector is hovering over unit
		game_state.hovering:
			init_hovering()
			return
		# Select input was made while the selector was hovering
		# Allows for game actions to be taken with the unit
		game_state.selected:
			init_selected()
			return
		# Select input was made after selecting the unit
		game_state.moving:
			return
		# Movement has completed and the unit is awaiting either an input decision or for AI
		# to determine what action to take
		game_state.select_action:
			init_action_selection()
			return
		# Default case
		_:
			return

# Changes the animation being played based on the current state of the unit
func update_animations(anim: anim_state):
	match anim:
		anim_state.idle:
			anim_player.play("idle")
			return
		anim_state.idle_fb:
			anim_player.play("idle_fb")
			return
		anim_state.walk:
			anim_player.play("walk")
			return
		anim_state.walk_fb:
			anim_player.play("walk_faceback")
			return
		_:
			anim_player.play("idle")
			return

# Initializes logic for the hovering game state
func init_hovering():
	select_key.visible = true

# Initializes logic for the selected game state
func init_selected():
	select_sfx.play()
	select_key.set_invisible_after_time()

# Z/ENTER was pressed while the unit was selected
func init_moving(path: Array[Vector2i], attack_direction: int = -1):
	# Update enemy variables
	enemy_attack_dir = attack_direction
	
	# Moving 1 or more squares
	if path.size() > 1:
		current_game_state = game_state.moving
		move_path = path
		set_move_animation(move_path[1])
	# CASE: Moving 0 squares
	else: 
		await get_tree().create_timer(0.1).timeout
		if is_player:
			set_game_state(game_state.select_action)
		else:
			show_attack()

# Initializes post-movement action selection for player
func init_action_selection():
	action_buttons.init_action_buttons()
	manager.grid.set_control_mode(manager.grid.control_mode.selecting_action)

# Ends any state based functionality relavent to game_state enum
func cancel():
	select_key.visible = false
	move_ghost.visible = false

# Sets the unit's animation state and flipped property (IDLE ONLY)
func set_facing(facing: facing_state):
	if facing == facing_state.left: # LEFT
		current_facing_state = facing_state.left
		update_animations(anim_state.idle_fb)
		flip_h = false
	if facing == facing_state.down: # DOWN
		current_facing_state = facing_state.down
		update_animations(anim_state.idle)
		flip_h = false
	if facing == facing_state.right: # RIGHT
		current_facing_state = facing_state.right
		update_animations(anim_state.idle)
		flip_h = true
	if facing == facing_state.up: # UP
		current_facing_state = facing_state.up
		update_animations(anim_state.idle_fb)
		flip_h = true

# Changes animations based on unit movement
func set_move_animation(target_pos: Vector2i):
	var dir: Vector2 = (map_to_loc(target_pos) - position).normalized()
	if dir.x < 0 and dir.y < 0: # LEFT
		update_animations(anim_state.walk_fb)
		current_facing_state = facing_state.left
		flip_h = false
	if dir.x < 0 and dir.y > 0: # DOWN
		update_animations(anim_state.walk)
		current_facing_state = facing_state.down
		flip_h = false
	if dir.x > 0 and dir.y > 0: # RIGHT
		update_animations(anim_state.walk)
		current_facing_state = facing_state.right
		flip_h = true
	if dir.x > 0 and dir.y < 0: # UP
		update_animations(anim_state.walk_fb)
		current_facing_state = facing_state.up
		flip_h = true

# Handle the death of a given unit
func die():
	# Update result tracker accordingly
	if is_player:
		ResultsTracker.total_enemy_kills += 1
	
	await get_tree().create_timer(1.75).timeout
	current_game_state = game_state.dead
	if is_player:
		manager.player_units.erase(self)
		if manager.player_units.size() == 0:
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_packed(results_scene)
	else:
		manager.enemy_units.erase(self)
		if manager.enemy_units.size() == 0:
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_packed(results_scene)
	visible = false
	manager.units.erase(self)

# Shortcut for map -> local conversion
func map_to_loc(tile: Vector2i) -> Vector2:
	return manager.grid.map_to_local(tile)
# Shortcut for local -> map conversion
func loc_to_map(pos: Vector2) -> Vector2i:
	return manager.grid.local_to_map(pos)
