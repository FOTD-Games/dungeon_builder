extends Node2D

class_name door_based_generator

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
	pass
			
func generate() -> void:
	var room_scene := available_rooms[0]as PackedScene;
	
	var scene = room_scene.instantiate();
	scene.position=Vector2i(0,0)
	add_child(scene)
	
	for child in scene.get_children():
		if child is exit_node:
			open_exits.push_back(child)
			used_rooms+=1;

func step_generation() -> bool:
	if open_exits.is_empty():
		return true;

	var exit = open_exits.pick_random() as exit_node
	var tween = create_tween();
	tween.tween_property(show_cam,"position",exit.global_position,.25)
	await tween.finished		
	
	open_exits.erase(exit)
	
	var valid_rooms = await try_rooms(exit)
	
	var room =valid_rooms.pick_random()
	if room == null:
		exit.queue_free()
		used_rooms-=1;
		return false;
	while room.global_position == exit.get_parent().global_position:
		room = valid_rooms.pick_random()
	add_child(room)
	last_room=room;
	var new_exits = get_exits(room)
	
	#Check to make sure we didn't close off any new exits.
	for targ_exit in open_exits:
		if room.overlaps_body(targ_exit):
			print("Hey now.")
			
	
	
	for new_exit in new_exits:
		if new_exit.global_position== exit.global_position:
			continue
		open_exits.push_back(new_exit)
		used_rooms+=1;
	valid_rooms.clear()
	
	return false
	
	
func try_rooms(exit:exit_node) -> Array[Node2D]:
	var ret_val:Array[Node2D]
	for room_scene in available_rooms:
		
		var parent_room = exit.get_parent();
		
		var room = room_scene.instantiate() as Area2D
		add_child(room)
		
		var exits = get_exits(room)
		if exits.size() > max_rooms-used_rooms:
			# print("Too many doors.")
			room.queue_free()
			continue;
		for test_exit in exits:
			if test_exit == null:
				continue;
			room.position = exit.global_position-test_exit.position
			await get_tree().physics_frame
			await get_tree().physics_frame
			await get_tree().process_frame
			if room.has_overlapping_areas():
				
				var shape1 = room.shape_owner_get_shape(0,0)
				
				if _process_collisions(shape1, room.get_global_transform(), room.get_overlapping_areas()):
					ret_val.push_back(dup(room_scene,room))                
			else:
				ret_val.push_back(dup(room_scene,room))
		room.queue_free()
		await get_tree().process_frame
	return ret_val


#False means don't add.
func _process_collisions(room_shape:Shape2D, room_transform:Transform2D,  overlaps:Array)->bool:
	
	for overlap in overlaps:
		var shape = overlap.shape_owner_get_shape(0,0);
		
		var extents = room_shape.collide_and_get_contacts(room_transform, shape, overlap.global_transform)
		
		if extents.size() > 0:
			return false;
		
	return true;

func dup(scene:PackedScene, instance:Node2D)->Node2D:
	var dup = scene.instantiate() as Node2D
	dup.transform= instance.transform
	return dup;
	
func get_exits(node:Node2D)	-> Array[exit_node]:
	var ret:Array[exit_node]
	for child in node.get_children():
		if child is exit_node:
			ret.push_back(child)
	return ret;

func copy_nodes(target:Node, from:Area2D, at:Vector2) ->void:
	for node in from.get_children():
		if node is spawner or node is exit_node \
		or node is TileMapLayer or node is CollisionPolygon2D:
			continue;
			
		if node is Area2D or node is CollisionObject2D:
			var copy = node.duplicate();
			copy.global_position=node.global_position
			target.add_child(copy)
		#if node is floor_decoration or node is wall_decoration:
			#var copy = node.duplicate();
			#copy.global_position=node.global_position
			#target.get_parent().get_node("decorations").add_child(copy)

func copy_decorations_nodes(target:Node, from:Area2D, at:Vector2) ->void:
	for node in from.get_children():
		if node is spawner or node is exit_node \
		or node is TileMapLayer or node is CollisionPolygon2D:
			continue;
			
		if node is NinePatchRect:
			var copy = node.duplicate();
			copy.global_position=node.global_position
			target.add_child(copy)

func copy_children_to(to:Node, from:Node) -> void:
	for node in from.get_children():
		if node is spawner or node is exit_node or !(node is Node2D):
						continue;
		var copy := node.duplicate();		
		to.add_child(copy)
		copy.global_position=node.global_position
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		step_generation()
		
		
