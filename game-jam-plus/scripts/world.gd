extends Node2D

@export var enemys: Array[CharacterBody2D] = []


var enemyType: String = "Wolf"
var enemysInScene: int = 10
var currentEnemys: int = 0


@onready var missionText = $CanvasLayer/Missions/MissionText
@onready var missionQuantity = $CanvasLayer/Missions/Quantity

func _ready() -> void:
	$AnimationPlayer.play("fadeOut")
	
	
	missionText.text = "Defeat: " + enemyType


func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		if not enemys.is_empty():
			enemys.pop_back()
			
		
		if enemys.is_empty():
			
			set_process(false) 
			await get_tree().create_timer(1.0).timeout
			get_tree().quit()
	

	missionQuantity.text = enemyType + " " + str(currentEnemys) + "/" + str(enemysInScene)
