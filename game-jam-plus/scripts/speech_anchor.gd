class_name SpeechAnchor
extends Marker2D
## Put one of these on every character (child of the player/NPC node) and move
## it to just above the character's head. Call say() to make that character
## speak in its own balloon. Each character has its own anchor, so many
## characters can talk at the same time.
##
## Like an MMO, each message is also posted to the chat window (FakeChat) under
## the character's nickname, at the moment the message appears in the bubble.

signal speech_started
signal speech_finished

@export var balloon_scene: PackedScene   # drag SpeechBalloon.tscn here
@export var default_dialogue: DialogueResource
@export var default_title: String = "start"
## Nodes whose variables/functions the .dialogue file can use for this character
## (for example the character itself).
@export var extra_game_states: Array[Node] = []

@export_group("Chat")
## Also post each message to the chat window.
@export var post_to_chat: bool = true
## Nickname used in the chat when say() isn't given one.
@export var default_nickname: String = ""
## The chat to post to. Leave empty to find it automatically (FakeChat adds
## itself to the "fake_chat" group).
@export var chat: FakeChat

var _current_balloon: SpeechBalloon
var _warned_no_chat: bool = false
var _bbcode_regex: RegEx


## Makes this character speak. If it is already speaking, the old balloon is
## replaced. Uses the default nickname/dialogue/title when none are given.
##   say()                                  -> everything default
##   say("Thorgar")                         -> default dialogue, nickname Thorgar
##   say("Thorgar", my_dialogue, "greeting") -> specific dialogue and title
func say(nickname: String = "", resource: DialogueResource = null, title: String = "") -> void:
	if resource == null:
		resource = default_dialogue
	if title.is_empty():
		title = default_title
	if nickname.is_empty():
		nickname = default_nickname
	if resource == null or balloon_scene == null:
		push_warning("SpeechAnchor: needs a dialogue resource and a balloon_scene.")
		return

	clear()

	var states: Array = extra_game_states.duplicate()

	_current_balloon = balloon_scene.instantiate() as SpeechBalloon
	add_child(_current_balloon)
	_current_balloon.finished.connect(func(): speech_finished.emit())
	# Posts to the chat each time a message appears in the bubble (not while it's "typing").
	_current_balloon.message_shown.connect(func(text: String): _post_to_chat(nickname, text))
	speech_started.emit()
	_current_balloon.start(resource, title, states)


## Removes the current balloon right away, if any.
func clear() -> void:
	if is_instance_valid(_current_balloon):
		_current_balloon.cancel()
	_current_balloon = null


func is_speaking() -> bool:
	return is_instance_valid(_current_balloon)


func _post_to_chat(nickname: String, text: String) -> void:
	if not post_to_chat or nickname.is_empty():
		return

	var target: FakeChat = chat
	if target == null:
		target = get_tree().get_first_node_in_group("fake_chat") as FakeChat
	if target == null:
		if not _warned_no_chat:
			_warned_no_chat = true
			push_warning("SpeechAnchor: no FakeChat found to post to (assign 'chat' or make sure FakeChat is in the scene).")
		return

	target.add_chat_line(nickname, _strip_bbcode(text))


## Removes BBCode tags like [b] or [color=red] so they don't show as raw text in the chat.
func _strip_bbcode(text: String) -> String:
	if _bbcode_regex == null:
		_bbcode_regex = RegEx.new()
		_bbcode_regex.compile("\\[[^\\]]*\\]")
	return _bbcode_regex.sub(text, "", true).strip_edges()
