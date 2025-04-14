extends CanvasLayer

@onready var turn_display = $TurnDisplay

func update_turn_indicator(is_player_turn: bool):
	if is_player_turn:
		turn_display.frame = 0
	else:
		turn_display.frame = 1
