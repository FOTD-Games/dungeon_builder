@tool
extends Area2D

class_name exit_node

var col_area:CollisionShape2D

var texture_rect: TextureRect
var arrow_texture: TextureRect

@export
var size:=Vector2(32,32)

enum directions {LEFT, RIGHT, UP, DOWN}

var dirmap :=[Vector2.LEFT, Vector2.RIGHT,Vector2.UP,Vector2.DOWN]

@export
var direction:directions:
	set(value):
		direction=value;
		dirty=true;

@export
var door:bool=false:
	set(value):
		door=value;
		dirty=true

var dirty:bool = false

var connected:=false

var atlas := preload("res://addons/dungeon_builder/nodes/exit_atlas.tres") as AtlasTexture

@export
var matching_tag_sets:Exit_Node_Want_Tag

func _init() -> void:
	setup()
	
func setup() ->void:
	if get_child_count() == 0:
		texture_rect=TextureRect.new()
		col_area = CollisionShape2D.new()		
		arrow_texture=TextureRect.new()
		
		add_child(col_area)
		add_child(texture_rect)
		add_child(arrow_texture)
				
		col_area.shape=RectangleShape2D.new()
		col_area.shape.set_size(size)
		col_area.visible=false
		
		dirty=true		

func get_direction() ->Vector2:
	return dirmap[direction]

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		setup()
	if dirty:
		if arrow_texture == null:
			for child in get_children():
				child.queue_free()
				remove_child(child)
			setup()
			
		arrow_texture.texture=atlas.duplicate()
		arrow_texture.size=size
		arrow_texture.position=-size/2
		arrow_texture.texture.region.size=Vector2(16,16)
		arrow_texture.texture.region.position=Vector2(32,0)
		arrow_texture.pivot_offset = size/2
		arrow_texture.self_modulate.a=160
		
		texture_rect.texture=atlas.duplicate()
		texture_rect.size=size
		texture_rect.position=-size/2
		texture_rect.texture.region.size=Vector2(16,16)
		texture_rect.texture.region.position=Vector2(16,0)
		
		dirty=false;

func _physics_process(delta: float) -> void:
	if texture_rect == null:
		dirty=true
	if dirty:
		return;
	if door:
		texture_rect.texture.region.position=Vector2(0,0)
	else:
		texture_rect.texture.region.position=Vector2(16,0)

	match(direction):
		directions.LEFT:
			arrow_texture.rotation=0
		directions.RIGHT:
			arrow_texture.rotation=PI
		directions.UP:
			arrow_texture.rotation=PI/2
		directions.DOWN:
			arrow_texture.rotation=PI+PI/2
		

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
