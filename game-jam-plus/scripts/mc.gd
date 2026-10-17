extends CharacterBody2D


const SPEED = 300.0


func _physics_process(delta: float) -> void:
	if(Input.is_action_just_pressed("left_click")):
		var	mouseDirection = get_global_mouse_position()
		var prevDirection = get_position_delta()
		
		
		move_toward(prevDirection, mouseDirection, SPEED)
		move_and_slide()
