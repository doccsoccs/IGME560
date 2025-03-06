extends Node
class_name Heuristic

static func manhattan(node: TileNode, goal: TileNode) -> float:
	var dx: float = abs(node.tile_pos.x - goal.tile_pos.x)
	var dy: float = abs(node.tile_pos.y - goal.tile_pos.y)
	return dx + dy

static func cross_product(start: TileNode, node: TileNode, goal: TileNode) -> float:
	var dx1: float = node.tile_pos.x - goal.tile_pos.x
	var dy1: float = node.tile_pos.y - goal.tile_pos.y
	var dx2: float = start.tile_pos.x - goal.tile_pos.x
	var dy2: float = start.tile_pos.x - goal.tile_pos.x
	var cross: float = abs((dx1 * dy2) - (dx2 * dy1))
	return manhattan(node, goal) + cross * 0.001
