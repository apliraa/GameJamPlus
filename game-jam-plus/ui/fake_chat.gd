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
## A message can't repeat until this many other messages have been posted.
## Automatically capped so there is always at least one message to pick.
@export var no_repeat_count: int = 5

@export_group("Online Users")
## How many players are "online". Only this many usernames send messages.
## Change it at runtime (e.g. chat.online_count = 12) and the group updates:
## increasing it logs random offline users in, decreasing it logs random users out,
## everyone else stays online. Capped to the size of the usernames list.
@export var online_count: int = 5:
	set(value):
		online_count = maxi(value, 0)
		_refresh_online_users()

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
var _recent_messages: Array = []
var _next_hue: float = randf()
var _online_users: Array = []   # the current subset of usernames that can chat
var _timer: Timer


func _ready() -> void:
	randomize()  # Godot 4 auto-randomizes, kept for clarity.
	_refresh_online_users()
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
	if _online_users.is_empty():
		return  # nobody online, nobody talks

	var user: String = _online_users.pick_random()
	add_chat_line(user, _pick_message())


## Call this whenever the number of online players changes.
## Default: keeps current chatters and only logs the difference in/out.
## rebuild = true: throws the group away and picks a brand new random set.
func build_online_group(new_count: int, rebuild: bool = false) -> void:
	if rebuild:
		_online_users.clear()
	online_count = new_count  # the setter calls _refresh_online_users()


## Adjusts the online group to match online_count while keeping existing
## online users stable (only the difference logs in/out).
func _refresh_online_users() -> void:
	# Drop anyone no longer in the usernames list (e.g. list edited).
	_online_users = _online_users.filter(func(u): return usernames.has(u))

	var target: int = clampi(online_count, 0, usernames.size())

	# Too many online: log out random users.
	while _online_users.size() > target:
		_online_users.remove_at(randi() % _online_users.size())

	# Too few online: log in random users that are currently offline.
	if _online_users.size() < target:
		var offline: Array = usernames.filter(func(u): return not _online_users.has(u))
		offline.shuffle()
		while _online_users.size() < target and not offline.is_empty():
			_online_users.append(offline.pop_back())

	# Everyone in the group gets their color now (existing colors are kept).
	for u in _online_users:
		_get_name_color(u)


## Picks a random message that wasn't used in the last no_repeat_count posts.
func _pick_message() -> String:
	var available: Array = chat_messages.filter(func(m): return not _recent_messages.has(m))
	if available.is_empty():
		available = chat_messages  # safety net, e.g. very short message list

	var picked: String = available.pick_random()

	_recent_messages.append(picked)
	var window: int = mini(no_repeat_count, chat_messages.size() - 1)
	while _recent_messages.size() > maxi(window, 0):
		_recent_messages.pop_front()

	return picked


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
		# Golden-ratio hue stepping spreads colors apart, so users in the
		# same group look distinct instead of randomly clashing.
		_next_hue = fposmod(_next_hue + 0.618034, 1.0)
		_name_colors[user] = Color.from_hsv(_next_hue, 0.6, 1.0)
	return _name_colors[user]


func _scroll_to_bottom() -> void:
	# Wait one frame so the container has resized with the new label.
	await get_tree().process_frame
	var bar := scroll_container.get_v_scroll_bar()
	scroll_container.scroll_vertical = int(bar.max_value)
