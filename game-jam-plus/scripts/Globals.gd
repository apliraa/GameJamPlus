extends Node

var player_pos: Vector2
var currentDay: int = 1
var player_life: int
var player_maxlife:int 
var dayEnemies = 10
var onlinePlayers: String
var killedEnemies: int = 0
var diaDoisEvento: bool = false

func _ready() -> void:
	if currentDay == 0:
		dayEnemies = 1
		onlinePlayers = "5000"
	elif currentDay == 1:
		dayEnemies = 1
		onlinePlayers = "4300"
		var dialogue: DialogueResource = load("res://dialogues/day2.dialogue")
		$Friend/Dialogue.dialogueAsset = dialogue
		
	
		
	

func _physics_process(delta: float) -> void:
	
	if currentDay == 0:
		dayEnemies = 1
		onlinePlayers = "5000"
	elif currentDay == 1:
		dayEnemies = 1
		onlinePlayers = "4300"
