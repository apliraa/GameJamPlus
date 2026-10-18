extends CharacterBody2D

const SPEED := 100.0
const CLICK_RADIUS := 24.0

var posicao_alvo = Vector2.ZERO
var is_moving = false # Controla se o personagem deve andar ou não

var XP: int

var MAX_LIFE: int = 100
var life: int = MAX_LIFE
var DAMAGE: int = 10

var attack_cooldown: float = 1.0
var target_enemy: Node2D = null

@onready var damage_area: Area2D = $DamageArea
@onready var damage_timer: Timer = $DamageTimer

func _ready() -> void:
	add_to_group("Player")
	# Define o alvo inicial como a própria posição para ele não ir pro ponto (0,0) ao iniciar
	posicao_alvo = global_position
	damage_timer.one_shot = true
	damage_timer.wait_time = attack_cooldown

func _physics_process(delta: float) -> void:
	Globals.player_pos = global_position
	
	if not is_instance_valid(target_enemy):
		target_enemy = null
	
	# 1. Atualiza o destino quando clica
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
			
		var clicked_enemy = get_enemy_at_mouse()
		if clicked_enemy != null:
			set_target(clicked_enemy)
		else:
			clear_target()
			posicao_alvo = get_global_mouse_position()
			is_moving = true
	
	# 2. Persegue o alvo e ataca quando ele está na área de dano
	if target_enemy != null:
		if damage_area.overlaps_body(target_enemy):
			is_moving = false
			attack(target_enemy)
		else:
			posicao_alvo = target_enemy.global_position
			is_moving = true
	
	# 3. Movimento contínuo, a direção é recalculada todos os frames
	velocity = Vector2.ZERO
	if is_moving:
		if global_position.distance_to(posicao_alvo) > SPEED * delta:
			velocity = global_position.direction_to(posicao_alvo) * SPEED
		else:
			# Chegou no destino
			is_moving = false
	
	move_and_slide()

func get_enemy_at_mouse() -> Node2D:
	var mouse_pos = get_global_mouse_position()
	var nearest: Node2D = null
	var best := CLICK_RADIUS * CLICK_RADIUS
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		var d = mouse_pos.distance_squared_to(enemy.global_position)
		if d <= best:
			best = d
			nearest = enemy
	return nearest

func set_target(enemy: Node2D) -> void:
	clear_target()
	target_enemy = enemy
	enemy.set_targeted(true)

func clear_target() -> void:
	if target_enemy != null:
		target_enemy.set_targeted(false)
	target_enemy = null

func attack(enemy: Node2D) -> void:
	if not damage_timer.is_stopped():
		return
	damage_timer.start()
	play_attack_animation()
	enemy.receive_damage(DAMAGE)

func receive_damage(amount: int) -> void:
	life = max(life - amount, 0)
	play_hit_animation()
	if life == 0:
		die()

func play_attack_animation() -> void:
	pass

func play_hit_animation() -> void:
	pass

func die() -> void:
	pass

# CORRIGIDO: A função gainXP agora apenas soma a experiência, sem atrapalhar a física.
func gainXP(amount: int) -> void:
	XP += amount
