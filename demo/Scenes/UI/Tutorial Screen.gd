extends CanvasLayer

var tutorialList: Array = []

@onready var title: = %"TitleLabel"
@onready var image: = %"TextureRect"
@onready var text: = %"Content"
@onready var spacer: = %"ImgSpacer"
@onready var background: = %"Background"
@onready var specSpacer: = %"Button Spacer"

var currentTutorial: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


@warning_ignore("shadowed_variable_base_class", "shadowed_variable")
func addTutorialData(name: String, text: String, scale: float, image: String = ""):
	tutorialList.append({"name": name, "text": text, "scale": scale, "image": image})
	return self


func addTutorialRef(tutorialDataContainer = null, tutorialReference: String = ""):
	tutorialList.back()["tutorialDataContainer"] = tutorialDataContainer
	tutorialList.back()["tutorialReference"] = tutorialReference
	return self


func addTutorialFunc(tutorialFunc: Callable, parameters: Array = []):
	tutorialList.back()["closeFunc"] = tutorialFunc
	tutorialList.back()["closeParams"] = parameters


func addTutorialTapDetect():
	tutorialList.back()["tapDetect"] = true


func hideTutorial():
	if currentTutorial.has("tutorialDataContainer"):
		currentTutorial.tutorialDataContainer[currentTutorial.tutorialReference] = false
	
	visible = false
	
	if currentTutorial.has("closeFunc"):
		currentTutorial.closeFunc.callv(currentTutorial.closeParams)

@warning_ignore("shadowed_variable_base_class")
func showTutorial(tutorialName: String):
	for tutorial in tutorialList:
		if tutorial.name == tutorialName:
			currentTutorial = tutorial
			title.text = tutorial.name
			text.text = tutorial.text
			setScale(tutorial.scale)
			if tutorial.image == "":
				image.visible = false
				spacer.visible = false
				specSpacer.visible = true
			else:
				image.visible = true
				spacer.visible = true
				specSpacer.visible = false
			visible = true
			return
	assert(false, "Tried to show tutorial that does not exist")


func _on_cancel_button_pressed():
	hideTutorial()

@warning_ignore("shadowed_variable_base_class")
func setScale(scale: float):
	var resize = (1.0 - scale) / 2
	background.anchor_top = 0.0 + resize
	background.anchor_bottom = 1.0 - resize
	background.anchor_left = 0.0 + resize
	background.anchor_right = 1.0 - resize


func _input(event):
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && currentTutorial && currentTutorial.has("tapDetect") && visible:
		hideTutorial()
