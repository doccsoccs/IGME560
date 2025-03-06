extends Node
class_name NodeRecord

var node: TileNode
var connection: NodeRecord
var cost_so_far: float
var estimated_total_cost: float

static func contains_node(tile: TileNode, nodes: Array[NodeRecord]) -> bool:
	for n in nodes:
		if n.node == tile:
			return true
	return false

static func get_record_from_list(tile: TileNode, nodes: Array[NodeRecord]) -> NodeRecord:
	for n in nodes:
		if n.node == tile:
			return n
	return null

static func get_smallest(nodes: Array[NodeRecord]) -> NodeRecord:
	var smallest: NodeRecord = NodeRecord.new()
	smallest.estimated_total_cost = INF
	for record in nodes:
		if record.estimated_total_cost < smallest.estimated_total_cost:
			smallest = record
	return smallest
