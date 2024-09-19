extends Node2D

class_name generator

@export
var available_rooms:Array[PackedScene]

@export
var max_rooms:=10
var used_rooms:=0


var open_exits:Array[exit_node]

var cast:ShapeCast2D


func _ready() -> void:
	var room_scene := available_rooms.pick_random() as PackedScene;

	cast = ShapeCast2D.new()
	cast.shape = RectangleShape2D.new()
	cast.collide_with_areas=true
	#cast.position= Vector2(-100000,-100000)
	cast.target_position=Vector2(0,0)
	
	
	add_child(cast)
	

	var room = room_scene.instantiate();
	add_child(room)
	room.position = Vector2(0,0);
	for child in room.get_children():
		if child is exit_node:
			open_exits.append(child)
			used_rooms+=1
	

func step_generation()->void:
	var exit:=open_exits.pop_at(randi_range(0,open_exits.size()-1)) as exit_node	
	var rooms:=get_possible_rooms(exit)
	
	if rooms.keys().size()==0:
		print("nope")
		used_rooms-=1;
		exit.queue_free()
		return
	
	var selected = rooms.keys().pick_random()
	var room = rooms[selected]
	rooms[selected]=null;
	
	for key in rooms.keys():
		if rooms[key] != null:
			rooms[key].queue_free()
	
	add_child(room)
	room.global_position=exit.global_position -selected.position

	
	for child in room.get_children():
		if child is exit_node and child !=selected:
			open_exits.append(child)
			used_rooms+=1

	
func get_possible_rooms(exit:exit_node)->Dictionary: #Convert this to a specific node later?
	
	var results: = {}
	for scene in available_rooms:
		var room = scene.instantiate()
		var exits = get_exits(room)
		if exits.size()-1 + used_rooms > max_rooms:
			print ("too many")
			continue
		add_child(room)
		var data =  test_room(room, exit)
		for key in data.keys():
			results[key]=data[key]
		remove_child(room)
	return results

func test_room(room:Node2D, exit:exit_node) -> Dictionary:

	var results = {}
	
	var room_exits = get_exits(room)
	var shape:= room.get_node("placement_hull") 
	cast.shape = shape.shape
	cast.clear_exceptions()
	cast.add_exception(room)
	cast.collision_mask=room.collision_mask
	
	for targ_exit in room_exits:
		room.global_position=exit.global_position-targ_exit.position
		cast.global_position=room.global_position;
		cast.force_shapecast_update()
		if !check_collision():
			results[targ_exit]=room;
		else:
			#print("booo")
			pass
	cast.position= Vector2(-50000,-50000)
	return results;

func check_collision() ->bool:
	if cast.is_colliding():
		for col in cast.collision_result:
			if col.collider is exit_node:
				continue
			else:
				return true;
		pass
	else:
		return false
	return false;

func get_exits(room:Node2D) ->Array[exit_node]:
	var exits:Array[exit_node]
	for node in room.get_children():
		if node is exit_node:
			var exit:=node as exit_node
			exits.append(exit)
	return exits;
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		step_generation()
