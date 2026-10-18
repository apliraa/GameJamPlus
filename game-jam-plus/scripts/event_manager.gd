extends Node

@export var events: Array[Node]

@export var playerDialogue: CharacterDialogue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
