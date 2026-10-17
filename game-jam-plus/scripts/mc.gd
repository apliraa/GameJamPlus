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
		else:
			velocity = Vector2.ZERO
			is_moving = false
			
			
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func gainXP()-> void:
	print(XP)
