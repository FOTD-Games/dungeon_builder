extends Resource

class_name Generation_Tag_Set

# A tagset needs to get above this weight threshold to be considered
# any amount *above* this threshold will be converted to multiple instnaces of the room
# default is 1.
@export var weight_threshold:int = 1

@export
var desired_tags:Array[Weighted_Generation_Tag]
@export
var required_tags:Array[Weighted_Generation_Tag]
@export
var blacklist_tags:Array[Weighted_Generation_Tag]
