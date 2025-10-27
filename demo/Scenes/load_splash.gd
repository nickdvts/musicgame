extends CanvasLayer

var startTime: int
var frames: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	frames = 0


func _process(_delta):
	if frames > 2:
		get_tree().change_scene_to_file("res://Scenes/session_screen.tscn")
	frames += 1
