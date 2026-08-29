extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	MetaData.coins_updated.connect(on_coins_changed)



func on_coins_changed(new_amount):
	%CoinAmount.text = str(new_amount)
