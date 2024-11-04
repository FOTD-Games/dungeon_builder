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
	cast.target_position=Vector2(0,0)
	
	
	add_child(cast)
	

	var room = room_scene.instantiate();
	add_child(room)
	room.position = Vector2(0,0);
	for child in room.get_children():
		if child is exit_node:
			open_exits.append(child)
			used_rooms+=1
	

func step_generation()->bool:
	if open_exits.size()==0:
		return false;
	var exit:=open_exits.pop_at(randi_range(0,open_exits.size()-1)) as exit_node	
	var rooms:=get_possible_rooms(exit)
	
	if rooms.keys().size()==0:
		used_rooms-=1;
		exit.queue_free()
		return true
	
	var selected = rooms.keys().pick_random()
	var room = rooms[selected]
	rooms[selected]=null;
	
	for key in rooms.keys():
		if rooms[key] != null and rooms[key] != room:
			rooms[key].queue_free()
	
	add_child(room)
	room.global_position=exit.global_position -selected.position

	
	for child in room.get_children():
		if child is exit_node and child !=selected:
			open_exits.append(child)
			used_rooms+=1
	return true;
	
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
	var shape:= room.get_node("placement_hull")  as CollisionPolygon2D
	
	var copy_shape := ConvexPolygonShape2D.new()
	copy_shape.set_point_cloud(shape.polygon)
	
	cast.shape = copy_shape
	cast.clear_exceptions()
	cast.add_exception(room)
	cast.collision_mask=room.collision_mask
	
	for targ_exit in room_exits:
		room.global_position=exit.global_position-targ_exit.position
		cast.global_position=room.global_position;
		cast.force_shapecast_update()		
		if !check_collision(shape):
			results[targ_exit]=room;
		else:
			pass
	return results;

func check_collision(room:CollisionPolygon2D) ->bool:
	if cast.is_colliding():
		for col in cast.collision_result:
			if col.collider is exit_node:
				continue
			else:
				var col_obj = col.collider as CollisionObject2D
				var shape = col_obj.shape_owner_get_shape(col_obj.shape_find_owner(col.shape), col.shape)
				var offset_shape =shape.points * col_obj.transform
				var offset_room = room.polygon * room.transform
				
				var data1 = Geometry2D.clip_polygons(offset_room, offset_shape)
				var data2 = Geometry2D.clip_polygons(offset_shape, offset_room)
				if data1.size() == 0 and data2.size() == 0:
					continue
				if data2.size() > 0 and data1.size() > 0:
					
					if data2[0][0].x - data2[0][1].x != 0:
						return true
					if data2[0][0].y - data2[0][2].y != 0:
						return true						
					continue
				if data2.size() == 0:
					continue;
				
				return true;
		pass
	else:
		if cast.position== room.position:
			return true;
		return false
	if cast.position== room.position:
		return true;
	return false;

func get_exits(room:Node2D) ->Array[exit_node]:
	var exits:Array[exit_node]
	for node in room.get_children():
		if node is exit_node:
			var exit:=node as exit_node
			exits.append(exit)
	return exits;
	 	
func _unhandled_input(event: InputEvent) -> void:
	#if Input.is_action_just_pressed("ui_accept"):
		#step_generation()
	if Input.is_action_just_pressed("ui_up"):
		check_collision(get_child(2).get_node("placement_hull"))
#s	
		
func do_spawns(target_node:Node2D)->void:
	for child in get_children():
			if child is Area2D:
				var room: = child as Area2D
				for possible_spawn in room.get_children():
					if possible_spawn is spawner:
						var spawn := possible_spawn as spawner
						spawn.spawn(target_node)

#This is not going to work long term. Work around?  Register scenes to be copied?  Eww, but... meh?
func copy_nodes(target:Node) ->void:
	for child in get_children():
			if child is Area2D:
				var room: = child as Area2D
				for node in room.get_children():
					if node is spawner or node is exit_node \
					or node is TileMapLayer or node is CollisionShape2D:
						continue;
					
					if !(node is Node2D):
						copy_children_to(target, node)
						continue
					
					var copy = node.duplicate();
					target.add_child(copy)
					
					copy.global_position=node.global_position

func copy_children_to(to:Node, from:Node) -> void:
	for node in from.get_children():
		if node is spawner or node is exit_node or !(node is Node2D):
						continue;
		var copy := node.duplicate();		
		to.add_child(copy)
		copy.global_position=node.global_position
