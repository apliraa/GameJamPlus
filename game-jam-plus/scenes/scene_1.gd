extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventManager.set_events.connect(add_events)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func add_events(event: PackedScene) -> void:
	print("aaaaaaa")
