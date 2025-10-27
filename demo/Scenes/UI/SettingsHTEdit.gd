extends PanelContainer


var complexRef
var refKey

@warning_ignore("unused_parameter", "shadowed_variable")
var constraint: Callable = func(input): return true
var errorMessage: String = ""

@warning_ignore("shadowed_variable")
var inputMod: Callable = func(input): return input
@warning_ignore("shadowed_variable")
var inverseInputMod: Callable = func(input): return input
@warning_ignore("shadowed_variable")
var outputMod: Callable = func(input): return str(input)

var mainEdit: LineEdit
var readOut: Label

var input = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	mainEdit = get_node("%LineEdit")
	readOut = get_node("%Read Out")


@warning_ignore("shadowed_variable")
func setConstraint(constraintFunction: Callable, errorMessage: String = ""):
	constraint = constraintFunction
	self.errorMessage = errorMessage
	return self


@warning_ignore("shadowed_variable")
func setInputMod(modifierFunction: Callable, inverseFunction: Callable = func(input): return input):
	self.inputMod = modifierFunction
	self.inverseInputMod = inverseFunction
	return self


func setOutputMod(modifierFunction: Callable):
	self.outputMod = modifierFunction
	readOut.text = str(outputMod.call(input))
	return self


func commitValue():
	attemptApplyInput(mainEdit.text)
	complexRef[refKey] = input


@warning_ignore("shadowed_variable")
func bindToSetting(complexRef, refKey):
	self.complexRef = complexRef
	self.refKey = refKey
	input =  complexRef[refKey]
	mainEdit.text = str(inverseInputMod.call(input))
	updateLinked()
	return self


func _on_line_edit_text_submitted(new_text):
	attemptApplyInput(new_text)

func attemptApplyInput(attemptedInput: String):
	var testInput = inputMod.call(attemptedInput)
	if constraint.call(testInput):
		input = testInput
		mainEdit.text = str(input)
		readOut.text = str(outputMod.call(input))
		updateLinked()

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
