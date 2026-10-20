extends Node

@export var events: Array[Node]
@export var playerDialogue: CharacterDialogue
var chat: FakeChat

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	chat = get_tree().get_first_node_in_group("fake_chat") as FakeChat

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _startDay() -> void:
	update_events(Globals.currentDay)
	_set_friend_dialogue()
	var chat: FakeChat = get_tree().get_first_node_in_group("fake_chat") as FakeChat
	if chat != null:
		chat._refresh_online_users()

func _set_friend_dialogue() -> void:
	var friend := get_tree().current_scene.get_node_or_null("Friend/Dialogue") as CharacterDialogue
	if friend == null:
		return
	if Globals.currentDay == 1:
		friend.dialogueAsset = load("res://dialogues/day2.dialogue")
	

func update_events(current_day_id: int) -> void:
	for i in events.size():
		set_event_active(events[i], i == current_day_id)

func set_event_active(event: Node, active: bool) -> void:
	if active:
		event.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		event.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Hide it too, if it's something visible (Node2D, Control, etc.)
	if event is CanvasItem:
		event.visible = active
		
	
func disable_map() -> void:
	var map := get_tree().current_scene.get_node_or_null("Map")
	if map != null and Globals.diaDoisEvento == false:
		map.hide()
	elif(Globals.diaDoisEvento):
		map.show()
		
	Globals.diaDoisEvento = true

func disable_friend() -> void:
	var friend := get_tree().current_scene.get_node_or_null("Friend")
	if friend != null:
		friend.hide()
		friend.set_physics_process(false)
	
	
	

func _endDay() -> void:
	Globals.currentDay += 1
	
	
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
