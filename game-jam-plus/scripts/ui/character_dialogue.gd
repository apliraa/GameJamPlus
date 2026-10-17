extends Node2D  

@onready var speech_anchor: SpeechAnchor = $SpeechAnchor

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout  
	speech_anchor.say(null, "arthur")
