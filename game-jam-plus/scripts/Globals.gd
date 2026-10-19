extends Node

var player_pos: Vector2
var currentDay: int = 0
var player_life: int
var player_maxlife:int 
var dayEnemies = 10
var onlinePlayers: String
var killedEnemies: int = 0
var diaDoisEvento: bool = false
signal update_dialogue(new_dialogue)

func _ready() -> void:
	if currentDay == 0:
		dayEnemies = 1
		onlinePlayers = "5000"
	elif currentDay == 1:
		var dialogue: DialogueResource = load("res://dialogues/day2.dialogue")
		update_dialogue.emit.call_deferred(dialogue)
		dayEnemies = 1
		onlinePlayers = "4300"
	elif(currentDay == 2):
		get_tree().quit()
		
		
	
		
	
		
	

func _physics_process(delta: float) -> void:
	print(currentDay)
	if currentDay == 0:
		dayEnemies = 1
		onlinePlayers = "5000"
	elif currentDay == 1:
		dayEnemies = 1
		onlinePlayers = "4300"
