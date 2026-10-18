extends Node2D

@export var enemys: Array[CharacterBody2D] = []

var enemyType: String = "Goblin"
var enemysInScene: int = 0
var currentEnemys: int = 0

@onready var missionText = $CanvasLayer/Missions/MissionText
@onready var missionQuantity = $CanvasLayer/Missions/Quantity
@onready var logout_screen = $CanvasLayer/Logout

func _ready() -> void:
	$AnimationPlayer.play("fadeOut")
	
	# Esconde o logout logo no início
	logout_screen.hide()
	
	# Pega a quantidade de inimigos APÓS a cena carregar e o @export ser preenchido
	enemysInScene = enemys.size()
	
	missionText.text = "Defeat: " + enemyType

func _process(_delta: float) -> void:
	
	# 1. Limpa o array automaticamente! Remove os inimigos que já tomaram queue_free()
	enemys = enemys.filter(func(enemy): return is_instance_valid(enemy))
	
	# 2. Calcula quantos morreram
	currentEnemys = enemysInScene - enemys.size()
	
	# 3. Atualiza o texto perfeitamente a cada frame
	missionQuantity.text = enemyType + " " + str(currentEnemys) + "/" + str(enemysInScene)
	
	# 4. Verifica se a missão acabou
	if enemys.is_empty() and enemysInScene > 0:
		set_process(false) # Para o processamento para não rodar esse timer 60x por segundo
		await get_tree().create_timer(1.0).timeout
		logout_screen.show()
