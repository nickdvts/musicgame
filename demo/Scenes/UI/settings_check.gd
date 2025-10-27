extends PanelContainer

var complexRef
var refKey

var mainCheck: Button
var readOut: Label

var checkedGraphic: Texture2D = preload("res://UI/Switch Button On.png")
var uncheckedGraphic: Texture2D = preload("res://UI/Switch Button Off.png")

var menuToggle: bool = false

@warning_ignore("shadowed_variable")
var inputMod: Callable = func(input): return input
@warning_ignore("shadowed_variable")
var inverseInputMod: Callable = func(input): return input
@warning_ignore("shadowed_variable")
var outputMod: Callable = func(input): return str(input)

var siblings: Array = []

var input = false

# Called when the node enters the scene tree for the first time.
func _ready():
	mainCheck = get_node("%CheckButton")
	readOut = get_node("%Read Out")
	pollButtonState()


func commitValue():
	complexRef[refKey] = input


@warning_ignore("shadowed_variable")
func bindToSetting(complexRef, refKey):
	self.complexRef = complexRef
	self.refKey = refKey
	input = complexRef[refKey]
	mainCheck.button_pressed = inverseInputMod.call(input)
	pollButtonState()
	updateLinked()
	return self


func setOutputMod(modifierFunction: Callable):
	self.outputMod = modifierFunction
	readOut.text = outputMod.call(input)
	return self


@warning_ignore("shadowed_variable")
func setInputMod(modifierFunction: Callable, inverseFunction: Callable = func(input): return input):
	self.inputMod = modifierFunction
	self.inverseInputMod = inverseFunction
	return self


func useAsMenuToggle():
	menuToggle = true
	siblings = get_parent().get_children()
	var t = 0
	while t < siblings.size():
		var sibling = siblings[t]
		if sibling is Control && sibling != self:
			t += 1
		else:
			siblings.remove_at(t)
	pollButtonState()
	return self


func pollButtonState():
	if mainCheck.button_pressed:
		mainCheck.set_button_icon(checkedGraphic)
		if menuToggle:
			for sibling in siblings:
				sibling.visible = true
	else:
		mainCheck.set_button_icon(uncheckedGraphic)
		if menuToggle:
			for sibling in siblings:
				sibling.visible = false

var linkedPanels: Array = []
var linkedMeta: Array = []
func linkToPanelMeta(panel: PanelContainer, metaName: String):
	linkedPanels.append(panel)
	linkedMeta.append(metaName)
	panel.set_meta(metaName, input)
	panel.outputMod.call(panel.input)
	return self

func updateLinked():
	var panel: PanelContainer
	for l in range(linkedPanels.size()):
		panel = linkedPanels[l]
		panel.set_meta(linkedMeta[l], input)
		panel.outputMod.call(panel.input)

func _on_check_button_toggled(button_pressed):
	input = inputMod.call(button_pressed)
	updateLinked()
	readOut.text = outputMod.call(input)
	pollButtonState()
