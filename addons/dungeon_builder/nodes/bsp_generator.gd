extends Node2D

@export_category("dev_tool")
@export var cheat_toggle:=true:
	set(value):
		cheat_toggle=value
		_ready()
@export_category("properties")

@export
var size:Vector2

@export 
var min_room_size:Vector2

@export 
var max_room_size:Vector2




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
