extends Sprite2D
class_name PlayerUnit

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

var grid_pos: Vector2i
const init_grid_pos: Vector2i = Vector2i(0,0)

var current_game_state: game_state
const initial_game_state: game_state = game_state.waiting
const initial_anim: anim_state = anim_state.idle

@onready var anim_player = $AnimationPlayer
@onready var enter_symbol = $EnterSymbol

func _ready():
	update_animations(initial_anim)
	current_game_state = initial_game_state
	grid_pos = init_grid_pos
	position = grid_pos

func update_position(new_pos: Vector2i):
	pass

# Sets the unit's game state
func set_game_state(new_state: game_state):
	current_game_state = new_state
	match current_game_state:
		game_state.hovering:
			init_hovering()
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
