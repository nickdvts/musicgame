extends CanvasLayer

const beatTime: int = 1000
var nextPulseTime: int = 0
var nextAudioPulseTime: int = 0
var currentTime: int = 0
var allowAudioPulse: bool = true
var beatNumber: int = 1
var audioBeatNumber: int = 1

@onready var metronome: ColorRect = %"Metronome"
@onready var audioSlider := %"AudioSlider"

var allowSave: bool = false
var settings: saveData
var isReady: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	settings = util.loadSave()
	audioSlider.applySliderSettings(-300, 300, 1).setOutputMod(func(input): return "Audio timing will play " + str(abs(input)) + "ms " + ("earlier" if input <= 0 else "later")).bindToSetting(settings.settings.generalSettings, "audioCalibration")
	allowSave = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	currentTime = Time.get_ticks_msec()
	if isReady == 0:
		isReady += 1
		nextPulseTime = currentTime + 100
		nextAudioPulseTime = nextPulseTime + audioSlider.input
		return
	
	if allowAudioPulse && currentTime >= nextAudioPulseTime:
		if audioSlider.input >= 0:
			nextAudioPulseTime = nextPulseTime + audioSlider.input
			audioBeatNumber = beatNumber + 1
		else:
			audioBeatNumber = beatNumber
		
		if audioBeatNumber == 1 || audioBeatNumber == 5:
			metronome.bigAudioPulse()
		else:
			metronome.audioPulse()
		
		allowAudioPulse = false
	
	if currentTime >= nextPulseTime:
		if beatNumber == 1:
			metronome.bigPulse(beatTime)
			beatNumber = 5
		else:
			metronome.pulse(beatTime)
		beatNumber -= 1
		
		nextPulseTime += beatTime
		
		if audioSlider.input < 0:
			nextAudioPulseTime = nextPulseTime + audioSlider.input
		allowAudioPulse = true


func save():
	if !allowSave: return
	audioSlider.commitValue()
	@warning_ignore("shadowed_variable")
	var save = saveData.new()
	save.settings = settings.settings
	save.tutorials = settings.tutorials
	ResourceSaver.save(save, "user://userData.tres")


func _on_save_button_pressed():
	save()
	get_tree().change_scene_to_file("res://Scenes/settings_screen.tscn")


func _on_cancel_button_pressed():
	allowSave = false
	get_tree().change_scene_to_file("res://Scenes/settings_screen.tscn")
