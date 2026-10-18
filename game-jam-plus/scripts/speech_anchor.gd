class_name SpeechAnchor
extends Marker2D

signal speech_started
signal speech_finished

@export var balloon_scene: PackedScene   # drag SpeechBalloon.tscn here
@export var default_dialogue: DialogueResource
@export var default_title: String = "start"
## Nodes whose variables/functions the .dialogue file can use
## (for example the character itself).
@export var extra_game_states: Array[Node] = []

@export_group("Character")
## The name this character has in .dialogue files: the "Nathan" in "Nathan: Hi!".
@export var character_name: String = ""

@export_group("Pause")
## A line like "wait: 3" pauses the conversation for 3 seconds instead of
## showing a bubble. This is the word before the colon.
@export var pause_keyword: String = "wait"

@export_group("Chat")
## Also post each message to the chat window.
@export var post_to_chat: bool = true
## Nickname shown in the chat. Empty = use character_name.
@export var default_nickname: String = ""
## The chat to post to. Leave empty to find it automatically (FakeChat adds
## itself to the "fake_chat" group).
@export var chat: FakeChat

var _current_balloon: SpeechBalloon
var _run_id: int = 0
var _warned_no_chat: bool = false
var _warned_choices: bool = false
var _bbcode_regex: RegEx


func _ready() -> void:
	add_to_group("speech_anchors")  # lets other anchors find this character by name

func _exit_tree() -> void:
	clear()

## Starts a conversation from this character. Every line is shown by the
## character it belongs to (see character_name). If this character is already
## in a conversation, it is replaced.
##   say()                                  -> default dialogue and title
##   say("Thorgar")                         -> also sets this character's chat nickname
##   say("Thorgar", my_dialogue, "greeting") -> specific dialogue and title
func say(nickname: String = "", resource: DialogueResource = null, title: String = "") -> void:
	if resource == null:
		resource = default_dialogue
	if title.is_empty():
		title = default_title
	if not nickname.is_empty():
		default_nickname = nickname
	if resource == null or balloon_scene == null:
		push_warning("SpeechAnchor: needs a dialogue resource and a balloon_scene.")
		return

	clear()
	var states: Array = []
	states.append_array(extra_game_states)
	_run_conversation(resource, title, states, _run_id)


## Stops this character's conversation and removes its balloon right away.
func clear() -> void:
	_run_id += 1
	_cancel_balloon()


func is_speaking() -> bool:
	return is_instance_valid(_current_balloon)


## The name shown in the chat for this character.
func get_chat_name() -> String:
	return default_nickname if not default_nickname.is_empty() else character_name


## Shows one line above THIS character and waits until the balloon is gone.
## Called by the conversation that is running (usually from another anchor).
func speak_line(line: DialogueLine, chat_name: String = "") -> void:
	if balloon_scene == null:
		push_warning("SpeechAnchor '%s': no balloon_scene assigned." % character_name)
		return

	_cancel_balloon()
	var balloon: SpeechBalloon = balloon_scene.instantiate() as SpeechBalloon
	_current_balloon = balloon
	add_child(balloon)
	# Posts to the chat when the message appears (not while it's "typing").
	balloon.message_shown.connect(func(text: String): _post_to_chat(chat_name, text))
	balloon.play_line(line)
	await balloon.tree_exited


func _run_conversation(resource: DialogueResource, title: String, states: Array, run_id: int) -> void:
	speech_started.emit()
	var next_id: String = title

	while run_id == _run_id:
		var line: DialogueLine = await DialogueManager.get_next_dialogue_line(resource, next_id, states)
		if run_id != _run_id or line == null:
			break

		if _is_pause_line(line):
			# "wait: 3" -> nobody speaks, the conversation just waits.
			await _pause(_pause_seconds(line), run_id)
			if run_id != _run_id:
				return
		elif not line.text.is_empty():
			# Which character says this line?
			var target: SpeechAnchor = _find_anchor(line.character)
			var matched: bool = target != null
			if target == null:
				target = self  # unknown speaker: use the character that started it

			var chat_name: String = target.get_chat_name()
			if not matched and not line.character.is_empty():
				chat_name = line.character

			await target.speak_line(line, chat_name)
			if run_id != _run_id:
				return  # replaced by a newer conversation

		# Choices ("- option") can't be answered from a bubble, so stop here.
		if line.responses.size() > 0:
			if not _warned_choices:
				_warned_choices = true
				push_warning("SpeechAnchor: dialogue choices are not supported in speech bubbles; the conversation stops here.")
			break

		next_id = line.next_id
		if next_id.is_empty():
			break

	if run_id == _run_id:
		speech_finished.emit()


## True for lines like "wait: 3" (speaker = pause_keyword, text = a number of seconds).
func _is_pause_line(line: DialogueLine) -> bool:
	if pause_keyword.strip_edges().is_empty():
		return false
	return _names_match(line.character, pause_keyword) and _pause_text(line).is_valid_float()


func _pause_seconds(line: DialogueLine) -> float:
	return maxf(_pause_text(line).to_float(), 0.0)


## Accepts "3", "2.5" and also "3s".
func _pause_text(line: DialogueLine) -> String:
	return line.text.strip_edges().trim_suffix("s").strip_edges()


## Waits without freezing the game; stops early if the conversation is replaced.
func _pause(seconds: float, run_id: int) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds and run_id == _run_id:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


## Finds the anchor whose character_name matches the speaker of a line.
## Returns null if the line has no speaker or nobody matches.
func _find_anchor(speaker: String) -> SpeechAnchor:
	if speaker.strip_edges().is_empty():
		return null
	if _names_match(character_name, speaker):
		return self
	for node in get_tree().get_nodes_in_group("speech_anchors"):
		var anchor: SpeechAnchor = node as SpeechAnchor
		if anchor != null and _names_match(anchor.character_name, speaker):
			return anchor
	return null


func _names_match(a: String, b: String) -> bool:
	return a.strip_edges().to_lower() == b.strip_edges().to_lower()


func _cancel_balloon() -> void:
	if is_instance_valid(_current_balloon):
		_current_balloon.cancel()
	_current_balloon = null


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

	target.add_chat_line(nickname, _strip_bbcode(text), true)  # true = dialogue color


## Removes BBCode tags like [b] or [color=red] so they don't show as raw text in the chat.
func _strip_bbcode(text: String) -> String:
	if _bbcode_regex == null:
		_bbcode_regex = RegEx.new()
		_bbcode_regex.compile("\\[[^\\]]*\\]")
	return _bbcode_regex.sub(text, "", true).strip_edges()
