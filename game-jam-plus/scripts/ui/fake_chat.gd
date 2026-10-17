extends Control
## Fake MMO chat simulator (Godot 4.x).
##
## Scene setup:
##   FakeChat (Control, this script attached, set to Full Rect)
##   └── ScrollContainer            (assign to scroll_container)
##       └── VBoxContainer          (assign to chat_container)
##           (size_flags_horizontal = Expand + Fill on both)
##
## Unity analogy: this is a MonoBehaviour. _ready() = Start(),
## Timer = a coroutine with WaitForSeconds, label.instantiate = Instantiate().

@export var scroll_container: ScrollContainer
@export var chat_container: VBoxContainer
@export var chat_label_scene: PackedScene   # drag ChatLabel.tscn here (your "prefab")

@export_group("Timing")
@export var min_delay: float = 0.6
@export var max_delay: float = 3.0

@export_group("Chat")
@export var max_messages: int = 50

@export_group("Content")
@export var usernames: Array[String] = [
	"Thorgar", "Lunaria", "xXSlayerXx", "HealzPlz", "NoobMaster69",
	"Elaria", "Grimbold", "Sir_Lagsalot", "DarkMage", "FarmingBot3000"
]
@export var chat_messages: Array[String] = [
	"LFG dungeon, need tank and healer!",
	"WTS Iron Sword 500g",
	"anyone know where the blacksmith is?",
	"lol that boss one-shot me",
	"guild recruiting, lvl 20+, DM me",
	"server lag again...",
	"gg everyone",
	"WTB health potions, paying well",
	"who wants to trade?",
	"brb afk 5 min",
	"help! I'm stuck in the wall",
	"just got a legendary drop!!!",
	"is the event still going?",
	"LF1M for quest, 2 min",
	"nice armor bro",
]

# Optional: one color per username so chat looks more alive.
var _name_colors: Dictionary = {}
var _timer: Timer


func _ready() -> void:
	randomize()  # Godot 4 auto-randomizes, kept for clarity.
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_schedule_next()


func _schedule_next() -> void:
	_timer.start(randf_range(min_delay, max_delay))


func _on_timer_timeout() -> void:
	post_random_message()
	_schedule_next()


## Call this manually too if you want (e.g. from a button).
func post_random_message() -> void:
	if usernames.is_empty() or chat_messages.is_empty():
		push_warning("FakeChat: usernames or chat_messages list is empty.")
		return

	var user: String = usernames.pick_random()
	var text: String = chat_messages.pick_random()
	add_chat_line(user, text)


func add_chat_line(user: String, text: String) -> void:
	# Unity: Instantiate(prefab, parent)
	var label: ChatLabel = chat_label_scene.instantiate()
	chat_container.add_child(label)
	label.setup(user, text, _get_name_color(user))

	# Remove oldest messages (Unity: Destroy(...)) to avoid infinite growth.
	while chat_container.get_child_count() > max_messages:
		var oldest := chat_container.get_child(0)
		chat_container.remove_child(oldest)
		oldest.queue_free()

	_scroll_to_bottom()


func _get_name_color(user: String) -> Color:
	if not _name_colors.has(user):
		_name_colors[user] = Color.from_hsv(randf(), 0.6, 1.0)
	return _name_colors[user]


func _scroll_to_bottom() -> void:
	# Wait one frame so the container has resized with the new label.
	await get_tree().process_frame
	var bar := scroll_container.get_v_scroll_bar()
	scroll_container.scroll_vertical = int(bar.max_value)
