class_name SpeechBalloon
extends PanelContainer
## A per-character speech bubble driven by Dialogue Manager (Godot 4.x).
##
## Every character gets its own instance of this scene, so many players can
## talk at once. It does not use DialogueManager.show_dialogue_balloon(); it
## asks Dialogue Manager for each line itself and shows it in a plain
## RichTextLabel.
##
## For each line it first shows an animated "typing" bubble (. .. ...) whose
## length depends on the message, then swaps in the full message, like a live
## MMO chat. No typewriter effect.
##
## Scene: PanelContainer (this script) -> RichTextLabel.
## Style the look (font, panel background, margins) in the scene itself.
## Responses/choices are not supported here (MMO chat bubbles don't have them).

## Emitted after the last line has been shown and the balloon has faded out.
signal finished
## Emitted each time a message becomes visible (after the "..." typing bubble).
signal message_shown(text: String)

@export_group("Position")
## Offset from the anchor. The balloon is centered horizontally above it.
@export var offset: Vector2 = Vector2(0, -8)
## The balloon follows the character while the "..." typing bubble shows.
## If this is on, the message stays at the spot where it appeared, even if the
## character walks away. If off, the message keeps following the character.
@export var pin_message_in_place: bool = true

@export_group("Size")
## Shrink the balloon to fit short messages instead of using a fixed width.
@export var fit_width_to_text: bool = true
## Maximum balloon width; longer text wraps onto more lines.
@export var max_width: float = 280.0

@export_group("Typing Indicator")
## Show the animated "..." bubble before each message.
@export var show_typing_indicator: bool = true
## How long the dots show per character of the upcoming message...
@export var typing_seconds_per_character: float = 0.05
## ...clamped between these two values.
@export var typing_min_seconds: float = 0.8
@export var typing_max_seconds: float = 3.0
## Time between dot changes (. -> .. -> ...).
@export var dots_interval: float = 0.35

@export_group("Message Timing")
## Time a message stays visible after it appears...
@export var base_display_seconds: float = 1.5
## ...plus this much per character. A time given in the .dialogue file
## (e.g. [#time=3]) overrides both.
@export var seconds_per_character: float = 0.05
@export var fade_out_seconds: float = 0.3

@onready var dialogue_label: RichTextLabel = $DialogueLabel

var _cancelled: bool = false
var _is_pinned: bool = false
var _pinned_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	dialogue_label.bbcode_enabled = true
	resized.connect(_reposition)
	_reposition()


## Runs the dialogue from `title`, line by line. Not meant to be awaited by the
## caller; listen to the `finished` signal instead.
func start(resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	modulate.a = 0.0  # stay invisible until the first line is ready

	var next_id: String = title
	while not _cancelled:
		var line: DialogueLine = await DialogueManager.get_next_dialogue_line(resource, next_id, extra_game_states)
		if _cancelled or line == null:
			break
		await _show_line(line)
		if _cancelled:
			break
		next_id = line.next_id
		if next_id.is_empty():
			break

	if _cancelled:
		queue_free()
		return

	await _fade_out()
	if _cancelled:
		queue_free()
		return
	finished.emit()
	queue_free()


## Immediately stops this balloon (e.g. the character started a new dialogue).
## It frees itself on its next frame; `finished` is not emitted.
func cancel() -> void:
	_cancelled = true
	hide()


func _show_line(line: DialogueLine) -> void:
	_unpin()  # the typing bubble follows the character
	if show_typing_indicator:
		await _show_typing_dots(line)
		if _cancelled:
			return

	# The message stays where the character is right now.
	_pin_in_place()

	# Swap in the real message.
	modulate.a = 0.0  # invisible while we measure the text
	dialogue_label.visible_characters = -1
	dialogue_label.text = line.text

	if fit_width_to_text:
		await _fit_width()
		if _cancelled:
			return

	modulate.a = 1.0
	if _cancelled:
		return
	message_shown.emit(line.text)
	await _wait(_display_time(line))


## Animated "..." bubble. The full "..." is always laid out, and only the number
## of visible dots changes, so the bubble doesn't change size while animating.
func _show_typing_dots(line: DialogueLine) -> void:
	var duration: float = clampf(
		line.text.length() * typing_seconds_per_character,
		typing_min_seconds,
		typing_max_seconds
	)

	modulate.a = 0.0
	dialogue_label.text = "..."
	dialogue_label.visible_characters = -1
	if fit_width_to_text:
		await _fit_width()
		if _cancelled:
			return

	var dots: int = 1
	dialogue_label.visible_characters = dots
	modulate.a = 1.0

	var elapsed: float = 0.0
	var step_timer: float = 0.0
	while elapsed < duration and not _cancelled:
		await get_tree().process_frame
		var delta: float = get_process_delta_time()
		elapsed += delta
		step_timer += delta
		if step_timer >= dots_interval:
			step_timer -= dots_interval
			dots = dots % 3 + 1
			dialogue_label.visible_characters = dots

	dialogue_label.visible_characters = -1


func _fit_width() -> void:
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	dialogue_label.custom_minimum_size = Vector2.ZERO
	size = Vector2.ZERO
	await get_tree().process_frame
	if _cancelled:
		return

	var width: float = minf(dialogue_label.get_content_width() + 2.0, max_width)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size.x = width
	size = Vector2.ZERO
	await get_tree().process_frame


func _display_time(line: DialogueLine) -> float:
	var time_tag: String = str(line.time)
	if time_tag.is_valid_float():
		return time_tag.to_float()
	return base_display_seconds + line.text.length() * seconds_per_character


func _wait(seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds and not _cancelled:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _fade_out() -> void:
	if fade_out_seconds <= 0.0:
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_out_seconds)
	await tween.finished


## Fixes the balloon at the anchor's current world position, so it stops
## following the character.
func _pin_in_place() -> void:
	if not pin_message_in_place or _is_pinned:
		return
	var anchor: Node2D = get_parent() as Node2D
	if anchor == null:
		return
	_pinned_global_position = anchor.global_position
	_is_pinned = true
	top_level = true  # ignore the parent's movement/scale from now on
	_reposition()


## Makes the balloon follow the character again (used for the typing bubble).
func _unpin() -> void:
	if not _is_pinned:
		return
	_is_pinned = false
	top_level = false
	_reposition()


func _reposition() -> void:
	# Bottom-center of the balloon sits on the anchor (plus offset).
	var local_offset: Vector2 = Vector2(-size.x * 0.5, -size.y) + offset
	if _is_pinned:
		global_position = _pinned_global_position + local_offset
	else:
		position = local_offset
