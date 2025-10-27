extends CanvasLayer

const beatTime: int = 750
const allowedDeviation: float = 32

var previousPulseTime: int = 0
var nextPulseTime: int = 0
var nextAudioPulseTime: int = 0

var allowAudioPulse: bool = true
var audioAdjust: int = 0
var isReady: int = 0
var silenced: bool = false

var currentTime: int = 0

@onready var metronome := %"Metronome"
@onready var inputSlider := %"InputSlider"
@onready var confirmPopup := %"ConfirmPopup"

var allowSave: bool = false
var settings: saveData

var inputDifList: Array = [INF, INF, INF, INF, INF, INF, INF, INF]
var inputDeviation: float
var inputMean: float

# Called when the node enters the scene tree for the first time.
func _ready():
	settings = util.loadSave()
	inputSlider.applySliderSettings(-300, 300, 1).setOutputMod(func(input): return "Input will be received " + str(abs(input)) + "ms " + ("earlier" if input <= 0 else "later")).bindToSetting(settings.settings.generalSettings, "inputCalibration")
	audioAdjust = settings.settings.generalSettings.audioCalibration


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if silenced: return
	currentTime = Time.get_ticks_msec()
	if isReady == 0:
		isReady += 1
		nextPulseTime = currentTime + 100
		nextAudioPulseTime = nextPulseTime + audioAdjust
		return
	
	if allowAudioPulse && currentTime >= nextAudioPulseTime:
		if audioAdjust >= 0:
			nextAudioPulseTime = nextPulseTime + audioAdjust
		metronome.bigAudioPulse()
		allowAudioPulse = false
	
	if currentTime >= nextPulseTime:
		metronome.bigPulse(beatTime)
		previousPulseTime = nextPulseTime
		nextPulseTime += beatTime
		
		if audioAdjust < 0:
			nextAudioPulseTime = nextPulseTime + audioAdjust
		allowAudioPulse = true
	
	if Input.is_action_just_pressed("tap"):
		var prevDif: int = currentTime - previousPulseTime
		var nextDif: int = currentTime - nextPulseTime
		inputDifList.pop_front()
		inputDifList.push_back(prevDif if abs(prevDif) < abs(nextDif) else nextDif)
		
		inputMean = inputDifList.reduce(func(accum, number): return accum + number, 0) as float / 8
		if inputMean > 300.0 || inputMean < -300.0: return
		
		inputDeviation = sqrt(inputDifList.reduce(func(accum, number): return accum + pow(number - inputMean, 2), 0) / 7)
		if inputDeviation <= allowedDeviation:
			var newInput: int = -round(inputMean)
			inputSlider.input = newInput
			inputSlider.mainSlider.value = inputSlider.inverseInputMod.call(newInput)
			inputSlider.readOut.text = inputSlider.outputMod.call(newInput)
			allowSave = true
			silenced = true
			confirmPopup.visible = true


func save():
	if !allowSave: return
	inputSlider.commitValue()
	@warning_ignore("shadowed_variable")
	var save = saveData.new()
	save.settings = settings.settings
	save.tutorials = settings.tutorials
	ResourceSaver.save(save, "user://userData.tres")


func _on_tap_button_pressed():
	Input.action_press("tap")


func _on_cancel_button_pressed():
	allowSave = false
	get_tree().change_scene_to_file("res://Scenes/settings_screen.tscn")


func _on_save_button_pressed():
	save()
	get_tree().change_scene_to_file("res://Scenes/settings_screen.tscn")


func _on_cancel_confirm_button_pressed():
	allowSave = false
	confirmPopup.visible = false
	silenced = false
	isReady = 0
	inputDifList = [INF, INF, INF, INF, INF, INF, INF, INF]
