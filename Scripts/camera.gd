extends Camera2D

const camera_range: int = 2
var camera_tile: Vector2i = Vector2i.ZERO

@export var camera_start_tile: Vector2i = Vector2i.ZERO
@onready var grid = $"../IsometricGrid"

func _ready():
	camera_tile = camera_start_tile

func move_camera(tile: Vector2i):
	camera_tile = tile
	position = map_to_loc(tile)

func update_camera(tile: Vector2i):
	if camera_tile.x + camera_range < tile.x:
		var diff: int = abs((camera_tile.x + camera_range) - tile.x)
		camera_tile.x += diff
		position = map_to_loc(camera_tile)
		
	elif camera_tile.x - camera_range > tile.x:
		var diff: int = abs((camera_tile.x - camera_range) - tile.x)
		camera_tile.x -= diff
		position = map_to_loc(camera_tile)
		
	if camera_tile.y + camera_range < tile.y:
		var diff: int = abs((camera_tile.y + camera_range) - tile.y)
		camera_tile.y += diff
		position = map_to_loc(camera_tile)
		
	elif camera_tile.y - camera_range > tile.y:
		var diff: int = abs((camera_tile.y - camera_range) - tile.y)
		camera_tile.y -= diff
		position = map_to_loc(camera_tile)
		

# Shortcut for map -> local conversion
func map_to_loc(tile: Vector2i) -> Vector2:
	return grid.map_to_local(tile)
# Shortcut for local -> map conversion
func loc_to_map(pos: Vector2) -> Vector2i:
	return grid.local_to_map(pos)
