extends TileMap

#region SELECTOR VARIABLES
const selector_atlus_pos: Vector2i = Vector2i(0,0)
const selector_source: int = 3
const init_selector_pos: Vector2i = Vector2i(0,0)
var current_selector_pos: Vector2i
#endregion

#region HIGHLIGHT TILE VARIABLES
const movement_atlus_pos: Vector2i = Vector2i(0,0)
const movement_source: int = 1
#endregionT

# Map Data
var coordinate_map: Array[Vector2i]
var coord_map_nodes: Array[TileNode]
@export var TILE_NODE: PackedScene

# Temp Data
var hovered_unit: PlayerUnit = null
var selected_unit: PlayerUnit = null
var highlighted_tiles: Array[Vector2i]

enum layers{
	level0 = 0,
	h_level0 = 1,
	level1 = 2,
	h_level1 = 3,
	level2 = 4,
	h_level2 = 5,
	selector = 6
}

enum control_mode{
	free,
	moving_unit
}
var current_ctrl_mode: control_mode

# Sound Effects
@onready var move_selector_sfx = $MoveSelectorSFX

# References
var unit_manager

# Onload
func _ready():
	# Initializes Selector
	set_cell(layers.selector, init_selector_pos, selector_source, selector_atlus_pos)
	current_selector_pos = init_selector_pos
	
	# Get the manager if it exists, else quit and throw error
	if get_tree().get_first_node_in_group("UnitManager"):
		unit_manager = get_tree().get_first_node_in_group("UnitManager")
	else:
		print("Error: Could not retrieve Unit Manager")
		get_tree().quit()
	
	# Retrieves an array containing all map cells one the ground layer
	coordinate_map = get_used_cells(layers.level0)
	# Initialize tilemap nodes for pathfinding
	init_coord_map()
	
	# Initialize Input Mode
	current_ctrl_mode = control_mode.free

# Input Events
func _input(event):
	# SELECT UNIT
	if event.is_action_pressed("Select") and hovered_unit != null and selected_unit == null:
		select_unit(hovered_unit)
	# MOVE SELECTED UNIT
	elif event.is_action_pressed("Select") and selected_unit != null:
		move_unit()
		hide_highlighted_tiles()
	
	# SELECTOR MOVEMENT INPUTS
	if event.is_action_pressed("Up"):
		move_selector(Vector2i(current_selector_pos.x, current_selector_pos.y - 1))
		if selected_unit != null:
			selected_unit.move_ghost.up()
	elif event.is_action_pressed("Down"):
		move_selector(Vector2i(current_selector_pos.x, current_selector_pos.y + 1))
		if selected_unit != null:
			selected_unit.move_ghost.down()
	elif event.is_action_pressed("Left"):
		move_selector(Vector2i(current_selector_pos.x - 1, current_selector_pos.y))
		if selected_unit != null:
			selected_unit.move_ghost.left()
	elif event.is_action_pressed("Right"):
		move_selector(Vector2i(current_selector_pos.x + 1, current_selector_pos.y))
		if selected_unit != null:
			selected_unit.move_ghost.right()

# Moves the selector to a new position and deletes the old tile
func move_selector(new_pos: Vector2i):
	# IF NEW POS IS ON MAP --> MOVE
	# When a unit is selected, move selector only if new pos is on a highlighted tile
	if coordinate_map.has(new_pos) and (selected_unit == null or highlighted_tiles.has(new_pos)):
		move_selector_sfx.play()
		erase_cell(layers.selector, current_selector_pos)
		set_cell(layers.selector, new_pos, selector_source, selector_atlus_pos)
		current_selector_pos = new_pos
		check_for_selections()
		
		# Display a ghost unit if moving the selector while a unit is selected
		if selected_unit != null:
			selected_unit.move_ghost.visible = true
			selected_unit.move_ghost.position = map_to_local(new_pos)

# Check to see if any player units are being selected
func check_for_selections():
	for unit in unit_manager.player_units:
		# Unit must be waiting in order to hover
		if unit.current_tile == current_selector_pos and unit.current_game_state == unit.game_state.waiting:
			unit.set_game_state(unit.game_state.hovering)
			hovered_unit = unit
		# Ends hover if was previously hovering
		elif unit.current_game_state == unit.game_state.hovering:
			unit.set_game_state(unit.game_state.waiting)
			hovered_unit = null

# Selects the hovered unit
func select_unit(unit: PlayerUnit):
	unit.set_game_state(unit.game_state.selected)
	hovered_unit = null
	selected_unit = unit
	project_movement(unit.speed, unit.current_tile)

# Displays movement tile highlights where the selected unit can move
func project_movement(speed: int, origin: Vector2i):
	draw_move_highlight(origin)
	var width: int = speed
	var height: int = 0
	for n in speed+1:
		for i in range(0, width+1):
			draw_move_highlight(origin + Vector2i(i, height))
			draw_move_highlight(origin + Vector2i(-i, height))
			if height != 0:
				draw_move_highlight(origin + Vector2i(i, -height))
				draw_move_highlight(origin + Vector2i(-i, -height))
		height += 1
		width -= 1

# Erases all highlighted movement cells
# but does NOT clear the highlighted tiles array
func hide_highlighted_tiles():
	for tile in highlighted_tiles:
		erase_cell(layers.h_level0, Vector2i(tile.x, tile.y))

# Calls unit telling it to begin moving using A* algorithm
# Sets selected unit to null
func move_unit():
	selected_unit.init_moving( \
		get_path_astar( \
				get_tilenode_from_coord_map(selected_unit.current_tile), \
				get_tilenode_from_coord_map(current_selector_pos) \
			) \
		)
	selected_unit.move_ghost.visible = false
	selected_unit = null

# Draws a highlighted movement tile at a given tile
func draw_move_highlight(tile: Vector2i):
	if coordinate_map.has(tile):
		set_cell(layers.h_level0, tile, movement_source, movement_atlus_pos)
		highlighted_tiles.push_back(tile)

# Creates a series of nodes that help perform pathfinding algorithms
func init_coord_map():
	for n in coordinate_map.size():
		var node = TILE_NODE.instantiate()
		add_child(node)
		coord_map_nodes.push_back(node)
	for n in coord_map_nodes.size():
		coord_map_nodes[n].init_tile(n, coordinate_map[n])

# Removes null elements from array
func clean_array(dirty_array: Array[TileNode]) -> Array[TileNode]:
	var cleaned_array: Array[TileNode] = []
	for item in dirty_array:
		if item != null:
			cleaned_array.push_back(item)
	return cleaned_array

# Returns a path a unit can follow to move from one location to another
# PARAMS: Goal/target tile & current unit's tile
func get_path_astar(start: TileNode, goal: TileNode) -> Array[Vector2i]:
	# CASE: Move target is the same as current position
	if start == goal:
		var empty: Array[Vector2i] = []
		return empty
	
	# Initialize the record for the start node
	var start_record: NodeRecord = NodeRecord.new()
	start_record.node = start
	start_record.connection = null
	start_record.cost_so_far = 0.0
	start_record.estimated_total_cost = Heuristic.cross_product(start, start, goal)
	
	# Initialize the open / closed lists
	var open: Array[NodeRecord] = []
	open.push_back(start_record)
	var closed: Array[NodeRecord] = []
	
	# Variables
	var current: NodeRecord = NodeRecord.new()
	var end_node_record: NodeRecord = NodeRecord.new()
	var end_node_heuristic: float
	
	# Iterate through processing each node
	while open.size() > 0:
		# Find the smallest element in the open list.
		# Use estimated total cost
		current = NodeRecord.get_smallest(open)
		
		# If the goal is found, then terminate
		if current.node == goal:
			break
		
		# Otherwise get outgoing connections
		var connections: Array[TileNode] = \
			[current.node.tile_left, current.node.tile_right, \
			current.node.tile_up, current.node.tile_down]
		# Remove null elements
		connections = clean_array(connections)
		
		# Loop through each connection
		for connection in connections:
			var end_node: TileNode = connection
			var end_node_cost: float = current.cost_so_far + 1
			
			if NodeRecord.contains_node(end_node, closed):
				end_node_record = NodeRecord.get_record_from_list(end_node, closed)
				if end_node_record.cost_so_far <= end_node_cost:
					continue
				closed.erase(end_node_record)
				end_node_heuristic = \
					end_node_record.estimated_total_cost - end_node_record.cost_so_far
			
			elif NodeRecord.contains_node(end_node, open):
				end_node_record = NodeRecord.get_record_from_list(end_node, open)
				if end_node_record.cost_so_far <= end_node_cost:
					continue
				end_node_heuristic = \
					end_node_record.estimated_total_cost - end_node_record.cost_so_far
			
			else:
				end_node_record = NodeRecord.new()
				end_node_record.node = end_node
				end_node_heuristic = Heuristic.cross_product(start, end_node, goal)
			
			end_node_record.cost_so_far = end_node_cost
			end_node_record.connection = current
			end_node_heuristic = end_node_cost + end_node_heuristic
			
			if !NodeRecord.contains_node(end_node, open):
				open.push_back(end_node_record)
			
		open.erase(current)
		closed.push_back(current)
	# ----------------------------------------------------------------------------------------
	
	var path: Array[Vector2i] = []
	# Construct path for return
	if current.node != goal:
		print("Search Failed")
	
	else:
		while current.node != start:
			path.push_back(current.node.tile_pos)
			current = current.connection
	
	path.reverse()
	path.push_front(start.tile_pos)
	return path

# Attempts to return a TileNode based on tile position information
func get_tilenode_from_coord_map(tile: Vector2i) -> TileNode:
	if coordinate_map.has(tile):
		return coord_map_nodes[coordinate_map.find(tile)]
	else:
		return null
