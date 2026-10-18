extends CharacterBody2D

@export var life: int = 15
@export var DAMAGE: int = 2
@export var SPEED: float = 40.0
@export var radius_limit: float = 100.0

const DETECTION_MULTIPLIER := 2.0

var detection_radius: float

var xp_reward: int = 10
var attack_cooldown: float = 1.0

var INITIAL_POSITION: Vector2
var DIRECTION: Vector2
var rng = RandomNumberGenerator.new()

enum State {WANDER, ATTACK}
var cur_state: State = State.WANDER

@onready var wander_timer: Timer = $Timer
@onready var damage_timer: Timer = $DamageTimer
@onready var damage_area: Area2D = $DamageArea
@onready var target_sprite: Sprite2D = $TargetSprite

func _ready() -> void:
	add_to_group("Enemies")
	target_sprite.visible = false
	
	detection_radius = radius_limit * DETECTION_MULTIPLIER
	INITIAL_POSITION = global_position
	
	new_direction()
	
	wander_timer.timeout.connect(_on_timer_timeout)
	wander_timer.wait_time = rng.randf_range(1.0, 5.0)
	wander_timer.start()
	
	damage_timer.one_shot = true
	damage_timer.wait_time = attack_cooldown

func _physics_process(_delta: float) -> void:
	check_player_distance()
	match cur_state:
		State.WANDER:
			wander()
			update_animations()
		State.ATTACK:
			attack()
			update_animations()
	
	
	
	move_and_slide()

func check_player_distance() -> void:
	if global_position.distance_to(Globals.player_pos) <= detection_radius:
		cur_state = State.ATTACK
	else:
		cur_state = State.WANDER

func _on_timer_timeout() -> void:
	if cur_state == State.ATTACK:
		return
	new_direction()

func new_direction() -> void:
	if rng.randf() < 0.55:
		DIRECTION = Vector2.from_angle(rng.randf_range(0.0, TAU))
			
	else:
		DIRECTION = Vector2.ZERO
	

func wander():
	if global_position.distance_to(INITIAL_POSITION) >= radius_limit:
		DIRECTION = global_position.direction_to(INITIAL_POSITION)
	
	velocity = SPEED * DIRECTION

func attack():
	var damage_target = get_damage_target()
	if damage_target == null:
		velocity = SPEED * global_position.direction_to(Globals.player_pos)
		return
	
	velocity = Vector2.ZERO
	if damage_timer.is_stopped():
		deal_damage(damage_target)

func get_damage_target() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("Player") or body.is_in_group("Friend"):
			var d = global_position.distance_squared_to(body.global_position)
			if d < best:
				best = d
				nearest = body
	return nearest

func deal_damage(body: Node2D) -> void:
	damage_timer.start()
	play_attack_animation()
	body.receive_damage(DAMAGE)

func receive_damage(amount: int) -> void:
	life = max(life - amount, 0)
	play_hit_animation()
	if life == 0:
		die()

func set_targeted(value: bool) -> void:
	target_sprite.visible = value

func play_attack_animation() -> void:
	pass

func play_hit_animation() -> void:
	$AnimationPlayer.play()

func die() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player != null:
		player.gainXP(xp_reward)
	queue_free()
	
func update_animations() -> void:
	# Memoriza a direção enquanto estiver andando
	if DIRECTION != Vector2.ZERO:
		DIRECTION = velocity.normalized()

	# Lógica quando está PARADO
	if DIRECTION == Vector2.ZERO:
		if DIRECTION.x > 0.1:
			$Sprite2D.play("Idle R")
		elif DIRECTION.x < -0.1:
			$Sprite2D.play("Idle L")
		elif DIRECTION.y > 0:
			$Sprite2D.play("Idle")
		elif DIRECTION.y < 0:
			$Sprite2D.play("Idle B")
			
	# Lógica quando está ANDANDO
	else:
		if DIRECTION.x > 0.1:
			$Sprite2D.play("Walk R")
		elif DIRECTION.x < -0.1:
			$Sprite2D.play("Walk L")
		elif DIRECTION.y > 0:
			$Sprite2D.play("Walk F")
		elif DIRECTION.y < 0:
			$Sprite2D.play("Walk B")
