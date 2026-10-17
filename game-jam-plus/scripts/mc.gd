extends CharacterBody2D

@export var	mouseDirection = Vector2.ZERO
@export var direcao = Vector2.ZERO
var distancia = Vector2.ZERO  
var velocityTarget = Vector2.ZERO
const SPEED = 300.0
const ACC = 20.0
var distanciaMouse

func _physics_process(delta: float) -> void:
	
	
	
	if(Input.is_action_just_pressed("left_click")):
		mouseDirection = get_global_mouse_position() 
		direcao = global_position.direction_to(mouseDirection)
		velocity = direcao * SPEED
		
	distanciaMouse = global_position.distance_to(mouseDirection)
	
	if(velocity != Vector2.ZERO and distanciaMouse <= (SPEED*delta) ):
		global_position = mouseDirection
		velocity = Vector2.ZERO
		
		
		
	
	
	
		
	
	
	
	
		
	move_and_slide()
