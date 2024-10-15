@tool

extends Node
class_name spawner

var col_area:CollisionShape2D

@export 
var to_spawn:Array[spawn_chance]

@export
var spawn_size:Vector2:
	set(value):
		spawn_size=value
		if col_area != null:
			col_area.shape.size=spawn_size
	

func _process(delta: float) -> void:
	if col_area == null:
		setup()
	
		
func setup():
	col_area = CollisionShape2D.new()
	var rect =RectangleShape2D.new()
	col_area.shape=rect;
	rect.size=spawn_size;
	add_child(col_area)

func _ready() -> void:
	setup()
		
#spawn will be called after the rect is positioned over the world, so we can get away with just
#using our global_position.
func spawn(parent:Node2D):
	
	#Fuck off, it's an alpha. :P
	var spawned := to_spawn.pick_random() as spawn_chance
	
	var new_scene = spawned.scene.instantiate() as Node2D
	
	var rand_pos = col_area.global_position + Vector2(randf_range(0,spawn_size.x), randf_range(0,spawn_size.y))
	
	new_scene.position= rand_pos
	#if new_scene is Entity:
		#ECS.add_component(new_scene) 
	# some sort of hookable event here.  A signal. duh.
	
	parent.add_child(new_scene)
	
