extends CanvasLayer

signal presetMenuClosed

const numberLookup = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

var settings := {}
var tutorials := {}

var allowSave := false

@onready var generalPanel := %"General Panel"
@onready var generalTabs := %"GeneralTabs"

@onready var nSize := %"NoteScale"
@onready var fSize := %"FeeScale"
@onready var bSize := %"ButtScale"

@onready var tMarg := %"TopMarg"
@onready var sMarg := %"SideMarg"
@onready var lMarg := %"LineMarg"
@onready var bMarg := %"ButtMarg"

@onready var iCal := %"InCali"
@onready var aCal := %"AuCali"


@onready var rWin := %"RelWin"
@onready var pWin := %"PreWin"

@onready var hMeas := %"Highlight"

@onready var mOn := %"Metro"
@onready var mVol := %"MetroVol"
@onready var mVis := %"MetroShow"
@onready var cIMeas := %"CountMeas"
@onready var cIAuto := %"AutoCount"
@onready var cIBPM := %"AutoBPM"


@onready var generationPanel := %"Generation Panel"
@onready var generationTitle := %"Gen Preset Title"
@onready var generationTabs := %"GenerationTabs"
@onready var genPreMan := %"Gen Preset Man"

@onready var sLen := %"SeqLength"


@onready var wDiv := %"WholeDiv"
@onready var hDiv := %"HalfDiv"
@onready var qDiv := %"QuarterDiv"
@onready var eDiv := %"EighthDiv"
@onready var sDiv := %"SixteenthDiv"

@onready var wNote := %"WholeNote"
@onready var hNote := %"HalfNote"
@onready var qNote := %"QuarterNote"
@onready var eNote := %"EighthNote"
@onready var sNote := %"SixteenthNote"

@onready var wTrip := %"WholeTrip"
@onready var hTrip := %"HalfTrip"
@onready var qTrip := %"QuarterTrip"
@onready var eTrip := %"EighthTrip"
@onready var sTrip := %"SixteenthTrip"

@onready var mTie := %"MeasTie"
@onready var wTie := %"WholeTie"
@onready var hTie := %"HalfTie"
@onready var qTie := %"QuarterTie"
@onready var eTie := %"EighthTie"
@onready var sTie := %"SixteenthTie"

@onready var wSyn := %"WholeSynco"
@onready var hSyn := %"HalfSynco"
@onready var qSyn := %"QuarterSynco"
@onready var eSyn := %"EighthSynco"
@onready var sSyn := %"SixteenthSynco"

@onready var sigMan := %"SigManager"
@onready var sigChange := %"SigChange"


@onready var tTut := %"tapTut"
@onready var wTut := %"welTut"
@onready var mTut := %"manTut"
@onready var fTut := %"feeTut"


@onready var editors := [generationPanel, generalPanel]
@onready var tabs := [generationTabs, generalTabs]

@onready var allPanels := [nSize, fSize, tMarg, lMarg, sMarg, iCal, aCal, bSize, bMarg, mOn, mVol, mVis, cIMeas, cIAuto, cIBPM, sLen, rWin, pWin, genPreMan, tTut, wTut, mTut, fTut]

@onready var genGroup := %"GenGroup"
@onready var calGroup := %"CalGroup"
@onready var sesGroup := %"SesGroup"
@onready var graGroup := %"GraGroup"
@onready var infGroup := %"InfGroup"

@onready var valGroup := %"ValGroup"
@onready var notGroup := %"NotGroup"
@onready var tieGroup := %"TieGroup"
@onready var triGroup := %"TriGroup"
@onready var synGroup := %"SynGroup"
@onready var timGroup := %"TimGroup"

@onready var scrollHandler: ScrollHandler = %"ScrollHandler"

var hSlider: PackedScene = preload("res://Scenes/UI/settings_h_slider.tscn")

@onready var tutorialMenu := %"Tutorial Screen"

func percentOfAll(this: PanelContainer):
	var total: float = 0
	total += this.get_meta("wv")
	total += this.get_meta("hv")
	total += this.get_meta("qv")
	total += this.get_meta("ev")
	total += this.get_meta("sv")
	return str(round(this.input / total * 1000) / 10) + "%"

func _ready():
	settings = util.loadSave().settings
	tutorials = util.loadSave().tutorials
	
	setActiveEditor(generalPanel)
	nSize.applySliderSettings(.01, .5, .01).setOutputMod(func(input): return "Note Scale: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "noteScale")
	fSize.applySliderSettings(.05, .25, .01).setOutputMod(func(input): return "Feedback Size: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "feedbackDisplayHeight")
	bSize.applySliderSettings(.05, .25, .01).setOutputMod(func(input): return "Button Size: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "buttonSize")
	
	tMarg.applySliderSettings(0, .25, .01).setOutputMod(func(input): return "Top Padding: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "topMargin")
	lMarg.applySliderSettings(0, .25, .01).setOutputMod(func(input): return "Line Padding: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "notePadding")
	sMarg.applySliderSettings(0, .2, .01).setOutputMod(func(input): return "Side Padding: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "sideMargin")
	bMarg.applySliderSettings(0, .25, .01).setOutputMod(func(input): return "Button Padding: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "buttonMargin")
	
	iCal.applySliderSettings(-300, 300, 1).setOutputMod(func(input): return "Input Calibration: " + str(abs(input)) + "ms " + ("earlier" if input <= 0 else "later")).bindToSetting(settings.generalSettings, "inputCalibration")
	aCal.applySliderSettings(-300, 300, 1).setOutputMod(func(input): return "Audio Calibration: " + str(abs(input)) + "ms " + ("earlier" if input <= 0 else "later")).bindToSetting(settings.generalSettings, "audioCalibration")
	
	
	sLen.applySliderSettings(1, 100, 1).setOutputMod(func(input): return "Measures: " + str(input)).bindToSetting(settings.generalSettings, "sequenceLength")
	
	wDiv.linkToPanelMeta(wDiv, "wv").linkToPanelMeta(hDiv, "wv").linkToPanelMeta(qDiv, "wv").linkToPanelMeta(eDiv, "wv").linkToPanelMeta(sDiv, "wv")
	hDiv.linkToPanelMeta(wDiv, "hv").linkToPanelMeta(hDiv, "hv").linkToPanelMeta(qDiv, "hv").linkToPanelMeta(eDiv, "hv").linkToPanelMeta(sDiv, "hv")
	qDiv.linkToPanelMeta(wDiv, "qv").linkToPanelMeta(hDiv, "qv").linkToPanelMeta(qDiv, "qv").linkToPanelMeta(eDiv, "qv").linkToPanelMeta(sDiv, "qv")
	eDiv.linkToPanelMeta(wDiv, "ev").linkToPanelMeta(hDiv, "ev").linkToPanelMeta(qDiv, "ev").linkToPanelMeta(eDiv, "ev").linkToPanelMeta(sDiv, "ev")
	sDiv.linkToPanelMeta(wDiv, "sv").linkToPanelMeta(hDiv, "sv").linkToPanelMeta(qDiv, "sv").linkToPanelMeta(eDiv, "sv").linkToPanelMeta(sDiv, "sv")
	
	wDiv.applySliderSettings(0, 1, .01).setOutputMod(func(_input): return "Whole Value Probability: " + percentOfAll(wDiv))
	genPreMan.addPanel(wDiv, ["divProb", 0])
	hDiv.applySliderSettings(0, 1, .01).setOutputMod(func(_input): return "Half Value Probability: " + percentOfAll(hDiv))
	genPreMan.addPanel(hDiv, ["divProb", 1])
	qDiv.applySliderSettings(0, 1, .01).setOutputMod(func(_input): return "Quarter Value Probability: " + percentOfAll(qDiv))
	genPreMan.addPanel(qDiv, ["divProb", 2])
	eDiv.applySliderSettings(0, 1, .01).setOutputMod(func(_input): return "Eighth Value Probability: " + percentOfAll(eDiv))
	genPreMan.addPanel(eDiv, ["divProb", 3])
	sDiv.applySliderSettings(0, 1, .01).setOutputMod(func(_input): return "Sixteenth Value Probability: " + percentOfAll(sDiv))
	genPreMan.addPanel(sDiv, ["divProb", 4])
	
	wNote.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Whole Note Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(wNote, ["noteProb", 0])
	hNote.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Half Note Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(hNote, ["noteProb", 1])
	qNote.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Quarter Note Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(qNote, ["noteProb", 2])
	eNote.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Eighth Note Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(eNote, ["noteProb", 3])
	sNote.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Sixteenth Note Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(sNote, ["noteProb", 4])
	
	wSyn.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Whole Note Syncopation Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(wSyn, ["syncoProb", 0])
	hSyn.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Half Note Syncopation Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(hSyn, ["syncoProb", 1])
	qSyn.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Quarter Note Syncopation Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(qSyn, ["syncoProb", 2])
	eSyn.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Eighth Note Syncopation Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(eSyn, ["syncoProb", 3])
	sSyn.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Sixteenth Note Syncopation Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(sSyn, ["syncoProb", 4])
	
	wTrip.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Whole Note Triplet Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(wTrip, ["tripletProb", 0])
	hTrip.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Half Note Triplet Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(hTrip, ["tripletProb", 1])
	qTrip.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Quarter Note Triplet Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(qTrip, ["tripletProb", 2])
	eTrip.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Eighth Note Triplet Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(eTrip, ["tripletProb", 3])
	sTrip.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Sixteenth Note Triplet Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(sTrip, ["tripletProb", 4])
	
	mTie.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Measure Tie Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(mTie, ["tieOverMeasureProb"])
	wTie.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Whole Note Tie Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(wTie, ["tiedProb", 0])
	hTie.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Half Note Tie Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(hTie, ["tiedProb", 1])
	qTie.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Quarter Note Tie Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(qTie, ["tiedProb", 2])
	eTie.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Eighth Note Tie Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(eTie, ["tiedProb", 3])
	sTie.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Sixteenth Note Tie Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(sTie, ["tiedProb", 4])
	
	var nIn := hSlider.instantiate()
	nIn.setOutputMod(func(input): return "Numerator: " + str(input)).applySliderSettings(2, 12, 1).setInputMod(func(input): return int(input))
	var dIn := hSlider.instantiate()
	dIn.setInputMod(func(input): return pow(2, input), func(input): return log(input)/log(2)).setOutputMod(func(input): return "Denominator: " + str(input)).applySliderSettings(0, 4, 1)
	var cIn := hSlider.instantiate()
	cIn.setOutputMod(func(input): return "Chance: " + str(input)).applySliderSettings(1, 100, 1).setInputMod(func(input): return int(input))
	
	sigMan.addInput(nIn, "numerator", 4).addInput(dIn, "denominator", 4).addInput(cIn, "chance", 50)
	genPreMan.addPanel(sigMan, ["sigList"])
	
	sigChange.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Time Signature Change Probability: " + str(input * 100) + "%")
	genPreMan.addPanel(sigChange, ["sigChangeProb"])
	
	genPreMan.setParent(self).setEditor(generationPanel, generationTitle).bindToSetting(settings.generationPresets, settings.generalSettings, "generationPreset", settings.generalSettings.genPresetOrder)
	genPreMan.setDefaultPreset(
			{
				"divProb": [0.01, 0.1, 0.2, 0.3, 0.04],
				"noteProb": [1, 0.8, 0.7, 0.7, 1],
				"tripletProb": [0, 0, 0, .05, 0],
				"tiedProb": [0.3, 0.3, 0.3, 0.3, 0.2],
				"syncoProb": [0, 0.2, 0.5, 1, 1],
				"tieOverMeasureProb": .05,
				"sigChangeProb": .03,
				"sigList": [
					{
						"numerator": 4,
						"denominator": 4,
						"chance": 10
					},
					{
						"numerator": 3,
						"denominator": 4,
						"chance": 10
					},
				]
			})
	
	
	rWin.applySliderSettings(0.05, .5, .01).setOutputMod(func(input): return "Release Window: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "releaseWindow")
	pWin.applySliderSettings(0.05, .5, .01).setOutputMod(func(input): return "Press Window: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "pressWindow")
	
	mOn.useAsMenuToggle().setOutputMod(func(_input): scrollHandler.refreshSize(); return "Metronome").bindToSetting(settings.generalSettings, "metronomeOn")
	mVol.applySliderSettings(0, 1, .01).setOutputMod(func(input): return "Metronome Volume: " + str(input * 100) + "%").bindToSetting(settings.generalSettings, "metronomeVolume")
	mVis.setOutputMod(func(_input): return "Show Metronome").bindToSetting(settings.generalSettings, "showMetronome")
	cIMeas.applySliderSettings(1, 4, 1).setOutputMod(func(input): return "Count In Measures: " + str(input)).bindToSetting(settings.generalSettings, "countInMeasures")
	cIAuto.setOutputMod(func(input): scrollHandler.refreshSize(); cIBPM.visible = !input; return "Set Tempo Manually").bindToSetting(settings.generalSettings, "manualCountIn")
	cIBPM.applySliderSettings(30, 240, 1).setOutputMod(func(input): return "BPM: " + str(input)).bindToSetting(settings.generalSettings, "BPM")
	hMeas.setOutputMod(func(_input): return "Highlight Current Measure").bindToSetting(settings.generalSettings, "highlightCurrentMeasure")
	
	
	tTut.setOutputMod(func(_input): return "Give Tap Hints").bindToSetting(tutorials, "tapHint")
	wTut.setOutputMod(func(_input): return "Give Welcome Tutorial").bindToSetting(tutorials, "welcome")
	mTut.setOutputMod(func(_input): return "Give Manual Count In Tutorial").bindToSetting(tutorials, "manualCountIn")
	fTut.setOutputMod(func(_input): return "Give Feedback Tutorial").bindToSetting(tutorials, "feedback")
	
	tutorialMenu.addTutorialData("Welcome!", "Welcome to BeatMaster, an app where you can practice sightreading music. Tap anywere to begin, then tap out the rhythm on your screen. If you make a mistake, you can always use the restart button in the upper right corner.", .5)
	tutorialMenu.addTutorialData("Manual Count In", "You have manual count in turned on. To count in manually, simply tap on the screen with a consistent timing. You will need to tap once per beat for " + numberLookup[settings.generalSettings.countInMeasures] + (" measures." if settings.generalSettings.countInMeasures > 1 else " measure."), .5)
	tutorialMenu.addTutorialData("Feedback", "When you have finished tapping out the rhythm, you are given feedback.\n
Blue and pink lines indicate notes and rests respectively. 
The notes you played are displayed below those lines. Red indicates an incorrect note while green indicates a correct note. 
The front and back of each note indicates whether it was started or ended at the right time.\n
You can switch between measures using the arrows on the right side of the screen.
If you want to correct a mistake, you can use the restart button. You can also press the play button to generate new sheet music.", .9)
	
	tutorialMenu.addTutorialData("General Settings", "Count In Measures - The number of measures played when counting in\n
Set Tempo Manually -Allows you to set your own tempo by tapping on each beat when count in\n
BPM - The tempo of the metronome (only available when Set Tempo Manually is off)\n
Metronome - A general on and off switch for both metronome visuals and audio\n
Metronome Volume - The volume of the metronome\n
Show Metronome - Toggles whether or not the metronome is visible", 0.9)
	
	tutorialMenu.addTutorialData("Generation Settings", "Measures - The number of measures generated in each session\n
- Presets -
Generation presets can be selected by clicking the circle buttons on the left, created by clicking the plus button, and edited by clicking the menu buttons on the right. The arrow buttons can be used to rearrange presets. The trash button can delete presets. The pen button can rename presets. The settings button allows you to customize presets.", 0.8)
	
	tutorialMenu.addTutorialData("Calibration Settings", "Input Calibration - Affects when your inputs are processed. Can be more easily calibrated by clicking the \"Calibrate Input\" button\n
Audio Calibration - Affects when audio is played and processed. Can be more easily calibrated by clicking the \"Calibrate Audio\" button\n
Press Window - The window of time a in which note can be started and counted as correct. Measured in percent of a quarter note.\n
Release Window - The window of time a in which note can be ended and counted as correct. Measured in percent of a quarter note.\n", 0.8)
	
	tutorialMenu.addTutorialData("Graphics Settings", "Highlight Current Measure - Underlines the current measure\n
Scale Settings - Sets the scale of something based on percent of screen height
Padding Settings - Sets the scale of something based on percent of screen height (side and button padding are based on screen width)", 0.8)
	
	tutorialMenu.addTutorialData("Tutorial Menu", "Give Tap Hints - Displays a hint to tap after inactivity\n
Give Tutorial - Gives specific tutorials the next time they are needed\n
Tutorial Buttons - Shows a specific tutorial now", 0.8)
	
	tutorialMenu.addTutorialData("Value Probabilities", "In music, value is the duration of a note.\n
Adjusting these sliders will affect how often a note or rest of each value will appear.", 0.5)
	
	tutorialMenu.addTutorialData("Note Probabilties", "Adjusting these sliders determines how often notation of a specific value will be a note or a rest.", 0.5)
	
	tutorialMenu.addTutorialData("Tie Probabilities", "Adjusting these sliders determines how often a note of a specific value will be tied or dotted. Measure Tie Probability affects ties going over measure lines.", 0.5)
	
	tutorialMenu.addTutorialData("Triplet Probabilities", "Adjusting these sliders determines how often triplets with notes of a specific value will appear.", 0.5)
	
	tutorialMenu.addTutorialData("Syncopation Probabilities", "In music, syncopation refers to emphasis on an off beat (when the second note out of two notes is played but not the first).\n
These sliders determine how often notes of a specific value will be syncopated.", 0.7)
	
	tutorialMenu.addTutorialData("Time Signatures", "Time signatures determine how many beats are in a measure (numerator) and how long each beat is (denominator).\n
Time Signature Change Probability is the chance that a time signature will change mid-sequence.\n
New time signatures can be added with the plus button.", 0.7)
	
	allowSave = true


func _on_play_button_pressed():
	save()
	get_tree().change_scene_to_file("res://Scenes/session_screen.tscn")


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST || what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save()


func setActiveEditor(editor: Node):
	for pEditor in editors:
		pEditor.visible = false
	if editor == generalPanel:
		generalTabs.visible = true
		generationTabs.visible = false
	else:
		generalTabs.visible = false
		generationTabs.visible = true
	editor.visible = true
	scrollHandler.resetPosition()


func save():
	if !allowSave: return
	for panel in allPanels:
		if panel != null:
			panel.commitValue()
	@warning_ignore("shadowed_variable")
	var save = saveData.new()
	save.settings = settings
	save.tutorials = tutorials
	ResourceSaver.save(save, "user://userData.tres")


func _on_preset_menu_closed():
	setActiveEditor(generalPanel)


func _on_general_save_pressed():
	save()
	get_tree().change_scene_to_file("res://Scenes/session_screen.tscn")


func _on_generation_save_pressed():
	genPreMan.saveEdit()
	emit_signal("presetMenuClosed")


func _on_ses_open_pressed():
	genGroup.visible = false
	calGroup.visible = false
	sesGroup.visible = true
	graGroup.visible = false
	infGroup.visible = false
	scrollHandler.resetPosition()


func _on_gen_open_pressed():
	genGroup.visible = true
	calGroup.visible = false
	sesGroup.visible = false
	graGroup.visible = false
	infGroup.visible = false
	scrollHandler.resetPosition()


func _on_cal_open_pressed():
	genGroup.visible = false
	calGroup.visible = true
	sesGroup.visible = false
	graGroup.visible = false
	infGroup.visible = false
	scrollHandler.resetPosition()


func _on_gra_open_pressed():
	genGroup.visible = false
	calGroup.visible = false
	sesGroup.visible = false
	graGroup.visible = true
	infGroup.visible = false
	scrollHandler.resetPosition()


func _on_inf_open_pressed():
	genGroup.visible = false
	calGroup.visible = false
	sesGroup.visible = false
	graGroup.visible = false
	infGroup.visible = true
	scrollHandler.resetPosition()


func _on_val_open_pressed():
	valGroup.visible = true
	notGroup.visible = false
	tieGroup.visible = false
	triGroup.visible = false
	synGroup.visible = false
	timGroup.visible = false
	scrollHandler.resetPosition()


func _on_not_open_pressed():
	valGroup.visible = false
	notGroup.visible = true
	tieGroup.visible = false
	triGroup.visible = false
	synGroup.visible = false
	timGroup.visible = false
	scrollHandler.resetPosition()


func _on_tie_open_pressed():
	valGroup.visible = false
	notGroup.visible = false
	tieGroup.visible = true
	triGroup.visible = false
	synGroup.visible = false
	timGroup.visible = false
	scrollHandler.resetPosition()


func _on_tri_open_pressed():
	valGroup.visible = false
	notGroup.visible = false
	tieGroup.visible = false
	triGroup.visible = true
	synGroup.visible = false
	timGroup.visible = false
	scrollHandler.resetPosition()


func _on_syn_open_pressed():
	valGroup.visible = false
	notGroup.visible = false
	tieGroup.visible = false
	triGroup.visible = false
	synGroup.visible = true
	timGroup.visible = false
	scrollHandler.resetPosition()


func _on_tim_open_pressed():
	valGroup.visible = false
	notGroup.visible = false
	tieGroup.visible = false
	triGroup.visible = false
	synGroup.visible = false
	timGroup.visible = true
	scrollHandler.resetPosition()


func _on_au_c_button_pressed():
	save()
	get_tree().change_scene_to_file("res://Scenes/audio_calibrator.tscn")


func _on_in_c_button_pressed():
	save()
	get_tree().change_scene_to_file("res://Scenes/input_calibrator.tscn")


func _on_fee_button_pressed():
	tutorialMenu.showTutorial("Feedback")


func _on_man_button_pressed():
	tutorialMenu.showTutorial("Manual Count In")


func _on_wel_button_pressed():
	tutorialMenu.showTutorial("Welcome!")


func _on_general_info_pressed():
	tutorialMenu.showTutorial("General Settings")


func _on_generation_info_pressed():
	tutorialMenu.showTutorial("Generation Settings")


func _on_graphic_info_pressed():
	tutorialMenu.showTutorial("Graphics Settings")


func _on_tutorial_info_pressed():
	tutorialMenu.showTutorial("Tutorial Menu")


func _on_calibration_info_pressed():
	tutorialMenu.showTutorial("Calibration Settings")


func _on_value_info_pressed():
	tutorialMenu.showTutorial("Value Probabilities")


func _on_note_info_pressed():
	tutorialMenu.showTutorial("Note Probabilties")


func _on_tie_info_pressed():
	tutorialMenu.showTutorial("Tie Probabilities")


func _on_triplet_info_pressed():
	tutorialMenu.showTutorial("Triplet Probabilities")


func _on_syncopation_info_pressed():
	tutorialMenu.showTutorial("Syncopation Probabilities")


func _on_time_info_pressed():
	tutorialMenu.showTutorial("Time Signatures")
