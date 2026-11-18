extends Node

@export var events: Array #Os indíces desse array representam os dias dos eventos e dentro desses indices devem estar arrays com os respectivos eventos.
var chat: FakeChat

signal set_day
signal set_events(scene: PackedScene)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	chat = get_tree().get_first_node_in_group("fake_chat") as FakeChat
	
	set_day.connect(Globals.on_set_day)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _startDay() -> void:
	update_events(Globals.currentDay)
	var chat: FakeChat = get_tree().get_first_node_in_group("fake_chat") as FakeChat
	if chat != null:
		chat._refresh_online_users()

func _change_friend_dialogue(Dialogue) -> void:
	var friend := get_tree().current_scene.get_node_or_null("Friend/Dialogue") as CharacterDialogue
	if friend == null:
		return
	else:
		friend.dialogueAsset = Dialogue
	

func update_events(Current_day) -> void:
	var map := get_tree().current_scene.get_node_or_null("Map")
	
	if events[Current_day] == null:
		pass
	else:
		for i in events[Current_day]:
			if i != null:
				set_events.emit(i)
			else:
				break
		
	
func disable_map() -> void:
	var map := get_tree().current_scene.get_node_or_null("Map")
	if map != null:
		map.hide()


func able_map () -> void:
	var map := get_tree().current_scene.get_node_or_null("Map")
	if map != null:
		map.show()
		


func disable_friend() -> void:
	var friend := get_tree().current_scene.get_node_or_null("Friend")
	if friend != null:
		friend.hide()
		friend.set_physics_process(false)
	
	
	

func _endDay() -> void:
	Globals.currentDay += 1
	set_day.emit()
	
	
func freeze_friend() -> void:
		var friend := get_tree().current_scene.get_node_or_null("Friend")
		var sprite = friend.get_node("Sprite2D")
		if friend != null:
			sprite.animation = "Idle"
			friend.set_physics_process(false)
				
func unfreeze_friend() -> void:
		var friend := get_tree().current_scene.get_node_or_null("Friend")
		if friend != null:
			friend.set_physics_process(true)
			
func freeze_player() -> void:
	var player := get_tree().current_scene.get_node_or_null("mc")
	if player != null:
		player.set_physics_process(false)
		
func unfreeze_player() -> void:
	var player := get_tree().current_scene.get_node_or_null("mc")
	if player != null:
		player.set_physics_process(true)
