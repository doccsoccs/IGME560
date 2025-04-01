extends Sprite2D
class_name PlayerUnit

# PLAYER Z-INDECES
# Level 0 = 2, Level 1 = 5, Level 2 = 8

#region UNIT STATISTICS
var speed: int = 4
#endregion

@export var attack_paths: Array[String]

#region STATE MACHINES
enum game_state{
	waiting,
	hovering,
	selected,
	moving,
	select_action,
	expended
}

enum anim_state{
	idle,
	idle_fb,
	walk,
	walk_fb
}
#endregion

var prev_tile: Vector2i
var current_tile: Vector2i

#region MOVEMENT
const move_speed: float = 55
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

@onready var anim_player = $AnimationPlayer
@onready var select_key = $SelectKeyIndicator
@onready var move_ghost = $MovementGhost
@onready var action_buttons = $ActionButtons
@onready var manager = $".."

## SFX
@onready var select_sfx = $SelectSFX

func _ready():
	update_animations(initial_anim)
	current_game_state = initial_game_state
	await get_tree().create_timer(0.1).timeout
	current_tile = loc_to_map(global_position)
	prev_tile = current_tile

func _process(delta):
	# Moves the unit if movement has been initialized
	# only move if the size of the path given is positive and non-zero
	if move_path.size() > 1:
		# Move unit towards the next tile in the path
		direction = (Vector2)(map_to_loc(move_path[1]) - map_to_loc(move_path[0])).normalized()
		velocity = direction * move_speed * delta
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
			set_game_state(game_state.select_action)

# Initializes the unit to be used during a round of play
func init_for_new_round():
	current_game_state = game_state.waiting
	modulate = Color.WHITE

# Inform manager to change control mode to ATTACKING
# Project an attack
func attack():
	manager.grid.current_ctrl_mode = manager.grid.control_mode.attacking
	manager.grid.project_attack(get_attack_pattern(attack_paths[0]))

# Ends the unit's "turn"
func end_turn():
	manager.grid.handle_end_turn()
	current_game_state = game_state.expended
	modulate = Color.DARK_GRAY

# Moves the unit immediately to a particular tile
func move_to(target: Vector2i):
	position = map_to_loc(target)

# Moves a ghost of a player character unit
# Typically along with the cursor
func ghost_move_tile(new_tile: Vector2i):
	move_ghost.position = map_to_loc(new_tile)

# Returns an array of tile positions representing an attack pattern 
# facing down and centered at (0,0) 
func get_attack_pattern(path: String) -> Array[Vector2i]:
	var file = FileAccess.open(path, FileAccess.READ)
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
	
	return attack_tiles

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
func init_moving(path: Array[Vector2i]):
	# Moving 1 or more squares
	if path.size() > 1:
		current_game_state = game_state.moving
		move_path = path
		set_move_animation(move_path[1])
	# CASE: Moving 0 squares
	else: 
		await get_tree().create_timer(0.1).timeout
		set_game_state(game_state.select_action)

# Initializes post-movement action selection for player
func init_action_selection():
	action_buttons.init_action_buttons()
	manager.grid.set_control_mode(manager.grid.control_mode.selecting_action)

# Ends any state based functionality relavent to game_state enum
func cancel():
	select_key.visible = false
	move_ghost.visible = false

# Changes animations based on unit movement
func set_move_animation(target_pos: Vector2i):
	var dir: Vector2 = (map_to_loc(target_pos) - position).normalized()
	if dir.x < 0 and dir.y < 0: # LEFT
		update_animations(anim_state.walk_fb)
		flip_h = false
	if dir.x < 0 and dir.y > 0: # DOWN
		update_animations(anim_state.walk)
		flip_h = false
	if dir.x > 0 and dir.y > 0: # RIGHT
		update_animations(anim_state.walk)
		flip_h = true
	if dir.x > 0 and dir.y < 0:
		update_animations(anim_state.walk_fb)
		flip_h = true

# Shortcut for map -> local conversion
func map_to_loc(tile: Vector2i) -> Vector2:
	return manager.grid.map_to_local(tile)
# Shortcut for local -> map conversion
func loc_to_map(pos: Vector2) -> Vector2i:
	return manager.grid.local_to_map(pos)
