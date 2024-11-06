extends Node2D

class_name door_based_tag_generator

@export
var source_rooms:Array[PackedScene]

var available_rooms:Array[Area2D]
var room_shapes:Dictionary

@export
var start_room:PackedScene

@export
var max_rooms:=10
var used_rooms:=0

var done = false;

var open_exits:Array[exit_node]

var last_room:=Area2D
@export
var show_cam:Camera2D;


func _ready() -> void:
	for scene in source_rooms:
		var room = scene.instantiate()
		if room is Area2D:
			available_rooms.append(room)
			var shapes:Array[Shape2D]
			for i in room.get_shape_owners():
				for x in range(room.shape_owner_get_shape_count(i)):
					shapes.push_back(room.shape_owner_get_shape(i,x).duplicate())
			room_shapes[room] = shapes
		else:
			print("Room is not an Area2D")

			
func generate() -> void:
	var room = available_rooms[0]
	var dup = room.duplicate()
	dup.position = Vector2(0,0)
	add_child(dup)
	
	for child in dup.get_children():
		if child is exit_node:
			open_exits.push_back(child)
			child.set_meta("parent", room)
			used_rooms+=1;
	await get_tree().create_timer(.5).timeout

func step_generation() -> bool:	
	if open_exits.size() == 0: 
		return true;
	
	var exit = open_exits.pick_random() as exit_node
	open_exits.erase(exit)
		
	var valid_rooms = get_rooms_by_tag(exit)

	if valid_rooms.desired_rooms.size() == 0 and valid_rooms.required_rooms.size() == 0:
		print("No desired rooms for exit")
		exit.queue_free()
		return false;
	

	var more_valid_rooms := await try_rooms(valid_rooms.desired_rooms, exit)
	
	if more_valid_rooms.size() == 0:
		more_valid_rooms = await try_rooms(valid_rooms.required_rooms, exit)
	else:
		print("Desired Rooms lost: " + str(valid_rooms.desired_rooms.size()-more_valid_rooms.size()))
		print("Desired rooms remaining: "  + str(more_valid_rooms.keys().size()))
	if more_valid_rooms.size() == 0:
		print("No required rooms fit exit")
		exit.queue_free()
		return false;
	else:
		print("Required Rooms lost: " + str(valid_rooms.required_rooms.size()-more_valid_rooms.size()))
		print("Required rooms remaining: "  + str(more_valid_rooms.keys().size()))

	var targ_room = more_valid_rooms.keys().pick_random() as Area2D
	var room = targ_room.duplicate(DUPLICATE_USE_INSTANTIATION)
	room.global_position=more_valid_rooms[targ_room]
	add_child(room)
	last_room=room
	used_rooms+=1;
	
	exit.connected=true;
	for child in room.get_children():
		if child is exit_node:
			if child.global_position == exit.global_position: 
				child.connected=true;
				continue;
			else:
				print (child.global_position - exit.global_position)
			open_exits.push_back(child)
			child.set_meta("parent", targ_room)
	return false;

func try_rooms(rooms:Array[Area2D], exit:exit_node) -> Dictionary:
	var to_return:Dictionary
	for room in rooms:
		
		var exits = get_opposing_exits(room, exit)
		if exits.size() == 0:
			continue
		var room_shape = room_shapes[room]
		
		for targ_exit in exits:
			var exit_shapes = room_shapes[exit.get_meta("parent")]
			var exit_offset = exit.position
			var new_offset = exit.global_position - targ_exit.position

			var valid= true;

			for shape in room_shape:
				var new_xform=Transform2D(0, new_offset)				
				if await exits_hit_others(room,Transform2D(0,exit.global_position),exit.get_parent(),[]):
					valid=false;
					break
				if await hits_others(shape,new_xform):
					valid=false
					break;
			if valid:
				to_return[room] = new_offset
	return to_return
				

func copy_nodes(target:Node, from:Area2D, at:Vector2) ->void:
	for node in from.get_children():
		if node is exit_node \
		or node is TileMapLayer or node is CollisionPolygon2D:
			continue;
			
		if node is Area2D or node is CollisionObject2D:
			var copy = node.duplicate();
			copy.global_position=node.global_position
			target.add_child(copy)

func copy_decorations_nodes(target:Node, from:Area2D, at:Vector2) ->void:
	for node in from.get_children():
		if node is exit_node \
		or node is TileMapLayer or node is CollisionPolygon2D:
			continue;
			
		if node is NinePatchRect:
			var copy = node.duplicate();
			copy.global_position=node.global_position
			target.add_child(copy)



func get_opposing_exits(node:Node2D, dir:exit_node)	-> Array[exit_node]:
	var ret:Array[exit_node]
	var nodes = get_exits(node)
	for child in nodes:
		if child.compare_direction(dir):
			ret.push_back(child)
				#for child in node.get_children():
		#if child is exit_node and child.compare_direction(dir):
			#ret.append(child)
			
	return ret;

func get_exits(node:Node2D)	-> Array[exit_node]:
	var ret:Array[exit_node]
	for child in node.get_children():
		if child is exit_node:
			ret.append(child)
	return ret;


class selected_rooms:
	var desired_rooms:Array[Area2D]=[]
	var required_rooms:Array[Area2D]=[]

func get_rooms_by_tag(exit:exit_node) -> selected_rooms:
	var rooms:=selected_rooms.new()

	for room in available_rooms:
		var tag_hosts = room.find_children("", "room_tags")
		if tag_hosts.size() == 0:
			continue
		if exit.matching_tag_sets == null:
			print(exit.get_meta("parent").name)
		for tset:Generation_Tag_Set in exit.matching_tag_sets.tags:
			var weight = 0
			var tags = tag_hosts[0].tags as Array[Generation_Tag]
			var valid = true
			for tag in tset.required_tags:
				if not tags.has(tag.tag):
					valid = false
					break
			for tag in tset.blacklist_tags:
				if tags.has(tag.tag):
					valid = false
					break
			if (get_exits(room).size() + used_rooms-1 )>= max_rooms:
				valid = false;
				break;

			for tag in tset.desired_tags:
				if tags.has(tag.tag):
					weight+=tag.weight
			if valid:
				for i in range(weight - tset.weight_threshold):
					rooms.desired_rooms.append(room)
				rooms.required_rooms.append(room)

	return rooms

func hits_others(shape:Shape2D, xform:Transform2D, exclude=[Node2D]):
	for child in get_children():
		if child is Area2D:
			if exclude.has(child):
				continue
			var area = child as Area2D;
			for i in child.get_shape_owners():
				for x in range(child.shape_owner_get_shape_count(i)):
					var child_shape = child.shape_owner_get_shape(i,x) as Shape2D;
					var contacts = shape.collide_and_get_contacts(xform, child.shape_owner_get_shape(i,x),Transform2D(0, child.global_transform.origin))
					if !contacts.is_empty():
						
						var rect1 := ColorRect.new()
						rect1.size=child.shape_owner_get_shape(i,x).get_rect().size
						rect1.position=child.global_transform.origin-child_shape.get_rect().size
						rect1.color=Color.BLUE
						
						
						var rect2 := ColorRect.new()
						rect2.size=shape.get_rect().size
						rect2.position=xform.origin
						rect2.color=Color.RED
						
						#add_child(rect1)
						#add_child(rect2)
						
						await get_tree().physics_frame
						
						return true;
	return false;
	
func exits_hit_others(room_to_test:Area2D,xform:Transform2D, room_to_ignore:Area2D, exits_to_exclude:Array[exit_node]) :
	var exits = get_exits(room_to_test);
	for exit in exits:
		if exit.connected:
			continue
		if exits_to_exclude.has(exit):
			continue;
		if await hits_others(exit.get_child(0).shape, Transform2D(0,xform.origin-exit.global_position), [room_to_ignore, room_to_test]):
			return true;
	return false;
			
func get_shapes(col_area:CollisionObject2D) -> Array[Shape2D]:
	var shapes:Array[Shape2D]
	for i in col_area.get_shape_owners():
		for x in col_area.shape_owner_get_shape_count(i) as int:
			shapes.push_back(col_area.shape_owner_get_shape(i,x))
	return shapes;
