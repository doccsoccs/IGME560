extends Node2D

func display_crit(time: float = 1.5):
	visible = true
	await get_tree().create_timer(time).timeout
	visible = false
