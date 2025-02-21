extends Node2D

var player_units: Array[Sprite2D]
var enemy_units: Array[Sprite2D]

func _ready():
	# Get an array containing all player units
	for unit in get_children():
		if unit is PlayerUnit:
			player_units.push_back(unit)
