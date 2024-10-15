extends Node2D

@export
var available_rooms:Array[PackedScene]

@export
var max_rooms:=10
var used_rooms:=0

var done = false;


var open_exits:Array[exit_node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var room_scene := available_rooms.pick_random() as PackedScene;
    
    var scene = room_scene.instantiate();
    scene.position=Vector2(0,0)
    add_child(scene)
    
    for child in scene.get_children():
        if child is exit_node:
            open_exits.push_back(child)
            used_rooms+=1;
            


func step_generation():
    if open_exits.is_empty():
        done = true;
        return;

    var exit = open_exits.pick_random() as exit_node
    open_exits.erase(exit)
    
    var valid_rooms = await try_rooms(exit)
    
    var room =valid_rooms.pick_random()
    if room == null:
        exit.queue_free()
        used_rooms-=1;
        return;
    while room.global_position == exit.get_parent().global_position:
        room = valid_rooms.pick_random()
    add_child(room)
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
    
    
    
func try_rooms(exit:exit_node) -> Array[Node2D]:
    var ret_val:Array[Node2D]
    for room_scene in available_rooms:
        
        var parent_room = exit.get_parent();
        
        var room = room_scene.instantiate() as Area2D
        add_child(room)
        
        var exits = get_exits(room)
        if exits.size() > max_rooms-used_rooms:
            print("Too many doors.")
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass


func _unhandled_input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        step_generation()
