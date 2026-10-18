class_name ChatDay
extends Resource

@export var day: int = 1
## How many players are online on this day. -1 = don't set it, use the
## default online_count from FakeChat. 0 = nobody is online.
@export var online_players: int = -1
@export var messages: Array[String] = []
