extends Node
class_name TileNode

@onready var tilemap = $".."

# Contains references to adjacent tiles
# references are NULL if adjacent tiles do not exist
var tile_left: TileNode
var tile_right: TileNode
var tile_up: TileNode
var tile_down: TileNode

# Coordinate map data
var index: int
var tile_pos: Vector2i

func init_tile(coordinate_index: int, tile_position: Vector2i):
	index = coordinate_index
	tile_pos = tile_position
	
	# LEFT NODE
	if tilemap.coordinate_map.has(Vector2i(tile_pos.x - 1, tile_pos.y)):
		tile_left = tilemap.coord_map_nodes[tilemap.coordinate_map.find(Vector2i(tile_pos.x - 1, tile_pos.y))]
	# RIGHT NODE
	if tilemap.coordinate_map.has(Vector2i(tile_pos.x + 1, tile_pos.y)):
		tile_right = tilemap.coord_map_nodes[tilemap.coordinate_map.find(Vector2i(tile_pos.x + 1, tile_pos.y))]
	# UP NODE
	if tilemap.coordinate_map.has(Vector2i(tile_pos.x, tile_pos.y - 1)):
		tile_up = tilemap.coord_map_nodes[tilemap.coordinate_map.find(Vector2i(tile_pos.x, tile_pos.y - 1))]
	# DOWN NODE
	if tilemap.coordinate_map.has(Vector2i(tile_pos.x, tile_pos.y + 1)):
		tile_down = tilemap.coord_map_nodes[tilemap.coordinate_map.find(Vector2i(tile_pos.x, tile_pos.y + 1))]
