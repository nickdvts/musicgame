extends PanelContainer

var selectedButton := preload("res://UI/Radio Button On.png")
var deselectedButton := preload("res://UI/Radio Button Off.png")
@onready var selectButton := get_node("%Select Button")
@onready var settingsContainer := get_node("%Settings Container")

var complexRef
var refKey

var readOut: Label

var parentScene: Control

# Called when the node enters the scene tree for the first time.
func _ready():
	readOut = get_node("%Readout")


@warning_ignore("shadowed_variable")
func setParent(parent: Control):
	self.parentScene = parent


@warning_ignore("shadowed_variable")
func bindToSetting(complexRef: Dictionary, refKey: String):
	self.complexRef = complexRef
	self.refKey = refKey
	readOut.text = refKey


func _on_delete_button_pressed():
	if await parentScene.attemptDelete(refKey):
		queue_free()


func _on_edit_button_pressed():
	parentScene.attemptEdit(refKey)


func _on_rename_button_pressed():
	parentScene.attemptRename(refKey)


func _on_select_button_pressed():
	select()
	parentScene.setInput(refKey)


func select(): 
	selectButton.icon = selectedButton


func deselect():
	selectButton.icon = deselectedButton


func _on_menu_button_pressed():
	if settingsContainer.visible:
		settingsContainer.visible = false
	else:
		parentScene.showMenu(refKey)


func _on_move_up_button_pressed():
	parentScene.moveUp(refKey)


func _on_move_down_button_pressed():
	parentScene.moveDown(refKey)
