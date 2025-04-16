extends CanvasLayer

@onready var outcome_label = $WonLostLabel
@onready var damage_label = $DamageLabel
@onready var units_killed_label = $UnitsKilledLabel

const win_message: String = "Enemies: Lost"
const lose_message: String = "Enemies: Won"

func _ready():
	set_results()

func set_results():
	if ResultsTracker.enemies_won:
		outcome_label.text = lose_message
	else:
		outcome_label.text = win_message
	
	damage_label.text = "Total Enemy Damage = " + str(ResultsTracker.total_enemy_damage)
	units_killed_label.text = "Player Units Killed = " + str(ResultsTracker.total_enemy_kills)
