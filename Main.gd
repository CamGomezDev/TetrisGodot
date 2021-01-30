extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$HUD/Score.text = str($PiecesGrid.full_rows)


func _on_HUD_start_game():
	$PiecesGrid.start()


func _on_PiecesGrid_lose_game():
	$HUD/Message.text = "loser"
	$HUD/Message.show()
	$HUD/StartButton.show()
	print("Lost game")
