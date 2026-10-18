extends Node2D 
class_name CharacterDialogue

@export var nickname: String
@onready var speech_anchor: SpeechAnchor = $SpeechAnchor

@export var dialogueAsset: DialogueResource
@export var curDialogue: String

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout	
	playDialogue(curDialogue)

func playDialogue(eventName: String) -> void:
	if speech_anchor == null:
		push_error("CharacterDialogue: no child node named 'SpeechAnchor'.")
		return
	curDialogue = eventName
	speech_anchor.say()
