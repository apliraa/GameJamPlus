extends CharacterBody2D


const SPEED = 150.0
@export var radius_limit : float
var INITIAL_POSITION : Vector2
var distance : float
@export var timer : float
var DIRECTION : Vector2
var move_flag : bool
var rng = RandomNumberGenerator.new()


func _ready() -> void:
	INITIAL_POSITION = global_position
	$Timer.wait_time = timer
	$Timer.start()
	
	

func _physics_process(delta: float) -> void:
	distance = global_position.distance_to(INITIAL_POSITION)
	
	if(distance >= radius_limit and move_flag):
		velocity = SPEED * (global_position.direction_to(INITIAL_POSITION)).normalized()
		move_flag = false
	elif(distance < radius_limit and move_flag):
		velocity = SPEED * DIRECTION
		move_flag = false
		
	move_and_slide()


func _on_timer_timeout() -> void:
	var prob = rng.randf_range(0.0, 1.0)
	
	if(prob < 0.55):
		var angle = randf_range(0.0, TAU)
		DIRECTION = (Vector2.from_angle(angle)).normalized()
	else:
		DIRECTION = Vector2.ZERO
	
	move_flag = true
	
	
