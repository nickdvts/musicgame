extends PanelContainer


var complexRef
var refKey: String

var dictionaryList: Array = []
var inputsList: Array = []

var defaultDictionary: Dictionary = {}
var newDictionary: Dictionary = {}

var dictionaryReadout = preload("res://Scenes/UI/settings_dictionary_readout.tscn")

var dictionaryListContainer: GridContainer
var addMenu: VBoxContainer
var addPopup: PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	dictionaryListContainer = get_node("%DictionaryContainer")
	addMenu = get_node("%AddContainer")
	addPopup = get_node("%Add Popup")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


@warning_ignore("shadowed_variable")
func bindToSetting(complexRef, refKey: String):
	for r in dictionaryListContainer.get_children():
		r.free()
	self.complexRef = complexRef
	self.refKey = refKey
	self.dictionaryList = complexRef[refKey].duplicate()
	for element in dictionaryList:
		if element is Dictionary:
			addReadout(element)


func addInput(panel: Node, keyName: String, defaultValue):
	addMenu.add_child(panel)
	inputsList.append(panel)
	panel.set_meta("key", keyName)
	defaultDictionary[keyName] = defaultValue
	newDictionary[keyName] = defaultValue
	return self


func addReadout(dictionary: Dictionary):
	var outputStr: String = ""
	for panel in inputsList:
		outputStr += str(panel.outputMod.call(dictionary[panel.get_meta("key")])) + "\n"
	var new: PanelContainer = dictionaryReadout.instantiate()
	new.setParent(self).bindToSetting(dictionary, outputStr)
	dictionaryListContainer.add_child(new)


func attemptNewDictionary():
	for panel in inputsList:
		panel.commitValue()
	var clone: Dictionary = newDictionary.duplicate()
	dictionaryList.append(clone)
	addReadout(clone)
	clearInput()


func clearInput():
	for key in newDictionary.keys():
		newDictionary[key] = defaultDictionary[key]
	for panel in inputsList:
		panel.bindToSetting(newDictionary, panel.get_meta("key"))


func commitValue():
	complexRef[refKey] = dictionaryList.duplicate()


func attemptDelete(dictionary):
	if dictionaryList.size() <= 1:
		return false
	var index = util.getNext(dictionaryList, 0, func(dict): return dict == dictionary)
	if index == -1:
		return false
	else:
		dictionaryList.remove_at(index)
		return true


func _on_new_button_pressed():
	addPopup.visible = !addPopup.visible
	clearInput()


func _on_cancel_button_pressed():
	addPopup.visible = false
	clearInput()


func _on_add_button_pressed():
	addPopup.visible = false
	attemptNewDictionary()
