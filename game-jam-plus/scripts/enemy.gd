extends CharacterBody2D

var types = {
	"wolf": [15, 2, 25, 50],
	"goblin": [15, 2, 25, 50],
	"skeleton": [15, 2, 25, 50]
}
@export var type: String = "wolf"
var life: int
var DAMAGE: int
var SPEED: int
@export var radius_limit : float = 100.0
@export var detection_radius : float = 200.0

var INITIAL_POSITION : Vector2
var distance : float
@export var timer : float = 1.0
var DIRECTION : Vector2
var move_flag : bool
var rng = RandomNumberGenerator.new()

enum State {WANDER, ATTACK}
var cur_state: State = State.WANDER

func _ready() -> void:
	var stats = types.get(type, [15, 2, 25, 50])
	life = stats[0]
	DAMAGE = stats[1]
	SPEED = stats[2]
	INITIAL_POSITION = global_position
	
	if has_node("Timer"):
		$Timer.wait_time = timer
		$Timer.start()

func _physics_process(delta: float) -> void:
	check_player_distance()
	
	match cur_state:
		State.WANDER:
			wander()
		State.ATTACK:
			attack()
		
	move_and_slide()

func check_player_distance() -> void: pass
	#var distance_to_player = global_position.distance_to(Global.player_pos)
	
	#if distance_to_player <= detection_radius:
		#cur_state = State.ATTACK
	#else:
		#if cur_state == State.ATTACK:
			#cur_state = State.WANDER
			#move_flag = false

func _on_timer_timeout() -> void:
	if cur_state == State.ATTACK:
		return
		
	var prob = rng.randf_range(0.0, 1.0)
	
	if(prob < 0.55):
		var angle = randf_range(0.0, TAU)
		var length = randf_range(0.2, 1.0)
		DIRECTION = (Vector2.from_angle(angle) * length).normalized()
	else:
		DIRECTION = Vector2.ZERO
	
	move_flag = true
	
func wander(): 
	distance = global_position.distance_to(INITIAL_POSITION)
	
	if(distance >= radius_limit and move_flag):
		velocity = SPEED * global_position.direction_to(INITIAL_POSITION)
		move_flag = false
	elif(distance < radius_limit and move_flag):
		velocity = SPEED * DIRECTION
		move_flag = false

func attack(): pass 
	#velocity = SPEED * global_position.direction_to(Global.player_pos)
