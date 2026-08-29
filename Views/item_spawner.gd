extends MultiplayerSpawner


@export var coin : PackedScene







func spawn_item(item_name : String, item_position : Vector2):
	var coin_instance = coin.instantiate()
	%ItemContainer.add_child(coin_instance,true)
	coin_instance.global_position = item_position
