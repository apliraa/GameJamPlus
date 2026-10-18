extends CharacterBody2D


const ARRIVE_DISTANCE := 6.0
const ARRIVE_DISTANCE_WIDE := 10.0

const PLAYER_MIN_DISTANCE := 120.0
const PLAYER_RADIUS := 300.0
const PLAYER_MAX_DISTANCE := PLAYER_RADIUS * 2.0

const CIRCLE_RADIUS_MIN := 100.0
const CIRCLE_RADIUS_MAX := 170.0

const BACK_FORTH_MARGIN := 16.0
const SHORT_STEP_MIN := 30.0
const SHORT_STEP_MAX := 70.0
const LONG_STEP_MIN := 120.0
const LONG_STEP_MAX := 230.0

enum Actions {
	WAIT,
	FOLLOW,
	ATTACK,
	BACK_AND_FORTH,
	CIRCLE
}
var cur_action: Actions = Actions.WAIT

var DAMAGE: int = 15
var timer: float = 1.0
var attack_cooldown: float = 1.0

var target: Vector2
var follow_offset: Vector2 = Vector2.ZERO
var rng = RandomNumberGenerator.new()
var last_direction : Vector2

var circle_angle: float = 0.0
var circle_dir: float = 1.0
var circle_target_angle: float = 0.0
var circle_completed_angle: float = 0.0
var circle_radius: float = 120.0
var circle_click_step: float = TAU / 8.0

var back_forth_a: Vector2 = Vector2.ZERO
var back_forth_dir: Vector2 = Vector2.RIGHT
var back_forth_legs: int = 0

var player_min_distance: float = 350.0
var player_radius: float = 700.0
var player_max_distance: float
var player_distance: float

var last_player_pos: Vector2 = Vector2.ZERO
var player_idle_time: float = 0.0
var circle_idle_threshold: float = 11.0

var stuck_time: float = 0.0
var stuck_threshold: float = 0.4
var retreat_time: float = 0.0
var retreat_duration: float = 0.4
var retreat_dir: Vector2 = Vector2.ZERO

@onready var action_timer: Timer = $Timer
@onready var damage_timer: Timer = $DamageTimer
@onready var enemy_area: Area2D = $EnemyArea
@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
	add_to_group("Friend")
	last_player_pos = Globals.player_pos
	
	action_timer.timeout.connect(_on_timer_timeout)
	action_timer.wait_time = timer
	action_timer.start()
	
	damage_timer.one_shot = true
	damage_timer.wait_time = attack_cooldown

func _physics_process(delta: float) -> void:
	player_distance = global_position.distance_to(Globals.player_pos)
	
	if Globals.player_pos.distance_to(last_player_pos) > 1.0:
		player_idle_time = 0.0
	else:
		player_idle_time += delta
	last_player_pos = Globals.player_pos
	
	if retreat_time > 0.0:
		retreat_time -= delta
		velocity = retreat_dir * SPEED * 0.6
		move_and_slide()
		if retreat_time <= 0.0:
			cur_action = Actions.WAIT
			next_action()
		return
	
	match cur_action:
		Actions.WAIT:
			wait()
		Actions.FOLLOW:
			follow()
		Actions.ATTACK:
			attack()
		Actions.BACK_AND_FORTH:
			back_and_forth()
		Actions.CIRCLE:
			circle()
	
	var intended = velocity
	move_and_slide()
	check_stuck(intended, delta)
	update_animations()

func check_stuck(intended: Vector2, delta: float) -> void:
	if cur_action == Actions.ATTACK or intended == Vector2.ZERO:
		stuck_time = 0.0
		return
	
	if get_real_velocity().length() < intended.length() * 0.3:
		stuck_time += delta
	else:
		stuck_time = 0.0
	
	if stuck_time >= stuck_threshold:
		stuck_time = 0.0
		retreat_dir = -intended.normalized()
		retreat_time = retreat_duration

func click_move(point: Vector2, arrive: float = ARRIVE_DISTANCE, speed_scale: float = 1.0) -> bool:
	var step = SPEED * speed_scale * get_physics_process_delta_time()
	if global_position.distance_to(point) <= max(arrive, step):
		velocity = Vector2.ZERO
		return true
	velocity = global_position.direction_to(point) * SPEED * speed_scale
	return false

func random_offset(min_dist: float, max_dist: float) -> Vector2:
	return Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(min_dist, max_dist)

func nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for body in enemy_area.get_overlapping_bodies():
		if body.is_in_group("Enemies"):
			var d = global_position.distance_squared_to(body.global_position)
			if d < best:
				best = d
				nearest = body
	return nearest

func wait():
	velocity = Vector2.ZERO

func follow():
	if player_distance < PLAYER_MIN_DISTANCE:
		velocity = Vector2.ZERO
	elif click_move(Globals.player_pos + follow_offset) and player_distance > PLAYER_MAX_DISTANCE:
		follow_offset = random_offset(PLAYER_MIN_DISTANCE, PLAYER_RADIUS)

func attack():
	var enemy = nearest_enemy()
	if enemy == null:
		cur_action = Actions.WAIT
		return
	
	if damage_area.overlaps_body(enemy):
		velocity = Vector2.ZERO
		if damage_timer.is_stopped():
			deal_damage(enemy)
	else:
		click_move(enemy.global_position)

func deal_damage(enemy: Node2D) -> void:
	damage_timer.start()
	play_attack_animation()
	enemy.receive_damage(DAMAGE)

func play_attack_animation() -> void:
	pass

func play_hit_animation() -> void:
	pass

func receive_damage(_amount: int) -> void:
	play_hit_animation()

func back_and_forth():
	if click_move(target, ARRIVE_DISTANCE_WIDE, 0.8):
		back_forth_legs -= 1
		if back_forth_legs <= 0:
			cur_action = Actions.WAIT
		elif target == back_forth_a:
			target = back_forth_a + back_forth_dir * random_step_length()
		else:
			target = back_forth_a

func random_step_length() -> float:
	if rng.randf() < 0.5:
		return rng.randf_range(SHORT_STEP_MIN, SHORT_STEP_MAX)
	return rng.randf_range(LONG_STEP_MIN, LONG_STEP_MAX)

func circle():
	if player_idle_time < circle_idle_threshold:
		cur_action = Actions.WAIT
		return
	var point = Globals.player_pos + Vector2.from_angle(circle_angle) * circle_radius
	if click_move(point, ARRIVE_DISTANCE_WIDE):
		circle_angle += circle_click_step * circle_dir
		circle_completed_angle += circle_click_step
		if circle_completed_angle >= circle_target_angle:
			cur_action = Actions.WAIT

func _on_timer_timeout() -> void:
	next_action()

func next_action():
	if player_distance > PLAYER_MAX_DISTANCE:
		if cur_action != Actions.FOLLOW:
			cur_action = Actions.FOLLOW
			follow_offset = random_offset(PLAYER_MIN_DISTANCE, PLAYER_RADIUS)
		return
	
	if nearest_enemy() != null:
		cur_action = Actions.ATTACK
		return
	
	if cur_action == Actions.CIRCLE or cur_action == Actions.BACK_AND_FORTH:
		return

	var actions_pool = [Actions.FOLLOW, Actions.BACK_AND_FORTH]
	if player_idle_time >= circle_idle_threshold:
		actions_pool.append(Actions.CIRCLE)
	cur_action = actions_pool[rng.randi_range(0, actions_pool.size() - 1)]

	if cur_action == Actions.FOLLOW:
		follow_offset = random_offset(PLAYER_MIN_DISTANCE, PLAYER_RADIUS)
	elif cur_action == Actions.CIRCLE:
		circle_radius = rng.randf_range(CIRCLE_RADIUS_MIN, CIRCLE_RADIUS_MAX)
		circle_angle = (global_position - Globals.player_pos).angle()
		circle_dir = 1.0 if rng.randf() < 0.5 else -1.0
		circle_completed_angle = 0.0
		circle_target_angle = rng.randi_range(1, 3) * TAU
	elif cur_action == Actions.BACK_AND_FORTH:
		back_forth_a = Globals.player_pos + random_offset(PLAYER_MIN_DISTANCE + BACK_FORTH_MARGIN, PLAYER_RADIUS * 0.7)
		back_forth_dir = Vector2.from_angle(rng.randf_range(0.0, TAU))
		back_forth_legs = rng.randi_range(2, 6)
		target = back_forth_a


func update_animations() -> void:
	# Memoriza a direção enquanto estiver andando
	var direction = (velocity/SPEED)
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		last_direction = direction
	# Lógica quando está PARADO
	if direction == Vector2.ZERO:
		if last_direction.x > 0.1:
			$Sprite2D.play_animations("Idle R")
		elif last_direction.x < -0.1:
			$Sprite2D.play_animations("Idle L")
		elif last_direction.y > 0:
			$Sprite2D.play_animations("Idle")
		elif last_direction.y < 0:
			$Sprite2D.play_animations("Idle B")
			
	# Lógica quando está ANDANDO
	else:
		if direction.x > 0.1:
			$Sprite2D.play_animations("Walk R")
		elif direction.x < -0.1:
			$Sprite2D.play_animations("Walk L")
		elif direction.y > 0:
			$Sprite2D.play_animations("Walk F")
		elif direction.y < 0:
			$Sprite2D.play_animations("Walk B")
