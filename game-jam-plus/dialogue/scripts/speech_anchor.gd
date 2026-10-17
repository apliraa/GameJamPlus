class_name SpeechAnchor
extends Marker2D
## Put one of these on every character (child of the player/NPC node) and move
## it to just above the character's head. Call say() to make that character
## speak in its own balloon. Each character has its own anchor, so many
## characters can talk at the same time.

signal speech_started
signal speech_finished

@export var balloon_scene: PackedScene   # drag SpeechBalloon.tscn here
@export var default_dialogue: DialogueResource
@export var default_title: String = "start"
## Nodes whose variables/functions the .dialogue file can use for this character
## (for example the character itself).
@export var extra_game_states: Array[Node] = []

var _current_balloon: SpeechBalloon


## Makes this character speak. If it is already speaking, the old balloon is
## replaced. Uses the default dialogue/title when none are given.
func say(resource: DialogueResource = null, title: String = "", extra: Array = []) -> void:
	if resource == null:
		resource = default_dialogue
	if title.is_empty():
		title = default_title
	if resource == null or balloon_scene == null:
		push_warning("SpeechAnchor: needs a dialogue resource and a balloon_scene.")
		return

	clear()

	var states: Array = extra_game_states.duplicate()
	states.append_array(extra)

	_current_balloon = balloon_scene.instantiate() as SpeechBalloon
	add_child(_current_balloon)
	_current_balloon.finished.connect(func(): speech_finished.emit())
	speech_started.emit()
	_current_balloon.start(resource, title, states)


## Removes the current balloon right away, if any.
func clear() -> void:
	if is_instance_valid(_current_balloon):
		_current_balloon.cancel()
	_current_balloon = null


func is_speaking() -> bool:
	return is_instance_valid(_current_balloon)
