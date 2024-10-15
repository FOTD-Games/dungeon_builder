@tool
extends Area2D

class_name exit_node

var col_area:CollisionShape2D

var click_area: RectangleShape2D
var texture_rect: TextureRect

@export
var size:=Vector2(32,32)



var connected:=false


	
	
func setup() ->void:
	if click_area == null:
		click_area= RectangleShape2D.new()
		texture_rect=TextureRect.new()
		col_area = CollisionShape2D.new()
		click_area.size=size
		col_area.shape=click_area
		
		add_child(col_area)
		add_child(texture_rect)
		
		var atlas := preload("res://addons/dungeon_builder/nodes/exit_atlas.tres") as AtlasTexture
		texture_rect.texture=atlas
		texture_rect.size=size
		texture_rect.position-=size/2
		atlas.region.size=Vector2(16,16)
	

func _process(delta: float) -> void:
		setup()
	
