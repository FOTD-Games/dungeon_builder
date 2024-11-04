extends Node
@export
var available_rooms:Array[PackedScene]

@export
var max_rooms:=10
var used_rooms:=0

var done = false;


var open_exits:Array[exit_node]

var last_room:=Area2D

@export
var show_cam:Camera2D;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for scene in available_rooms:
		var room = scene.instantiate()
			
func generate() -> void:
	pass

func step_generation() -> void:
	pass
