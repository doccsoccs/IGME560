extends Sprite2D
class_name PlayerUnit

# PLAYER Z-INDECES
# Level 0 = 2, Level 1 = 5, Level 2 = 8

#region UNIT STATISTICS
var speed: int = 4
#endregion

#region STATE MACHINES
enum game_state{
	waiting,
	hovering,
	selected,
	expended
}

enum anim_state{
	idle,
	walk,
	walk_fb
}
#endregion

var current_tile: Vector2i

var current_game_state: game_state
const initial_game_state: game_state = game_state.waiting
const initial_anim: anim_state = anim_state.idle

@onready var anim_player = $AnimationPlayer
@onready var enter_symbol = $EnterSymbol
@onready var move_ghost = $MovementGhost
@onready var manager = $".."

func _ready():
	update_animations(initial_anim)
	current_game_state = initial_game_state
	await get_tree().create_timer(0.1).timeout
	current_tile = manager.grid.local_to_map(global_position)

func ghost_move_tile(new_tile: Vector2i):
	position = manager.grid.map_to_local(manager.grid.new_tile)
	current_tile = new_tile

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
		# ENTER was pressed while the selector was hovering
		# Allows for game actions to be taken with the unit
		game_state.selected:
			init_selected()
			return

# Changes the animation being played based on the current state of the unit
func update_animations(anim: anim_state):
	match anim:
		anim_state.idle:
			anim_player.play("idle")
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
	enter_symbol.visible = true

# Initializes logic for the selected game state
func init_selected():
	enter_symbol.visible = false

# Ends any state based functionality relavent to game_state enum
func cancel():
	enter_symbol.visible = false
