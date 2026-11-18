extends Node

var player_pos: Vector2
var currentDay: int = 0
var player_life: int
var player_maxlife:int 
var dayEnemies : int
var onlinePlayers: String
var killedEnemies: int = 0
var diaDoisEvento: bool = false
var actualDialogue : DialogueResource = load("res://dialogues/day1.dialogue")



func _ready() -> void:
	if (currentDay == 0):
		EventManager._startDay()
		dayEnemies = 3
		onlinePlayers = "5000"
	
		
		
	
func _physics_process(delta: float) -> void:
	pass
		
	
func on_set_day():
	EventManager._startDay()
	if currentDay == 1:
		print("aaaaa")
		actualDialogue = load("res://dialogues/day2.dialogue")
		dayEnemies = 8
		onlinePlayers = "4300"
	elif(currentDay == 2):
		get_tree().quit()
		
