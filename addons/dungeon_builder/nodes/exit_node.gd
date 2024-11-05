@tool
extends Area2D

class_name exit_node

var col_area:CollisionShape2D

var texture_rect: TextureRect

@export
var size:=Vector2(32,32)

enum directions {LEFT, RIGHT, UP, DOWN}
var dirmap :=[Vector2.LEFT, Vector2.RIGHT,Vector2.UP,Vector2.DOWN]

@export
var direction:directions
@export
var door:bool=false

var connected:=false

var atlas := preload("res://addons/dungeon_builder/nodes/exit_atlas.tres") as AtlasTexture

@export
var matching_tag_sets:Exit_Node_Want_Tag
	
func setup() ->void:
	if get_child_count() == 0:
		texture_rect=TextureRect.new()
		col_area = CollisionShape2D.new()		
		add_child(col_area)
		col_area.owner= get_tree().edited_scene_root
		add_child(texture_rect)
		texture_rect.owner= get_tree().edited_scene_root
		
		
		texture_rect.texture=atlas
		texture_rect.size=size
		texture_rect.position-=size/2
		atlas.region.size=Vector2(16,16)
		
		atlas.region.position=Vector2(16,0)


func get_direction() ->Vector2:
	return dirmap[direction]

func _process(delta: float) -> void:
		setup()

func _physics_process(delta: float) -> void:
		if door:
			atlas.region.position=Vector2(0,0)
		else:
			atlas.region.position=Vector2(16,0)

func compare_direction(other:exit_node) ->bool:
	match(direction):
		directions.LEFT:
			if other.direction == directions.RIGHT:
				return true
		directions.RIGHT:
			if other.direction == directions.LEFT:
				return true
		directions.UP:
			if other.direction == directions.DOWN:
				return true
		directions.DOWN:
			if other.direction == directions.UP:
				return true
	return false
