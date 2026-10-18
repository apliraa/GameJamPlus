extends CharacterBody2D

var posicao_alvo = Vector2.ZERO
var is_moving = false

const SPEED = 150.0
const ACC = 20.0
var XP: int

func _ready() -> void:
	posicao_alvo = global_position

func _physics_process(delta: float) -> void:
	Globals.player_pos = global_position
	
	if Input.is_action_just_pressed("left_click"):
		posicao_alvo = get_global_mouse_position() 
		is_moving = true
		
	if is_moving:
		var distancia = global_position.distance_to(posicao_alvo)
		
		if distancia > (SPEED * delta):
			var direcao = global_position.direction_to(posicao_alvo)
			velocity = direcao * SPEED
			
			if(direcao.x > 0.1):
				$Sprite2D.play_animations("Walk R")
			elif(direcao.x < -0.1):
				$Sprite2D.play_animations("Walk L")
			elif(direcao.y > 0):
				$Sprite2D.play_animations("Walk F")
			elif(direcao.y < 0):
				$Sprite2D.play_animations("Walk B")
		else:
			var direcao = global_position.direction_to(posicao_alvo)
			
			if(direcao.x > 0.1):
				$Sprite2D.play_animations("Idle R")
			elif(direcao.x < -0.1):
				$Sprite2D.play_animations("Idle L")
			elif(direcao.y > 0):
				$Sprite2D.play_animations("Idle")
			elif(direcao.y < 0):
				$Sprite2D.play_animations("Idle B")
			
			velocity = Vector2.ZERO
			
			is_moving = false
			
			
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func gainXP()-> void:
	print(XP)
