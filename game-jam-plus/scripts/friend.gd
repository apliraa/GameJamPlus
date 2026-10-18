extends CharacterBody2D

enum Actions {
	WAIT,
	FOLLOW,
	ATTACK,
	BACK_AND_FORTH,
	CIRCLE
}
var cur_action: Actions = Actions.WAIT

var DAMAGE: int = 15
var SPEED: int = 70
var timer: float = 1.0

var target: Vector2
var follow_offset: Vector2 = Vector2.ZERO
var enemies_in_range: Array = []
var rng = RandomNumberGenerator.new()

var circle_angle: float = 0.0
var circle_dir: float = 1.0
var circle_target_angle: float = 0.0
var circle_completed_angle: float = 0.0
var circle_radius: float = 350.0
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

func _ready() -> void:
	player_max_distance = player_radius * 2
	last_player_pos = Globals.player_pos
	if has_node("Timer"):
		var t = $Timer as Timer
		if not t.timeout.is_connected(_on_timer_timeout):
			t.timeout.connect(_on_timer_timeout)
		t.wait_time = timer
		t.start()
	if has_node("EnemyArea"):
		$EnemyArea.body_entered.connect(_on_enemy_entered)
		$EnemyArea.body_exited.connect(_on_enemy_exited)

func _physics_process(delta: float) -> void:
	player_distance = global_position.distance_to(Globals.player_pos)
	enemies_in_range = enemies_in_range.filter(is_instance_valid)
	
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

func click_move(point: Vector2, arrive_distance: float = 15.0, speed_scale: float = 1.0) -> bool:
	var step = SPEED * speed_scale * get_physics_process_delta_time()
	if global_position.distance_to(point) <= max(arrive_distance, step):
		velocity = Vector2.ZERO
		return true
	velocity = global_position.direction_to(point) * SPEED * speed_scale
	return false

func random_offset(min_dist: float, max_dist: float) -> Vector2:
	return Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(min_dist, max_dist)

func wait():
	velocity = Vector2.ZERO

func follow():
	if player_distance < player_min_distance:
		velocity = Vector2.ZERO
	elif click_move(Globals.player_pos + follow_offset) and player_distance > player_max_distance:
		follow_offset = random_offset(player_min_distance, player_radius)

func attack():
	if enemies_in_range.size() > 0:
		var nearest_enemy = enemies_in_range[0]
		for enemy in enemies_in_range:
			if global_position.distance_squared_to(enemy.global_position) < global_position.distance_squared_to(nearest_enemy.global_position):
				nearest_enemy = enemy
		click_move(nearest_enemy.global_position)
	else:
		cur_action = Actions.WAIT

func back_and_forth():
	if click_move(target, 25.0, 0.8):
		back_forth_legs -= 1
		if back_forth_legs <= 0:
			cur_action = Actions.WAIT
		elif target == back_forth_a:
			target = back_forth_a + back_forth_dir * random_step_length()
		else:
			target = back_forth_a

func random_step_length() -> float:
	if rng.randf() < 0.5:
		return rng.randf_range(80.0, 200.0)
	return rng.randf_range(350.0, 700.0)

func circle():
	if player_idle_time < circle_idle_threshold:
		cur_action = Actions.WAIT
		return
	var point = Globals.player_pos + Vector2.from_angle(circle_angle) * circle_radius
	if click_move(point, 25.0):
		circle_angle += circle_click_step * circle_dir
		circle_completed_angle += circle_click_step
		if circle_completed_angle >= circle_target_angle:
			cur_action = Actions.WAIT

func _on_timer_timeout() -> void:
	next_action()
	
func next_action():
	if player_distance > player_max_distance:
		if cur_action != Actions.FOLLOW:
			cur_action = Actions.FOLLOW
			follow_offset = random_offset(player_min_distance, player_radius)
		return
	
	if enemies_in_range.size() > 0:
		cur_action = Actions.ATTACK
		return
	
	if cur_action == Actions.CIRCLE or cur_action == Actions.BACK_AND_FORTH:
		return

	var actions_pool = [Actions.FOLLOW, Actions.BACK_AND_FORTH]
	if player_idle_time >= circle_idle_threshold:
		actions_pool.append(Actions.CIRCLE)
	cur_action = actions_pool[rng.randi_range(0, actions_pool.size() - 1)]

	if cur_action == Actions.FOLLOW:
		follow_offset = random_offset(player_min_distance, player_radius)
	elif cur_action == Actions.CIRCLE:
		circle_radius = rng.randf_range(300.0, 500.0)
		circle_angle = (global_position - Globals.player_pos).angle()
		circle_dir = 1.0 if rng.randf() < 0.5 else -1.0
		circle_completed_angle = 0.0
		circle_target_angle = rng.randi_range(1, 3) * TAU
	elif cur_action == Actions.BACK_AND_FORTH:
		back_forth_a = Globals.player_pos + random_offset(player_min_distance + 50.0, player_radius * 0.7)
		back_forth_dir = Vector2.from_angle(rng.randf_range(0.0, TAU))
		back_forth_legs = rng.randi_range(2, 6)
		target = back_forth_a

func _on_enemy_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		enemies_in_range.append(body)

func _on_enemy_exited(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		enemies_in_range.erase(body)
