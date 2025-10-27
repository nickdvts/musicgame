extends PanelContainer


signal submitAttempted

var selectionRef: Dictionary
var selectionKey: String
var orderRef: Array

var complexRef: Dictionary

var presetReadout := preload("res://Scenes/UI/preset_readout.tscn")

var presetContainer: Control
var containedPresets: Array = []
var confirmPopup: Control
var renamePopup: Control
var renameEditor: LineEdit

var clonedRef: Dictionary = {}

var defaultPreset: Dictionary = {}

var parentScene: Node

var deleteSelected: bool = false
var cancelSelected: bool = false

var panelList: Array = []
var presetEditor: Control
var titleNode: Control
var prefix: String
var suffix: String

var editorKey: String

@onready var inputBlocker: ColorRect = get_node("%Input Blocker")
@onready var mainContainer: VBoxContainer = %"MainContainer"
@onready var currentReadout: Label = get_node("%Current Label")

@warning_ignore("shadowed_variable")
var outputMod: Callable = func(input): return str(input)

var input: String

# Called when the node enters the scene tree for the first time.
func _ready():
	presetContainer = get_node("%PresetContainer")
	confirmPopup = get_node("%Delete Popup")
	renamePopup = get_node("%Rename Popup")
	renameEditor = get_node("%RenameEdit")


func setDefaultPreset(dictionary: Dictionary):
	self.defaultPreset = dictionary
	return self


func setParent(parent: Node):
	self.parentScene = parent
	return self


@warning_ignore("shadowed_variable")
func setEditor(editor: Control, titleNode: Control):
	self.presetEditor = editor
	self.titleNode = titleNode
	return self


func setOutputMod(modifierFunction: Callable):
	self.outputMod = modifierFunction
	return self


func addPanel(panel: Control, keyPath: Array):
	panelList.append({"panel": panel, "keyPath": keyPath})


@warning_ignore("shadowed_variable")
func bindToSetting(complexRef: Dictionary, selectionRef: Dictionary, selectionKey: String, orderRef):
	self.complexRef = complexRef
	self.selectionRef = selectionRef
	self.selectionKey = selectionKey
	self.orderRef = orderRef
	input = selectionRef[selectionKey]
	updateOrder()
	refreshPresetReadout()
	return self


func moveDown(keyName: String):
	var index: int = 0
	while index < orderRef.size():
		if orderRef[index] == keyName:
			if index >= orderRef.size() - 1: return
			orderRef.insert(index + 2, keyName)
			orderRef.remove_at(index)
			break
		index += 1
	
	refreshPresetReadout()
	showMenu(keyName)


func moveUp(keyName: String):	
	var index: int = 0
	while index < orderRef.size():
		if orderRef[index] == keyName:
			if index <= 0: return
			orderRef.insert(index - 1, keyName)
			orderRef.remove_at(index + 1)
			break
		index += 1
	
	refreshPresetReadout()
	showMenu(keyName)

func updateOrder():
	var found: bool = false
	for key in complexRef.keys():
		found = false
		for orderKey in orderRef:
			if key == orderKey:
				found = true
				break
		if !found:
			orderRef.append(key)


func refreshPresetReadout():
	for preset in containedPresets:
		preset.queue_free()
	containedPresets = []
	for key in orderRef:
		addReadout(key, false)
	setInput(input)


func addReadout(keyName: String, newPreset: bool = true):
	var output := presetReadout.instantiate()
	presetContainer.add_child(output)
	output.setParent(self)
	if newPreset:
		clonedRef[keyName] = defaultPreset.duplicate()
		output.bindToSetting(clonedRef, keyName)
	else:
		output.bindToSetting(complexRef, keyName)
	containedPresets.append(output)


func attemptDelete(keyName: String):
	if complexRef.keys().size() > 1:
		return await getDeleteConfirmation(keyName)


func getDeleteConfirmation(keyName: String):
	confirmPopup.visible = true
	inputBlocker.visible = true
	mainContainer.modulate.a = 0.0
	deleteSelected = false
	await confirmPopup.visibility_changed
	if deleteSelected:
		complexRef.erase(keyName)
		orderRef.remove_at(orderRef.find(keyName))
		@warning_ignore("shadowed_variable")
		containedPresets.remove_at((util.getNext(containedPresets, 0, func(input): return input.refKey == keyName)))
		if input == keyName:
			setInput(orderRef[0])
	return deleteSelected


func getRenameConfirmation():
	cancelSelected = false
	inputBlocker.visible = true
	mainContainer.modulate.a = 0.0
	renameEditor.placeholder_text = "Preset Name"
	while true:
		renameEditor.text = ""
		renamePopup.visible = true
		await self.submitAttempted
		if cancelSelected || renameEditor.text == "":
			renamePopup.visible = false
			inputBlocker.visible = false
			mainContainer.modulate.a = 1.0
			return false
		if complexRef.has(renameEditor.text) || renameEditor.text.length() > 16:
			if renameEditor.text.length() > 16:
				renameEditor.placeholder_text = "ERROR: Maximum 16 Characters"
			else:
				renameEditor.placeholder_text = "ERROR: Name Already Exists"
		else:
			renamePopup.visible = false
			inputBlocker.visible = false
			mainContainer.modulate.a = 1.0
			return true


func attemptRename(keyName: String):
	if !complexRef.has(keyName): return
	if await getRenameConfirmation():
		var temp = complexRef[keyName]
		complexRef.erase(keyName)
		complexRef[renameEditor.text] = temp
		orderRef[orderRef.find(keyName)] = renameEditor.text
		refreshPresetReadout()
		if keyName == input:
			setInput(renameEditor.text)
			showMenu(renameEditor.text)
	renameEditor.text = ""


func attemptEdit(keyName: String):
	titleNode.text = outputMod.call(keyName)
	
	if !clonedRef.has(keyName):
		if complexRef.has(keyName):
			clonedRef[keyName] = complexRef[keyName]
		else:
			clonedRef[keyName] = defaultPreset
	
	var currentPreset = clonedRef[keyName]
	
	for panelData in panelList:
		var keyPath = panelData.keyPath
		var cref
		if keyPath.size() > 1:
			cref = currentPreset[keyPath.front()]
			var depth = 1
			while depth < keyPath.size() - 1:
				cref = cref[keyPath[depth]]
				depth += 1
		else:
			cref = currentPreset
		panelData.panel.bindToSetting(cref, keyPath.back())
	
	editorKey = keyName
	parentScene.setActiveEditor(presetEditor)


func commitValue():
	selectionRef[selectionKey] = input


func setInput(inputName: String):
	for readout in containedPresets:
		if readout.refKey == inputName:
			readout.select()
		else:
			readout.deselect()
	input = inputName
	currentReadout.text = "Current Preset: " + input


@warning_ignore("shadowed_variable_base_class")
func showMenu(name: String):
	for readout in containedPresets:
		readout.settingsContainer.visible = readout.refKey == name


func saveEdit():
	for panelData in panelList:
		panelData.panel.commitValue()
	complexRef[editorKey] = clonedRef[editorKey]


func cancelEdit():
	clonedRef[editorKey].erase(editorKey)


func _on_delete_button_pressed():
	deleteSelected = true
	confirmPopup.visible = false
	inputBlocker.visible = false
	mainContainer.modulate.a = 1.0


func _on_cancel_button_pressed():
	deleteSelected = false
	confirmPopup.visible = false
	inputBlocker.visible = false
	mainContainer.modulate.a = 1.0


func _on_add_button_pressed():
	var number = 1
	var newName: String
	while true:
		newName = "Preset " + str(number)
		if !complexRef.has(newName):
			complexRef[newName] = defaultPreset.duplicate(true)
			break
		number += 1
	orderRef.append(newName)
	refreshPresetReadout()


func _on_accept_rename_pressed():
	submitAttempted.emit()


func _on_cancel_rename_pressed():
	cancelSelected = true
	submitAttempted.emit()
