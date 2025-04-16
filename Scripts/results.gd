extends CanvasLayer

@onready var outcome_label = $WonLostLabel
@onready var damage_label = $DamageLabel
@onready var units_killed_label = $UnitsKilledLabel

var ai_type_used: String = ""

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
	
	match ResultsTracker.ai_type_used:
		0:
			ai_type_used = "Hits/Kills Utility (GOB)"
		1:
			ai_type_used = "Damage Only (GOB)"
		2:
			ai_type_used = "Random"
	
	save_to_file("Damage = " + str(ResultsTracker.total_enemy_damage) + " | " \
	 + "Kills = " + str(ResultsTracker.total_enemy_kills) + " | " \
	 + outcome_label.text + " | " + ai_type_used)

func save_to_file(content):
	var file = FileAccess.open("res://Game Records/records.txt", FileAccess.READ)
	var readline = file.get_as_text()
	file.close()
	
	file = FileAccess.open("res://Game Records/records.txt", FileAccess.WRITE)
	file.store_string(readline + "\n" + content)
	file.close()
