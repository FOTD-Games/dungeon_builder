extends Node


@onready var dbtg: door_based_tag_generator = %door_based_tag_generator


func _ready() -> void:
	dbtg.generate()  #starts the actual generation. 
	
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		dbtg.step_generation()
		get_tree().create_tween().tween_property($MapCamera2D,"position", dbtg.last_room.global_position,.5)
