extends PanelContainer

var complexRef
var refKey

var mainSlider: Slider
var readOut: Label

@warning_ignore("shadowed_variable")
var inputMod: Callable = func(input): return input
@warning_ignore("shadowed_variable")
var inverseInputMod: Callable = func(input): return input
@warning_ignore("shadowed_variable")
var outputMod: Callable = func(input): return str(input)

var input = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	mainSlider = get_node("%Slider")
	readOut = get_node("%Read Out")


@warning_ignore("shadowed_variable")
func applySliderSettings(minValue: float, maxValue: float, step: float):
	await _ready()
	mainSlider.set_min(minValue)
	mainSlider.set_max(maxValue)
	mainSlider.value = maxValue as float / 2 as float
	input = inputMod.call(mainSlider.value)
	mainSlider.step = step
	return self


@warning_ignore("shadowed_variable")
func setInputMod(modifierFunction: Callable, inverseFunction: Callable = func(input): return input):
	self.inputMod = modifierFunction
	self.inverseInputMod = inverseFunction
	return self


func setOutputMod(modifierFunction: Callable):
	await _ready()
	self.outputMod = modifierFunction
	readOut.text = outputMod.call(input)
	return self


func commitValue():
	complexRef[refKey] = input


func bindToSetting(complexRef, refKey):
	self.complexRef = complexRef
	self.refKey = refKey
	input = complexRef[refKey]
	mainSlider.value = inverseInputMod.call(input)
	readOut.text = outputMod.call(input)
	updateLinked()
	return self


func _on_slider_value_changed(value):
	input = inputMod.call(value)
	updateLinked()
	readOut.text = outputMod.call(input)


func _on_right_button_pressed():
	if mainSlider.value < mainSlider.max_value:
		mainSlider.value += mainSlider.step


func _on_left_button_pressed():
	if mainSlider.value > mainSlider.min_value:
		mainSlider.value -= mainSlider.step


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
		panel.readOut.text = panel.outputMod.call(panel.input)
