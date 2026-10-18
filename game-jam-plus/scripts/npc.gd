extends CharacterBody2D


const SPEED = 30.0
@export var radius_limit : float
var INITIAL_POSITION : Vector2
var distance : float
@export var timer : float
var DIRECTION : Vector2
var move_flag : bool = true
var rng = RandomNumberGenerator.new()
var animation : AnimatedSprite2D
var last_direction : Vector2

func _ready() -> void:
	
	generate_npc()
	
	INITIAL_POSITION =  global_position
	$Timer.wait_time = timer
	$Timer.start()
	var angle = randf_range(0.0, TAU)
	DIRECTION = (Vector2.from_angle(angle)).normalized()
	

func _physics_process(_delta: float) -> void:
	distance = global_position.distance_to(INITIAL_POSITION)
	
	if(distance >= radius_limit and move_flag):
		velocity = SPEED * (global_position.direction_to(INITIAL_POSITION)).normalized()
		move_flag = false
	elif(distance < radius_limit and move_flag):
		velocity = SPEED * DIRECTION
		move_flag = false	
	
	update_animations()
	move_and_slide()
	

func _on_timer_timeout() -> void:
	var prob = rng.randf_range(0.0, 1.0)
	
	if(prob < 0.55):
		var angle = randf_range(0.0, TAU)
		DIRECTION = (Vector2.from_angle(angle)).normalized()
	else:
		DIRECTION = Vector2.ZERO
	
	move_flag = true
	
	


func _on_hit_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		var direction = body.global_position.direction_to(global_position)
		DIRECTION = direction
		move_flag = false

func generate_npc():
	var chance = rng.randf_range(0.0, 1.0)
	
	if(chance <= 0.4 ):
		$Mage.queue_free()
		$Thief.queue_free()
		animation = $Warrior
		$Warrior.self_modulate = Color.from_hsv(randf_range(0.02, 0.08), randf_range(0.20, 0.55), randf_range(0.30, 0.95))
		$Warrior/Helm.self_modulate = Color(randf(), randf(), randf())
		$Warrior/Plate.self_modulate = Color(randf(), randf(), randf())
		$Warrior/Boots.self_modulate = Color(randf(), randf(), randf())
	elif(chance <= 0.7):
		$Warrior.queue_free()
		$Mage.queue_free()
		animation = $Thief
		$Thief.self_modulate = Color.from_hsv(randf_range(0.02, 0.08), randf_range(0.20, 0.55), randf_range(0.30, 0.95))
		$Thief/Helm.self_modulate = Color(randf(), randf(), randf())
		$Thief/Plate.self_modulate = Color(randf(), randf(), randf())
		$Thief/Boots.self_modulate = Color(randf(), randf(), randf())
	else:
		$Thief.queue_free()
		$Warrior.queue_free()
		animation = $Mage
		$Mage.self_modulate = Color.from_hsv(randf_range(0.02, 0.08), randf_range(0.20, 0.55), randf_range(0.30, 0.95))
		$Mage/Helm.self_modulate = Color(randf(), randf(), randf())
		$Mage/Plate.self_modulate = Color(randf(), randf(), randf())
		$Mage/Boots.self_modulate = Color(randf(), randf(), randf())
		
		

func update_animations() -> void:
	# Memoriza a direção enquanto estiver andando
	if DIRECTION != Vector2.ZERO:
		DIRECTION = DIRECTION.normalized()
		last_direction = DIRECTION
	# Lógica quando está PARADO
	if velocity == Vector2.ZERO:
		if last_direction.x > 0:
			animation.play_animations("Idle R")
		elif last_direction.x < -0:
			animation.play_animations("Idle L")
		elif last_direction.y > 0:
			animation.play_animations("Idle")
		elif last_direction.y < 0:
			animation.play_animations("Idle B")
			
	# Lógica quando está ANDANDO
	else:
		if DIRECTION.x > 0:
			animation.play_animations("Walk R")
		elif DIRECTION.x < -0:
			animation.play_animations("Walk L")
		elif DIRECTION.y > 0:
			animation.play_animations("Walk F")
		elif DIRECTION.y < 0:
			animation.play_animations("Walk B")
