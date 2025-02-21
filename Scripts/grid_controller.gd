extends TileMap

const selector_atlus_pos: Vector2i = Vector2i(0,0)
const selector_source: int = 3
const init_selector_pos: Vector2i = Vector2i.ZERO
var current_selector_pos: Vector2i

enum layers{
	level0 = 0,
	h_level0 = 1,
	level1 = 2,
	h_level1 = 3,
	level2 = 4,
	h_level2 = 5,
	selector = 6
}

# Sound Effects
@onready var move_selector_sfx = $MoveSelectorSFX

# References
var unit_manager

func _ready():
	set_cell(layers.selector, init_selector_pos, selector_source, selector_atlus_pos)
	current_selector_pos = init_selector_pos
	
	# Get the manager if it exists, else quit and throw error
	if get_tree().get_first_node_in_group("UnitManager"):
		unit_manager = get_tree().get_first_node_in_group("UnitManager")
	else:
		print("Error: Could not retrieve Unit Manager")
		get_tree().quit()

func _input(event):
	# SELECTOR MOVEMENT INPUTS
	if event.is_action_pressed("Up"):
		move_selector(Vector2i(current_selector_pos.x, current_selector_pos.y - 1))
	elif event.is_action_pressed("Down"):
		move_selector(Vector2i(current_selector_pos.x, current_selector_pos.y + 1))
	elif event.is_action_pressed("Left"):
		move_selector(Vector2i(current_selector_pos.x - 1, current_selector_pos.y))
	elif event.is_action_pressed("Right"):
		move_selector(Vector2i(current_selector_pos.x + 1, current_selector_pos.y))

# Moves the selector to a new position and deletes the old tile
func move_selector(new_pos: Vector2i):
	move_selector_sfx.play()
	erase_cell(layers.selector, current_selector_pos)
	set_cell(layers.selector, new_pos, selector_source, selector_atlus_pos)
	current_selector_pos = new_pos
	check_for_selections()

# Check to see if any player units are being selected
func check_for_selections():
	for unit in unit_manager.player_units:
		if unit.grid_pos == current_selector_pos:
			unit.set_game_state(unit.game_state.hovering)
