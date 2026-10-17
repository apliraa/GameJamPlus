extends CharacterBody2D

var types = {
	"wolf": [15, 2, 200, 600.0],
	"goblin": [15, 2, 25, 100.0],
	"skeleton": [15, 2, 25, 100.0]
}
@export var type: String = "wolf"
var life: int
var DAMAGE: int
var SPEED: int
var radius_limit : float
var detection_radius : float

var INITIAL_POSITION : Vector2
var distance : float
var timer : float = 1.0
var DIRECTION : Vector2
var move_flag : bool
var rng = RandomNumberGenerator.new()

enum State {WANDER, ATTACK}
var cur_state: State = State.WANDER

func _ready() -> void:
	var stats = types.get(type, [15, 2, 25, 100.0])
	life = stats[0]
	DAMAGE = stats[1]
	SPEED = stats[2]
	radius_limit = stats[3]
	detection_radius = radius_limit * 2
	INITIAL_POSITION = global_position
	timer = randf_range(1.0, 5.0)
	
	new_direction()
	
	if has_node("Timer"):
		var t = $Timer as Timer
		if not t.timeout.is_connected(_on_timer_timeout):
			t.timeout.connect(_on_timer_timeout)
		t.wait_time = timer
		t.start()

func _physics_process(delta: float) -> void:
	check_player_distance()
	match cur_state:
		State.WANDER:
			wander()
		State.ATTACK:
			attack()
	
	move_and_slide()

func check_player_distance() -> void:
	var distance_to_player = global_position.distance_to(Globals.player_pos)
	
	if distance_to_player <= detection_radius:
		cur_state = State.ATTACK
	else:
		if cur_state == State.ATTACK:
			cur_state = State.WANDER
			move_flag = false

func _on_timer_timeout() -> void:
	if cur_state == State.ATTACK:
		return
	
	new_direction()
	move_flag = true

func new_direction() -> void:
	var prob = rng.randf_range(0.0, 1.0)
	
	if(prob < 0.55):
		var angle = rng.randf_range(0.0, TAU)
		var length = rng.randf_range(0.2, 1.0)
		DIRECTION = (Vector2.from_angle(angle) * length).normalized()
	else:
		DIRECTION = Vector2.ZERO
	
func wander(): 
	distance = global_position.distance_to(INITIAL_POSITION)
	
	if distance >= radius_limit:
		DIRECTION = global_position.direction_to(INITIAL_POSITION)
	
	velocity = SPEED * DIRECTION

func attack():
	velocity = SPEED * global_position.direction_to(Globals.player_pos)


func _on_enemy_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_enemy_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
