extends PanelContainer

var complexRef

var readOut: Label

var parentScene: Control

# Called when the node enters the scene tree for the first time.
func _ready():
	readOut = get_node("%Readout")


@warning_ignore("shadowed_variable")
func setParent(parent: Control):
	self.parentScene = parent
	return self


@warning_ignore("shadowed_variable")
func bindToSetting(complexRef: Dictionary, newText: String):
	await _ready()
	self.complexRef = complexRef
	readOut.text = newText


func _on_delete_button_pressed():
	if parentScene.attemptDelete(complexRef):
		complexRef = null
		queue_free()
