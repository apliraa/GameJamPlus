extends Node2D 
class_name CharacterDialogue

@export var nickname: String
@onready var speech_anchor: SpeechAnchor = $SpeechAnchor

@export var dialogueAsset: DialogueResource
@export var curDialogue: String

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout  
	speech_anchor.say(nickname, dialogueAsset, curDialogue)
