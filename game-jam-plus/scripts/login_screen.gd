extends Control
@onready var timer = $Timer
@onready var user = $LoginModal/ColorRect/ColorRect/UserLabelText
@onready var password = $LoginModal/ColorRect2/ColorRect/PasswordLabelText
@onready var online = $ColorRect/Online
const ONLINE_PLAYERS = "1200"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventManager._startDay()
	user.visible_characters = 0
	password.visible_characters = 0
	timer.wait_time = 0.1
	timer.start()
	online.text = online.text + ONLINE_PLAYERS
	 # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass


func _on_timer_timeout() -> void:
	if user.visible_characters < user.text.length():
			user.visible_characters += 1
	elif password.visible_characters < password.text.length():
			password.visible_characters += 1
			#som de teclar
	else:
		timer.stop()
		
		await get_tree().create_timer(1.0).timeout
		$LoginModal.hide()
		$LoginOk.show()
		await get_tree().create_timer(2.0).timeout
		$FadeAnim.play("fade")
		
			
		
	
func _on_fade_anim_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	pass # Replace with function body.
