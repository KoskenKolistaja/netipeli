extends StaticBody2D


@export var can_spawn : bool


# Called when the node enters the scene tree for the first time.
func _ready():
	if not multiplayer.is_server():
		return
	
	if not can_spawn:
		return
	
	
	if randf_range(0,1) < 0.05:
		var item_spawner = get_tree().get_first_node_in_group("item_spawner")
		item_spawner.spawn_item("coin",%ItemContainer.global_position)
