extends PanelContainer

class_name SettingsHSlider

signal value_changed(value)

@onready var slider := %"HSlider"
@onready var label := %"Label"

var input_mod_func: Callable
var output_mod_func: Callable
var min_value: float
var max_value: float
var step_value: float

func _ready():
	if slider:
		slider.value_changed.connect(_on_slider_value_changed)

func applySliderSettings(min_val: float, max_val: float, step: float) -> SettingsHSlider:
	min_value = min_val
	max_value = max_val
	step_value = step
	if slider:
		slider.min_value = min_val
		slider.max_value = max_val
		slider.step = step
	return self

func setOutputMod(func_ref: Callable) -> SettingsHSlider:
	output_mod_func = func_ref
	return self

func setInputMod(func_ref: Callable, inverse_func: Callable = Callable()) -> SettingsHSlider:
	input_mod_func = func_ref
	return self

func _on_slider_value_changed(value: float):
	if output_mod_func.is_valid():
		label.text = output_mod_func.call(value)
	emit_signal("value_changed", value)
