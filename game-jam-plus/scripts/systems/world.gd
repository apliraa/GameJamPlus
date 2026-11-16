extends Node2D

@export var enemys: Array[CharacterBody2D] = []

var enemyType: String = "Goblin"
var enemysInScene: int = Globals.dayEnemies
var currentEnemys: int = 0

@onready var missionText = $HUD/CanvasLayer/Missions/MissionText
@onready var missionQuantity = $HUD/CanvasLayer/Missions/Quantity
@onready var logout_screen = $HUD/CanvasLayer/Logout

func _ready() -> void:
	enemysInScene = Globals.dayEnemies
	$AnimationPlayer.play("fadeOut")
	print($Friend/Dialogue.dialogueAsset)
	# Esconde diretamente o conteúdo que está dentro do CanvasLayer do Logout
	logout_screen.hide()
	
	missionText.text = "Defeat: " + enemyType

	Globals.update_dialogue.connect(on_update_dialogue)
	Globals.on_set_dialogue()

func _process(_delta: float) -> void:
	
	#print("O Logout está visível? ", logout_screen.visible)
	# 1. Limpa o array automaticamente! Remove os inimigos que já tomaram queue_free()
	enemys = enemys.filter(func(enemy): return is_instance_valid(enemy))
	
	# 3. Atualiza o texto perfeitamente a cada frame
	missionQuantity.text = enemyType + " " + str(Globals.killedEnemies) + "/" + str(enemysInScene)
	
	# 4. Verifica se a missão acabou
	if Globals.killedEnemies == enemysInScene and enemysInScene > 0:
		set_process(false)
		await get_tree().create_timer(1.0).timeout
		logout_screen.show()	
		
func on_update_dialogue(dialogue):
	$Friend/Dialogue.dialogueAsset = dialogue
	$Friend/Dialogue/SpeechAnchor.default_dialogue = dialogue
	print(dialogue)
	print("recebi")
