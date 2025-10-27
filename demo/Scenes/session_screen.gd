extends Node2D

const divisionLookup = {
		4 as float: 0,
		2 as float: 1,
		1 as float: 2,
		.5: 3,
		.25: 4
		}

const numberLookup = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

var smallestDivIndex: int

const noteStockY: float = 1248
var sessionSettings: Dictionary = {}
enum {DIVISION, TUPLET, TUPLET_COMPONENT, NOTE, REST, BEAM, FSOLO_BEAM, BSOLO_BEAM, TIE, TIME_SIGNATURE, MEASURE_LINE, DOT}
enum {HOLD, RELEASE}
enum {FRONT, BACK}
enum {TOP, BOTTOM}

var VIEWPORT_WIDTH: float
var VIEWPORT_HEIGHT: float

var topPosition: Vector2
var noteParent: Node2D
@onready var metronome: ColorRect = %"Metronome"


var timingList: Array = []
var graphicList: Array = []
var visibleLines: Array = []
var fullTimings: Array = []
var fullInputs: Array = []
var finished: bool = false

var currentMeasureNumber: int = 0
var currentLineNumber: int =  0
var currentBeats: int
var currentBeatDivision: float
var currentInputIndex: int = 0

var gameStateFunc: Callable

var useMetronomeSound: bool

var allowSave: bool = false
var userSave: saveData
@onready var tutorialMenu := %"Tutorial Screen"
@onready var UI := %"Session UI"

# Tap indicator variables
var tapIndicators: Array = []
const TAP_INDICATOR_DURATION: float = 0.5
const TAP_INDICATOR_SIZE: float = 20.0

# Called when the node enters the scene tree for the first time.
func _ready():
	sessionSettings = util.getSessionSettings()
	userSave = util.loadSave()
	
	smallestDivIndex = util.getPrevious(sessionSettings.divProb, sessionSettings.divProb.size() - 1, func(input): return input > 0.0)
	updateViewDimensions()
	topPosition = Vector2(WPercentToPX(sessionSettings.sideMargin), HPercentToPX(sessionSettings.topMargin) + HPercentToPX(sessionSettings.buttonSize))
	noteParent = get_node("NotationContainer")
	metronome.setVolumePercent(sessionSettings.metronomeVolume)
	useMetronomeSound = sessionSettings.metronomeVolume > 0 && sessionSettings.metronomeOn
	UI.setMainButtonSize(HPercentToPX(sessionSettings.buttonSize))
	UI.setMainButtonPadding(sessionSettings.buttonMargin)
	refreshSequence()
	
	tutorialMenu.addTutorialData("Welcome!", "Welcome to Beat Master, an app where you can practice sightreading music. Tap anywere to begin, then tap out the rhythm on your screen. If you make a mistake, you can always use the button in the upper right corner to restart or go back a measure.", .6)
	tutorialMenu.addTutorialRef(userSave.tutorials, "welcome")
	tutorialMenu.addTutorialTapDetect()
	if userSave.tutorials.manualCountIn && sessionSettings.manualCountIn:
		tutorialMenu.addTutorialFunc(tutorialMenu.showTutorial, ["Manual Count In"])
		
		tutorialMenu.addTutorialData("Manual Count In", "You have manual count in turned on. To count in manually, simply tap on the screen with a consistent timing. You will need to tap once per beat for " + numberLookup[sessionSettings.countInMeasures] + (" measures." if sessionSettings.countInMeasures > 1 else " measure."), .5)
		tutorialMenu.addTutorialRef(userSave.tutorials, "manualCountIn")
	
	if userSave.tutorials.tapHint:
		tutorialMenu.addTutorialFunc(func(): gameStateFunc = BEGIN_COUNT_IN)
	
	if userSave.tutorials.welcome:
		tutorialMenu.showTutorial("Welcome!")
		gameStateFunc = func(): return
	elif userSave.tutorials.manualCountIn && sessionSettings.manualCountIn:
		tutorialMenu.showTutorial("Manual Count In")
		gameStateFunc = func(): return
	
	if userSave.tutorials.feedback:
		tutorialMenu.addTutorialData("Feedback", "When you have finished tapping out the rhythm, you are given feedback.\n
Blue and pink lines indicate notes and rests respectively. 
The notes you played are displayed below those lines. Red indicates an incorrect note while green indicates a correct note. 
The front and back of each note indicates whether it was started or ended at the right time.\n
You can switch between measures using the arrows on the right side of the screen.
If you want to correct a mistake, you can use the restart button (note that the restart button will restart the last measure in the line). You can also press the play button to generate new sheet music.", .9)
		tutorialMenu.addTutorialRef(userSave.tutorials, "feedback")
	
	allowSave = true

func refreshSequence():
	UI.hideCountdown()
	currentLineNumber = 0
	currentMeasureNumber = 0
	var startTime: int = Time.get_ticks_msec()
	fullTimings = []
	fullInputs = []
	for line in visibleLines:
		line.free()
	visibleLines = []
	graphicList = []
	generateSequence(sessionSettings.sequenceLength)
	currentMeasure = timingList[0]
	@warning_ignore("integer_division")
	print("Generation Time: " + str(Time.get_ticks_msec() - startTime) + "ms (" + str(round((Time.get_ticks_msec() - startTime) as float / 10) / 100) + "s) for " + str(sessionSettings.sequenceLength) + " measures")
	finished = false
	UI.hideStopButton()
	UI.hidePlayButton()
	BEGIN_COUNT_IN()


#COUNT_IN-SPECIFIC VARIABLES
var averageCountInInterval: float
var currentCountInBeat: int
var lastCountInBeatTime: int = -1
var countInStarted: bool = false

func BEGIN_COUNT_IN():
	lastCountInBeatTime = -1
	if userSave.tutorials.tapHint:
		UI.enableTapHint()
	UI.hideCountdown()
	audioPulseSizeList.clear()
	audioPulseTimeList.clear()
	if sessionSettings.showMetronome && sessionSettings.metronomeOn:
		metronome.visible = true
	else:
		metronome.visible = false
	loadVisibleLines(currentLineNumber, topPosition, VIEWPORT_HEIGHT, HPercentToPX(sessionSettings.notePadding), false)
	UI.hideScrollButtons()
	highlightMeasure(currentMeasureNumber, currentLineNumber)
	currentMeasure = timingList[currentMeasureNumber]
	currentLineGraphic = graphicList[currentLineNumber]
	averageCountInInterval = 0
	currentCountInBeat = 0
	var startSignature: Dictionary = currentMeasure.timeSignature
	currentBeats = startSignature.numerator
	currentBeatDivision = 4 as float / startSignature.denominator
	countInStarted = false
	if finished == true: UI.showStopButton()
	if sessionSettings.manualCountIn:
		gameStateFunc = COUNT_IN
	else:
		gameStateFunc = METRONOME_COUNT_IN


func COUNT_IN():
	if Input.is_action_just_pressed("tap"):
		createTapIndicator()
		UI.disableTapHint()
		UI.showCountdown()
		if !sessionSettings.highlightCurrentMeasure: clearHighlights()
		var currentCountInBeatTime: int = Time.get_ticks_msec()
		countInStarted = true
		currentCountInBeat += 1
		if (currentCountInBeat > 1):
			averageCountInInterval += (currentCountInBeatTime as float - lastCountInBeatTime as float) / (currentBeats as float  * sessionSettings.countInMeasures as float - 1)
		var tempLength: float = 300.0 if currentCountInBeat == 1 else averageCountInInterval as float * currentBeats as float * sessionSettings.countInMeasures as float / currentCountInBeat as float
		if (currentCountInBeat % currentBeats == 1):
			metronome.bigPulse(tempLength)
			UI.pulseCount(tempLength, 1)
			if useMetronomeSound: metronome.bigAudioPulse()
		else:
			metronome.pulse(tempLength)
			if currentCountInBeat == currentBeats * sessionSettings.countInMeasures:
				UI.pulseCount(tempLength, 0)
			else:
				UI.pulseCount(tempLength, currentCountInBeat % currentBeats if currentCountInBeat % currentBeats != 0 else currentBeats)
			if useMetronomeSound: metronome.audioPulse()
		lastCountInBeatTime = currentCountInBeatTime
		
		if (currentCountInBeat >= currentBeats * sessionSettings.countInMeasures):
			BEGIN_TAP()
	
	elif lastCountInBeatTime != -1 && Time.get_ticks_msec() - lastCountInBeatTime > 4000:
		BEGIN_COUNT_IN()


#METRONOME_COUNT_IN-specific variables
var nextCountInPulse: int

func METRONOME_COUNT_IN():
	if Input.is_action_just_pressed("tap") && !countInStarted:
		createTapIndicator()
		UI.disableTapHint()
		UI.showCountdown()
		if !sessionSettings.highlightCurrentMeasure: clearHighlights()
		var currentCountInBeatTime: int = Time.get_ticks_msec()
		countInStarted = true
		averageCountInInterval = 60.0 / sessionSettings.BPM as float * 1000.0
		unitDurationLength = round(averageCountInInterval as float * currentMeasure.timeSignature.denominator as float / 4.0)
		metronome.bigPulse(averageCountInInterval)
		UI.pulseCount(averageCountInInterval, 1)
		if useMetronomeSound:
			var signature = currentMeasure.timeSignature
			var sTime = currentCountInBeatTime
			for meas in range(sessionSettings.countInMeasures):
				generateAudioPulses(sTime, signature)
				sTime = audioPulseTimeList[-1] + averageCountInInterval
		@warning_ignore("narrowing_conversion")
		nextCountInPulse = currentCountInBeatTime + averageCountInInterval
		currentCountInBeat = 1
	if countInStarted:
		currentTime = Time.get_ticks_msec()
		if useMetronomeSound && !audioPulseTimeList.is_empty() && currentTime >= audioPulseTimeList[0]:
			advanceAudioPulses()
		if currentTime >= nextCountInPulse:
			currentCountInBeat += 1
			if currentCountInBeat % currentBeats == 1:
				metronome.bigPulse(averageCountInInterval)
			else:
				metronome.pulse(averageCountInInterval)
			if currentCountInBeat == currentBeats * sessionSettings.countInMeasures:
				UI.pulseCount(averageCountInInterval, 0)
			else:
				UI.pulseCount(averageCountInInterval, currentCountInBeat % currentBeats if currentCountInBeat % currentBeats != 0 else currentBeats)
			lastCountInBeatTime = nextCountInPulse
			nextCountInPulse += averageCountInInterval as int
			if (currentCountInBeat >= currentBeats * sessionSettings.countInMeasures):
				BEGIN_TAP()


func generateAudioPulses(startTime: int, timeSignature: Dictionary):
	var reps: int = timeSignature.numerator
	var timeAdded: float = (4.0 / timeSignature.denominator as float) * unitDurationLength
	var currentT: float = timeAdded
	var beat: int = 1
	audioPulseSizeList.append(true)
	audioPulseTimeList.append(startTime + sessionSettings.audioCalibration)
	while beat < reps:
		audioPulseSizeList.append(false)
		audioPulseTimeList.append(startTime + round(currentT) as int + sessionSettings.audioCalibration)
		currentT += timeAdded
		beat += 1


func advanceAudioPulses():
	if !audioPulseTimeList.is_empty():
		if audioPulseSizeList[0]:
			metronome.bigAudioPulse()
		else:
			metronome.audioPulse()
		audioPulseSizeList.pop_front()
		audioPulseTimeList.pop_front()

# TAP-specific variables
var unitDurationLength: float = 750 #in milliseconds
var beatLength: float = 750 #in milliseconds
var measureStartTime: float
var measureEndTime: float
var nextPulseTime: int

var audioPulseTimeList: Array = []
var audioPulseSizeList: Array = []

var currentTime: int
var currentBeat: int
var currentMeasure: measureTimingData
var currentLineGraphic: lineGraphicData

var previousAction

var clearUsed: bool = false

var currentActionIndex: int
var currentAction
var currentActionStartTime: float
var currentActionEndTime: float

var nextAction
var nextNextAction


func BEGIN_TAP():
	UI.hideScrollButtons()
	beatLength = averageCountInInterval
	print("Detected BPM: ~" + str(round(60 / (beatLength / 1000))))
	unitDurationLength = beatLength / currentBeatDivision
	measureStartTime = lastCountInBeatTime + beatLength as int
	nextPulseTime = measureStartTime as int
	generateAudioPulses(round(measureStartTime), currentMeasure.timeSignature)
	measureEndTime = currentMeasure.resetTime * unitDurationLength + measureStartTime
	if currentMeasureNumber < sessionSettings.sequenceLength - 1: generateAudioPulses(round(measureEndTime), timingList[currentMeasureNumber + 1].timeSignature)
	currentActionStartTime = measureStartTime
	if currentMeasure.timings.is_empty():
		var cActionMeasure: measureTimingData = timingList[util.getPrevious(timingList, currentMeasureNumber, func(measure): return !measure.timings.is_empty())]
		currentAction = fullTimings[cActionMeasure.lastActionIndex]
	else:
		currentAction = currentMeasure.timings.front()
		currentActionIndex = currentMeasure.firstActionIndex
	updateNextActions()
	
	clearUsed = false
	
	currentBeat = 1
	gameStateFunc = TAP


func updateNextActions():
	if fullTimings.size() - 1 <= currentActionIndex:
		nextAction = null
		nextNextAction = null
		currentActionEndTime = measureStartTime + currentMeasure.resetTime * unitDurationLength
	else:
		nextAction = fullTimings[currentActionIndex + 1]
		currentActionEndTime = (nextAction.gStartTime as float - currentMeasure.gStartTime as float) * unitDurationLength + measureStartTime
		if fullTimings.size() - 2 <= currentActionIndex:
			nextNextAction = null
		else:
			nextNextAction = fullTimings[currentActionIndex + 2]


func TAP():
	currentTime = Time.get_ticks_msec()
	
	if useMetronomeSound && !audioPulseTimeList.is_empty()  && currentTime >= audioPulseTimeList[0]:
		advanceAudioPulses()
	
	if (currentTime >= measureEndTime):
		if (currentMeasureNumber < timingList.size() - 1):
			currentMeasureNumber += 1
			currentMeasure = timingList[currentMeasureNumber]
			clearInput(currentMeasureNumber)
			currentBeatDivision = 4 as float / currentMeasure.timeSignature.denominator as float
			beatLength = unitDurationLength * currentBeatDivision
			measureStartTime = currentTime
			measureEndTime = currentMeasure.resetTime * unitDurationLength + measureStartTime
			currentBeat = 1
			nextPulseTime = measureStartTime as int
			if useMetronomeSound && currentMeasureNumber < timingList.size() - 1:
				generateAudioPulses(round(measureEndTime), timingList[currentMeasureNumber + 1].timeSignature)
			if !currentLineGraphic.containsMeasure(currentMeasureNumber):
				cycleLinesForward(false)
			if sessionSettings.highlightCurrentMeasure: highlightMeasure(currentMeasureNumber, currentLineNumber)
			clearUsed = false
		else:
			metronome.visible = false
	
	
	if (currentTime >= nextPulseTime):
		if !sessionSettings.showMetronome || !sessionSettings.metronomeOn:
			metronome.visible = false
		if currentBeat == 1:
			metronome.bigPulse(beatLength)
		else:
			metronome.pulse(beatLength)
		nextPulseTime = measureStartTime + currentBeat * beatLength as int 
		currentBeat += 1
	
	
	if (currentTime >= currentActionEndTime):
		previousAction = currentAction
		currentActionIndex += 1
		currentAction = nextAction
		updateNextActions()
	
	
	if (Input.is_action_just_pressed("tap") || Input.is_action_just_released("tap")):
		if Input.is_action_just_pressed("tap"):
			createTapIndicator()
		if !clearUsed:
			clearInput(currentMeasureNumber)
			currentInputIndex = 0 if fullInputs.is_empty() else (inputBSearch(currentMeasure.gStartTime) + 1)
			clearUsed = true
		var inputType: int
		var relativeTime: float = (currentTime - measureStartTime + sessionSettings.inputCalibration) as float / unitDurationLength as float
		if  relativeTime > -2.0 / currentMeasure.timeSignature.denominator as float:
			inputType = HOLD if Input.is_action_just_pressed("tap") else RELEASE
			if currentInputIndex == 0 || inputType != fullInputs[currentInputIndex - 1].action:
				if inputType == RELEASE && currentActionIndex != 0 && !fullTimings.is_empty():
					var lastInput: Dictionary = fullInputs.back()
					var thisInput: Dictionary = currentMeasure.newUserTiming(currentInputIndex, relativeTime, inputType, lastInput.nearestAction.other)
					thisInput.other = lastInput
					lastInput.other = thisInput
					currentInputIndex += 1
				elif inputType == HOLD:
					currentMeasure.newUserTiming(currentInputIndex, relativeTime, inputType, getNearestAction(currentMeasure.gStartTime + relativeTime, inputType))
					currentInputIndex += 1
	
	if currentTime >= measureEndTime && !Input.is_action_pressed("tap"):
		finished = true
		BEGIN_FEEDBACK(0)


func getNearestAction(gTime: float, target: int):
	var nearList: Array = [previousAction, currentAction, nextAction, nextNextAction]
	var difList: Array = []
	
	if previousAction != null && previousAction.action == target:
		difList.append(abs(previousAction.gStartTime - gTime))
	else:
		difList.append(-1)
	
	if currentAction != null && currentAction.action == target:
		difList.append(abs(currentAction.gStartTime - gTime))
	else:
		difList.append(-1)
	
	if nextAction != null && nextAction.action == target:
		difList.append(abs(nextAction.gStartTime - gTime))
	else:
		difList.append(-1)
	
	if nextNextAction != null && nextNextAction.action == target:
		difList.append(abs(nextNextAction.gStartTime - gTime))
	else:
		difList.append(-1)
	
	var d: int = 0
	while d < difList.size():
		if difList[d] == -1:
			difList.remove_at(d)
			nearList.remove_at(d)
		else:
			d += 1
	var nearest = null if nearList.is_empty() else nearList.back()
	d = 0
	var check: Dictionary
	while d < nearList.size() - 1:
		check = nearList[d]
		if abs(check.gStartTime - gTime) < abs(nearest.gStartTime - gTime):
			nearest = check
		d += 1
	return nearest


func BEGIN_FEEDBACK(lineNumber: int):
	UI.hideCountdown()
	UI.hideStopButton()
	metronome.visible = false
	clearHighlights()
	UI.showScrollButtons()
	UI.showPlayButton()
	UI.flashButtons()
	if userSave.tutorials.feedback:
		tutorialMenu.addTutorialFunc(UI.flashButtons)
		tutorialMenu.showTutorial("Feedback")
	currentLineNumber = lineNumber
	currentLineGraphic = graphicList[lineNumber]
	currentMeasureNumber = currentLineGraphic.lastMeasureNum
	currentMeasure = timingList[currentMeasureNumber]
	for l in visibleLines:
		l.free()
	visibleLines = []
	gradeInput()
	loadVisibleLines(lineNumber, topPosition, VIEWPORT_HEIGHT, HPercentToPX(sessionSettings.notePadding), true)
	gameStateFunc = FEEDBACK


func FEEDBACK():
	if Input.is_action_just_pressed("tap"):
		createTapIndicator()
		UI.flashButtons()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	gameStateFunc.call()
	updateTapIndicators(_delta)

func createTapIndicator():
	var tapPosition = get_global_mouse_position()
	
	var indicator = ColorRect.new()
	indicator.color = Color(1.0, 0.3, 0.3, 0.8)  # Red with transparency
	indicator.size = Vector2(TAP_INDICATOR_SIZE, TAP_INDICATOR_SIZE)
	indicator.position = tapPosition - indicator.size / 2
	
	# Make it circular by setting corner radius
	var style = StyleBoxFlat.new()
	style.bg_color = indicator.color
	style.corner_radius_top_left = TAP_INDICATOR_SIZE / 2
	style.corner_radius_top_right = TAP_INDICATOR_SIZE / 2
	style.corner_radius_bottom_left = TAP_INDICATOR_SIZE / 2
	style.corner_radius_bottom_right = TAP_INDICATOR_SIZE / 2
	
	indicator.add_theme_stylebox_override("panel", style)
	
	add_child(indicator)
	
	# Store indicator with creation time
	tapIndicators.append({
		"node": indicator,
		"time_left": TAP_INDICATOR_DURATION,
		"initial_color": indicator.color
	})

func updateTapIndicators(delta: float):
	for i in range(tapIndicators.size() - 1, -1, -1):
		var indicator_data = tapIndicators[i]
		indicator_data.time_left -= delta
		
		if indicator_data.time_left <= 0:
			# Remove expired indicator
			indicator_data.node.queue_free()
			tapIndicators.remove_at(i)
		else:
			# Fade out the indicator
			var alpha = indicator_data.time_left / TAP_INDICATOR_DURATION
			var color = indicator_data.initial_color
			color.a = alpha * 0.8
			
			# Update the style with new alpha
			var style = StyleBoxFlat.new()
			style.bg_color = color
			style.corner_radius_top_left = TAP_INDICATOR_SIZE / 2
			style.corner_radius_top_right = TAP_INDICATOR_SIZE / 2
			style.corner_radius_bottom_left = TAP_INDICATOR_SIZE / 2
			style.corner_radius_bottom_right = TAP_INDICATOR_SIZE / 2
			
			indicator_data.node.add_theme_stylebox_override("panel", style)


func gradeInput():
	for input in fullInputs:
		if input.nearestAction == null:
			input.score = 0
		else:
			var difference: float = abs(input.gStartTime - input.nearestAction.gStartTime)
			var leniency: float
			if input.action == HOLD:
				leniency = sessionSettings.pressWindow
			else:
				leniency = sessionSettings.releaseWindow
			if difference >= leniency:
				input.score = 0
			else:
				input.score = 100 * ((leniency - difference) / leniency)
	
	var lastNearestHold
	var holdGroup: Array = []
	var lastNearestRelease
	var releaseGroup: Array = []
	var inputGroups: Array = []
	for input in fullInputs:
		if input.action == HOLD:
			if lastNearestHold == input.nearestAction:
				holdGroup.append(input)
			else:
				inputGroups.append(holdGroup)
				holdGroup = [input]
				lastNearestHold = input.nearestAction
		if input.action == RELEASE:
			if lastNearestRelease == input.nearestAction:
				releaseGroup.append(input)
			else:
				inputGroups.append(releaseGroup)
				releaseGroup = [input]
				lastNearestRelease = input.nearestAction
	inputGroups.append(holdGroup)
	inputGroups.append(releaseGroup)
	for group in inputGroups:
		if !group.is_empty():
			var i: int = 0
			var greatestScore: float = 0
			var greatestIndex: int = 0
			while i < group.size():
				if group[i].score > greatestScore:
					greatestScore = group[i].score
					greatestIndex = i
				i += 1
			var greatestInput = group[greatestIndex]
			greatestInput.parentMeasure.score += greatestScore
			group.remove_at(greatestIndex)
			if greatestInput.action == HOLD:
				for input in group:
					input.score = -10
					input.parentMeasure.score -= 10


var highlight: ColorRect
var highlightExists: bool = false
func highlightMeasure(measureNumber, lineNumber: int = 0):
	clearHighlights()
	var lineNum = util.getNext(graphicList, lineNumber, func(line: lineGraphicData): return line.containsMeasure(measureNumber))
	if lineNum == -1: return
	var graphicLineNum = util.getNext(visibleLines, 0, func(line: Node2D): return line.lineNumber == lineNum)
	if graphicLineNum == -1: return
	var line: lineGraphicData = graphicList[lineNum]
	var graphicLine: Node2D = visibleLines[graphicLineNum]
	var measure = line.childMeasures[measureNumber - line.firstMeasureNum]
	highlight = ColorRect.new()
	highlight.color = Color(0.3, 0.7, 1.0, 1.0)
	highlight.size = Vector2(measure.dimensions.x, 10)
	highlight.position = Vector2(measure.position.x, line.dimensions.y + 15)
	graphicLine.add_child(highlight)
	highlightExists = true


func clearHighlights():
	if highlight == null:
		highlightExists = false
	if highlightExists: 
		highlight.free()
		highlightExists = false


func _on_session_ui_stop_pressed():
	BEGIN_FEEDBACK(currentLineNumber)


func _on_session_ui_restart_pressed():
	if (gameStateFunc == COUNT_IN || gameStateFunc == METRONOME_COUNT_IN) && !countInStarted:
		if currentMeasureNumber > 0:
			currentMeasureNumber -= 1
			if !graphicList[currentLineNumber].containsMeasure(currentMeasureNumber):
				cycleLinesBackward(false)
	elif gameStateFunc == FEEDBACK:
		for l in visibleLines:
			l.free()
		visibleLines = []
		loadVisibleLines(currentLineNumber, topPosition, VIEWPORT_HEIGHT, HPercentToPX(sessionSettings.notePadding), false)
	if sessionSettings.highlightCurrentMeasure:
		highlightMeasure(currentMeasureNumber, currentLineNumber)
	currentMeasure = timingList[currentMeasureNumber]
	BEGIN_COUNT_IN()


func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED || what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if gameStateFunc == COUNT_IN || gameStateFunc == TAP:
			BEGIN_COUNT_IN()
	
	if what == NOTIFICATION_WM_CLOSE_REQUEST || what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save()


func inputBSearch(targetGTime: float) -> int:
	var uBound: int = fullInputs.size() - 1
	var lBound: int = 0
	var cIndex: int
	var cGTime: float
	while uBound > lBound:
		cIndex = floor((uBound + lBound) as float / 2)
		cGTime = fullInputs[cIndex].gStartTime
		if cGTime < targetGTime:
			lBound = cIndex + 1
		elif cGTime > targetGTime:
			uBound = cIndex - 1
		else:
			lBound = cIndex
			break
	return lBound


func clearInput(targetNumber: int):
	if fullInputs.is_empty(): return
	var measure: measureTimingData = timingList[targetNumber]
	var startIndex: int = inputBSearch(measure.gStartTime)
	
	if fullInputs[startIndex].parentMeasure != measure:
		if startIndex < fullInputs.size() -  1 && fullInputs[startIndex + 1].parentMeasure == measure:
			startIndex += 1
		else:
			return
	
	if targetNumber > 0 && startIndex > 0 && fullInputs[startIndex].other == fullInputs[startIndex - 1]:
		timingList[targetNumber - 1].newUserTiming(startIndex - 1, timingList[targetNumber - 1].resetTime, RELEASE, fullInputs[startIndex - 1].nearestAction.other)
		startIndex += 1
	
	var endIndex: int = startIndex + 1
	while endIndex < fullInputs.size():
		if fullInputs[endIndex].parentMeasure != measure:
			break
		endIndex += 1
	endIndex -= 1
	
	if targetNumber < timingList.size() - 1 && startIndex < fullInputs.size() - 1 && fullInputs[endIndex].other == fullInputs[endIndex + 1]:
		fullInputs.remove_at(endIndex + 1)
		timingList[targetNumber + 1].userTimings.pop_front()
	
	measure.clearInput()
	for r in range(endIndex - startIndex + 1):
		fullInputs.remove_at(startIndex)


func _on_session_ui_settings_pressed():
	save()
	get_tree().change_scene_to_file("res://Scenes/settings_screen.tscn")


func _on_session_ui_play_pressed():
	refreshSequence()


func _on_session_ui_scroll_down_pressed():
	if currentLineNumber < graphicList.size() - 1:
		cycleLinesForward(true, true)
	currentMeasureNumber = currentLineGraphic.lastMeasureNum
	currentMeasure = timingList[currentMeasureNumber]


func _on_session_ui_scroll_up_pressed():
	if currentLineNumber > 0:
		cycleLinesBackward(true)
	currentMeasureNumber = currentLineGraphic.lastMeasureNum
	currentMeasure = timingList[currentMeasureNumber]


func cycleLinesBackward(showFeedback: bool):
	if (currentLineNumber > 0):
		currentLineNumber -= 1
		currentLineGraphic = graphicList[currentLineNumber]
		loadVisibleLines(currentLineNumber, topPosition, VIEWPORT_HEIGHT, HPercentToPX(sessionSettings.notePadding), showFeedback)

func cycleLinesForward(showFeedback: bool, forceTeleport: bool = false):
	currentLineNumber += 1
	currentLineGraphic = graphicList[currentLineNumber]
	if currentLineNumber > graphicList.size(): return
	visibleLines.front().queue_free()
	visibleLines.pop_front()
	loadVisibleLines(currentLineNumber, topPosition, VIEWPORT_HEIGHT + visibleLines[0].dimensions.y + HPercentToPX(sessionSettings.notePadding), HPercentToPX(sessionSettings.notePadding), showFeedback)
	if !visibleLines.is_empty():
		visibleLines[0].teleToPosition(topPosition)
		if visibleLines.size() > 1:
			var smooth = !visibleLines[1].is_moving()
			for v in range(visibleLines.size() - 1):
				var currentGraphicLine = visibleLines[v + 1]
				var previousGraphicLine = visibleLines[v]
				var newDestination = previousGraphicLine.destinationPosition
				newDestination.y += previousGraphicLine.dimensions.y + HPercentToPX(sessionSettings.notePadding)
				if smooth && !forceTeleport:
					currentGraphicLine.slideToPosition(newDestination, beatLength)
				else:
					currentGraphicLine.teleToPosition(newDestination)


func loadVisibleLines(firstLineNumber: int, startPosition: Vector2, viewBoxY: float, linePadding: float, showFeedback: bool):
	if visibleLines.is_empty():
		var currentPosition = startPosition
		var loadLineNumber = firstLineNumber
		while loadLineNumber < graphicList.size():
			var lineData = graphicList[loadLineNumber]
			var lineGraphic = loadLine(lineData, noteParent, currentPosition, showFeedback)
			visibleLines.append(lineGraphic)
			currentPosition.y += lineGraphic.dimensions.y + linePadding
			if (currentPosition.y > viewBoxY):
				break
			loadLineNumber += 1
		return
	else:
		if firstLineNumber >= visibleLines.front().lineNumber:
			var newPosition = Vector2(startPosition.x, visibleLines.back().destinationPosition.y + visibleLines.back().dimensions.y + linePadding)
			var addedLineNumber = visibleLines.back().lineNumber + 1
			if addedLineNumber >= graphicList.size():
				return
			var lineData = graphicList[visibleLines.back().lineNumber + 1]
			if newPosition.y - startPosition.y <= viewBoxY:
				visibleLines.append(loadLine(lineData, noteParent, newPosition, showFeedback))
		elif firstLineNumber < visibleLines.front().lineNumber && firstLineNumber >= 0: 
			for l in visibleLines:
				l.queue_free()
			visibleLines = []
			loadVisibleLines(firstLineNumber, startPosition, viewBoxY, linePadding, showFeedback)



@warning_ignore("shadowed_variable_base_class")
func loadLine(lineData: lineGraphicData, parent, position: Vector2, showFeedback: bool):
	var line = graphicLine.new(lineData, position)
	parent.add_child(line)
	for measureData in lineData.childMeasures:
		var measure = Node2D.new()
		line.add_child(measure)
		measure.position = measureData.position
		for graphicData in measureData.graphicList:
			var graphic = TextureRect.new()
			if graphicData.path != "":
				measure.add_child(graphic)
				graphic.texture = load(graphicData.path)
				graphic.position = graphicData.position
				graphic.scale = graphicData.scale
		if showFeedback:
			var lastSignificantIndex = util.getPrevious(timingList, measureData.measureNumber - 1, func(tdata): return tdata.timings.size() > 0)
			var lastSignificantAction
			if lastSignificantIndex == -1:
				lastSignificantAction = 1
			else:
				lastSignificantAction = timingList[lastSignificantIndex].timings.back().action
			
			var lastSignificantInputIndex = util.getPrevious(timingList, measureData.measureNumber - 1, func(tdata): return tdata.userTimings.size() > 0)
			var lastSignificantInput
			if lastSignificantInputIndex == -1:
				lastSignificantInput = null
			else:
				if timingList[lastSignificantInputIndex].userTimings.is_empty():
					lastSignificantInput = null
				else:
					lastSignificantInput = timingList[lastSignificantInputIndex].userTimings.back()
			line.add_child(feedbackDisplay.new(measureData.timingData, 
					Vector2(measureData.measureStartX + measure.position.x, lineData.dimensions.y + 5),
					Vector2(measureData.dimensions.x - measureData.measureStartX, HPercentToPX(sessionSettings.feedbackDisplayHeight)), 
					lastSignificantAction,
					lastSignificantInput))
	if showFeedback:
		line.prepareForFeedback(HPercentToPX(sessionSettings.feedbackDisplayHeight))
	else:
		line.prepareForTap()
	return line


func generateSequence(length): ## chance is 100% for change
	timingList = []
	var previousTimeSignature = null
	var currentTimeSignature 
	var nextTimeSignature = util.grabBagProbability(sessionSettings.sigList)
	var lastActionIsHold: bool = false
	var lastActionIsTie: bool = false
	var lastType: int = -1
	var currentMeasureTime: float = 0
	@warning_ignore("shadowed_variable")
	var currentMeasure: Array = []
	var nextMeasure = generateMeasure(nextTimeSignature.numerator, nextTimeSignature.denominator)
	@warning_ignore("shadowed_variable")
	var currentLine = lineGraphicData.new(0, false, VIEWPORT_WIDTH - (2 * WPercentToPX(sessionSettings.sideMargin)), VIEWPORT_HEIGHT - HPercentToPX(sessionSettings.topMargin))
	for measure in range(length):
		var currentMeasureGraphics: measureGraphicData = measureGraphicData.new(measure, VIEWPORT_HEIGHT / noteStockY * sessionSettings.noteScale)
		previousTimeSignature = currentTimeSignature
		currentTimeSignature = nextTimeSignature
		currentMeasure = nextMeasure
		if (randf() < sessionSettings.sigChangeProb && sessionSettings.sigList.size() > 1):
			nextTimeSignature = util.grabBagProbability(sessionSettings.sigList.filter(func(sig): return sig != currentTimeSignature))
		
		if currentTimeSignature != previousTimeSignature:
			currentMeasureGraphics.addGraphic(util.graphicData.measureLine, -1, MEASURE_LINE, {"xIncrimentRatio": .1})
			currentMeasureGraphics.addGraphic(util.graphicData.timeSignature[currentTimeSignature.numerator as int], -1, TIME_SIGNATURE, {})
			currentMeasureGraphics.addGraphic(util.graphicData.timeSignature[currentTimeSignature.denominator as int], -1, TIME_SIGNATURE,
					{"offset": Vector2(0, util.graphicData.timeSignature[currentTimeSignature.numerator as int].dimensions.y),
					"xIncrimentRatio": 1})
		nextMeasure = null if measure >= length - 1 else generateMeasure(nextTimeSignature.numerator, nextTimeSignature.denominator)
		
		if nextMeasure != null:
			var endNoteIndex: int = util.getPrevious(currentMeasure, currentMeasure.size() - 1, func(note): return note.type == NOTE || note.type == REST)
			if endNoteIndex != -1 && currentMeasure[endNoteIndex].type == NOTE:
				var frontNoteIndex: int = util.getNext(nextMeasure, 0, func(note): return note.type == NOTE || note.type == REST)
				if frontNoteIndex != -1 && nextMeasure[frontNoteIndex].type == NOTE && randf() < sessionSettings.tieOverMeasureProb:
					currentMeasure[endNoteIndex].connect = true
					currentMeasure[endNoteIndex].drawConnect = true
			
			if endNoteIndex != -1 && currentMeasure[endNoteIndex].type == REST:
				var frontNoteIndex: int = util.getNext(nextMeasure, 0, func(note): return note.type == NOTE || note.type == REST)
				if frontNoteIndex != -1 && nextMeasure[frontNoteIndex].type == REST:
					currentMeasure[endNoteIndex].restConnect = true
		
		var currentTiming: float = 0
		var measureTimings = measureTimingData.new(currentMeasureTime, fullTimings, fullInputs, currentTimeSignature, 0)
		var start: Dictionary = {}
		var end: Dictionary = {}
		for action in currentMeasure:
			if (action.type == NOTE || action.type == DOT):
				if !(lastActionIsTie && lastType == NOTE):
					if lastActionIsHold:
						start = fullTimings.back()
						end = measureTimings.newTiming(currentTiming, RELEASE)
						start.other = end
						end.other = start
					measureTimings.newTiming(currentTiming, HOLD)
				lastActionIsHold = true
				lastActionIsTie = action.connect
				lastType = NOTE
				currentTiming += action.division * action.timeMultiplier
			elif (action.type == REST):
				if !(lastActionIsTie && lastType == action.type):
					if fullTimings.is_empty():
						measureTimings.newTiming(currentTiming, RELEASE)
					else:
						start = fullTimings.back()
						end = measureTimings.newTiming(currentTiming, RELEASE)
						start.other = end
						end.other = start
				lastActionIsHold = false
				lastActionIsTie = action.restConnect
				lastType = REST
				currentTiming += action.division * action.timeMultiplier
		if measure == length - 1 && fullTimings.back().action == HOLD:
			start = fullTimings.back()
			end = measureTimings.newTiming(currentTiming, RELEASE)
			start.other = end
			end.other = start
		measureTimings.resetTime = currentTiming
		timingList.append(measureTimings)
		currentMeasureTime += currentTiming
		
		currentMeasureGraphics.addGraphic(util.graphicData.measureLine, -1, MEASURE_LINE, {})
		for a in range(currentMeasure.size()):
			var action = currentMeasure[a]
			if action.type == NOTE:
				var useBeamGraphic: bool = false
				if action.frontBeams > 0 && action.beamsFromFront > 0:
					useBeamGraphic = true
					if action.frontBeams > action.beamsFromFront:
						currentMeasureGraphics.addGraphic(util.graphicData.beam[action.frontBeams], action, FSOLO_BEAM, {})
				if action.backBeams > 0 && action.beamsFromBack > 0:
					useBeamGraphic = true
					if action.backBeams > action.beamsFromBack:
						currentMeasureGraphics.addGraphic(util.graphicData.beam[action.backBeams], action, BSOLO_BEAM, {})
					currentMeasureGraphics.addGraphic(util.graphicData.beam[action.beamsFromBack if action.beamsFromBack < action.backBeams else action.backBeams], action, BEAM, {})
				if action.drawConnect:
					currentMeasureGraphics.addGraphic(util.graphicData.tie, action, TIE, {})
				currentMeasureGraphics.addGraphic(util.graphicData.note["beamed" if useBeamGraphic else "unbeamed"][action.division], action, NOTE, {})
				for d in range(action.dots):
					currentMeasureGraphics.addGraphic(util.graphicData.dot, action, DOT, {})
			elif action.type == REST:
				currentMeasureGraphics.addGraphic(util.graphicData.rest[action.division], action, REST, {})
			elif action.type == TUPLET:
				currentMeasureGraphics.addGraphic(util.graphicData.tuplet.placeHolder, action, TUPLET, {})
		currentMeasureGraphics.prepare(currentMeasure)
		currentMeasureGraphics.linkTimingData(measureTimings)
		
		if !currentLine.addMeasure(currentMeasureGraphics):
			currentLine.prepare()
			graphicList.append(currentLine)
			currentLine = lineGraphicData.new(graphicList.size(), currentLine.tieAtEnd, VIEWPORT_WIDTH - (2 * WPercentToPX(sessionSettings.sideMargin)), VIEWPORT_HEIGHT - HPercentToPX(sessionSettings.topMargin))
			currentLine.addMeasure(currentMeasureGraphics)
	if (currentLine.childMeasures.size() > 0):
		currentLine.prepare()
		graphicList.append(currentLine)


class lineGraphicData:
	var lineNumber: int
	var firstMeasureNum: int
	var lastMeasureNum: int
	var childMeasures = []
	var maxWidth
	var maxHeight
	var dimensions = Vector2.ZERO
	var tieAtEnd = false
	var tieFront
	var upperOffset = 0
	var rescaled = false
	var rescaleFactor = 1
	
	@warning_ignore("shadowed_variable")
	func _init(lineNumber, tieFront, maxWidth, maxHeight):
		self.lineNumber = lineNumber
		self.maxWidth  = maxWidth
		self.maxHeight = maxHeight
		self.tieFront = tieFront
	
	
	func addMeasure(measure: measureGraphicData):
		if dimensions.x + measure.dimensions.x * rescaleFactor > maxWidth || measure.dimensions.y * rescaleFactor > maxHeight:
			if childMeasures.is_empty():
				rescaled = true
				var widthRatio = maxWidth / measure.dimensions.x
				var heightRatio = maxHeight / measure.dimensions.y
				rescaleFactor = widthRatio if widthRatio < heightRatio else heightRatio
			else:
				return false
		if rescaled:
			measure.scale *= rescaleFactor
			measure.dimensions *= rescaleFactor
			measure.minYPos *= rescaleFactor
			measure.maxYPos *= rescaleFactor
			for childGraphic in measure.graphicList:
				childGraphic.position *= rescaleFactor
				childGraphic.position = floor(childGraphic.position)
				childGraphic.scale *= rescaleFactor
		childMeasures.append(measure)
		measure.position.x = dimensions.x
		if (abs(measure.minYPos) > upperOffset):
			upperOffset = abs(measure.minYPos)
		if (dimensions.y < measure.dimensions.y):
			dimensions.y = floor(measure.dimensions.y)
		dimensions.x += floor(measure.dimensions.x)
		tieAtEnd = measure.tieAtEnd
		return true
	
	
	func containsMeasure(checkNumber: int):
		return checkNumber <= lastMeasureNum && checkNumber >= firstMeasureNum
	
	
	func prepare(): #add a measure line to end, scale ties, update tie at end variable, update tie at beginning
		firstMeasureNum = childMeasures.front().measureNumber
		lastMeasureNum = childMeasures.back().measureNumber
		
		for m in range(childMeasures.size() - 1):
			childMeasures[m].position.y += upperOffset
			if childMeasures[m].tieAtEnd:
				var measure = childMeasures[m]
				var tie = measure.tieAtEndGraphic
				var targetMeasure = childMeasures[m + 1]
				var targetNotation = targetMeasure.startingNotation
				var targetX = targetMeasure.position.x + targetNotation.position.x + targetNotation.graphicData.frontMarker * targetNotation.scale.x
				var tieX = measure.position.x + tie.position.x
				var xDistance = targetX - tieX
				tie.scale.x = xDistance / tie.graphicData.dimensions.x * measure.scale
		childMeasures.back().position.y += upperOffset
		
		if tieFront:
			var firstMeasure: measureGraphicData = childMeasures.front()
			var frontTie = firstMeasure.addGraphic(util.graphicData.tie, null, TIE, {})
			firstMeasure.placeAtMarker(frontTie, firstMeasure.startingNotation, BACK, FRONT, BOTTOM)
		
		tieAtEnd = childMeasures.back().tieAtEnd
		var endLine = childMeasures.back().addGraphic(util.graphicData.measureLine, -1, MEASURE_LINE, {"xIncrimentRatio": 0})
		var last = childMeasures.back()
		if (tieAtEnd): last.stretchBetween(last.tieAtEndGraphic, last.tieAtEndParent, endLine, FRONT, BACK, BOTTOM)
		
		for m in childMeasures:
			for g in m.graphicList:
				g.erase("graphicData")
				g.erase("type")


class measureGraphicData:
	var measureNumber: int
	var graphicList = []
	var dimensions = Vector2.ZERO
	var maxYPos = 0
	var minYPos = 0
	var position = Vector2.ZERO
	var scale
	var startingNotation
	var tieAtEnd = false
	var tieAtEndGraphic
	var tieAtEndParent
	var timingData: measureTimingData
	var measureStartX: int
	
	@warning_ignore("shadowed_variable")
	func _init(number, scale: float):
		self.measureNumber = number
		self.scale = scale
	
	func addGraphic(graphic: Dictionary, baseNotation, type: int, overrides: Dictionary) -> Dictionary:
		var relevantData = graphic.duplicate()
		for key in overrides.keys():
			relevantData[key] = overrides[key]
		relevantData.dimensions *= scale
		relevantData.offset *= scale
		var output = {
				"type": type, 
				"path": relevantData.path,
				"position": Vector2(floor(dimensions.x + relevantData.offset.x), floor(relevantData.offset.y)),
				"scale": Vector2(scale, scale),
				"baseNotation": baseNotation,
				"graphicData": relevantData}
		graphicList.append(output)
		if relevantData.offset.y < minYPos:
			minYPos = relevantData.offset.y
		if relevantData.offset.y + relevantData.dimensions.y > maxYPos:
			maxYPos = relevantData.offset.y + relevantData.dimensions.y
		dimensions.y = floor(maxYPos + abs(minYPos))
		var xIncrease = floor(relevantData.dimensions.x * (relevantData.xIncrimentRatio as float))
		if (xIncrease > 0):
			dimensions.x += xIncrease - 1
		return output
	
	
	@warning_ignore("shadowed_variable")
	func linkTimingData(timingData):
		self.timingData = timingData
	
	
	func prepare(actionList): # resizeTriplets, resize ties, delete base notation property, set tieAtEnd property
		for g in range(graphicList.size()):
			var graphic = graphicList[g]
			if graphic.type == BEAM:
				var parentNote: notation = graphic.baseNotation
				var parentNoteIndex: int = util.getNext(actionList, 0, func(note): return note == parentNote)
				var nextNoteIndex: int = util.getNext(actionList, parentNoteIndex + 1, func(note): return note.type == NOTE)
				var nextNote: notation = actionList[nextNoteIndex]
				var parentGraphicIndex: int = util.getNext(graphicList, g, func(graph): return graph.baseNotation == parentNote && graph.type == parentNote.type)
				var nextGraphicIndex: int = util.getNext(graphicList, parentGraphicIndex + 1, func(graph): return graph.baseNotation == nextNote && graph.type == nextNote.type)
				var firstGraphic: Dictionary = graphicList[parentGraphicIndex]
				var lastGraphic: Dictionary = graphicList[nextGraphicIndex]
				stretchBetween(graphic, firstGraphic, lastGraphic, BACK, BACK, TOP)
			elif graphic.type == BSOLO_BEAM || graphic.type == FSOLO_BEAM:
				var parentNote: notation = graphic.baseNotation
				var parentGraphicIndex: int = util.getNext(graphicList, g, func(graph): return graph.baseNotation == parentNote && graph.type == parentNote.type)
				var parentGraphic: Dictionary = graphicList[parentGraphicIndex]
				placeAtMarker(graphic, parentGraphic, FRONT if graphic.type == BSOLO_BEAM else BACK, BACK, TOP)
			elif graphic.type == TIE:
				var parentNote: notation = graphic.baseNotation
				var parentNoteIndex: int = util.getNext(actionList, 0, func(note): return note == parentNote)
				var parentGraphicIndex: int = util.getNext(graphicList, g, func(graph): return graph.baseNotation == parentNote && graph.type == parentNote.type)
				var parentGraphic: Dictionary = graphicList[parentGraphicIndex]
				var nextNoteIndex: int = util.getNext(actionList, parentNoteIndex + 1, func(note): return note.type == NOTE)
				if nextNoteIndex == -1:
					tieAtEnd = true
					tieAtEndGraphic = graphic
					tieAtEndParent = parentGraphic
					placeAtMarker(graphic, parentGraphic, FRONT, FRONT, BOTTOM)
				else:
					var nextNote: notation = actionList[nextNoteIndex]
					var nextGraphicIndex: int = util.getNext(graphicList, parentGraphicIndex + 1, func(graph): return graph.baseNotation == nextNote && graph.type == nextNote.type)
					var nextGraphic: Dictionary = graphicList[nextGraphicIndex]
					stretchBetween(graphic, parentGraphic, nextGraphic, FRONT, FRONT, BOTTOM)
			elif graphic.type == DOT:
				var dotted = graphicList[util.getPrevious(graphicList, g - 1, func(graph): return graph.type == NOTE || graph.type == REST || graph.type == DOT)]
				graphic.position = dotted.graphicData.dotPosition * scale + dotted.position + graphic.graphicData.offset
			elif graphic.type == TUPLET:
				var tempBase: notation = graphic.baseNotation
				var group: int = tempBase.groupNumber
				var firstGraphicIndex: int = util.getNext(graphicList, g + 1, func(graph): return (graph.type == NOTE || graph.type == REST) && graph.baseNotation.groupNumber == group)
				var notGroupIndex: int = util.getNext(graphicList, firstGraphicIndex + 1, func(graph): return (graph.type == NOTE || graph.type == REST) && graph.baseNotation.groupNumber != group)
				var lastGraphicIndex: int = util.getPrevious(graphicList,
						notGroupIndex if notGroupIndex != -1 else graphicList.size() - 1,
						func(graph): return (graph.type == NOTE || graph.type == REST) && graph.baseNotation.groupNumber == group)
				var firstGraphic: Dictionary = graphicList[firstGraphicIndex]
				var lastGraphic: Dictionary = graphicList[lastGraphicIndex] if lastGraphicIndex >= 0  else graphicList.back()
				
				var firstBrace: Dictionary = addGraphic(util.graphicData.tuplet.brace, tempBase, TUPLET_COMPONENT, {})
				var lastBrace: Dictionary = addGraphic(util.graphicData.tuplet.brace, tempBase, TUPLET_COMPONENT, {})
				var firstBar: Dictionary = addGraphic(util.graphicData.tuplet.bar, tempBase, TUPLET_COMPONENT, {})
				var lastBar: Dictionary = addGraphic(util.graphicData.tuplet.bar, tempBase, TUPLET_COMPONENT, {})
				var tupletNumber: Dictionary = addGraphic(util.graphicData.tuplet[3], tempBase, TUPLET_COMPONENT, {})
				placeAtMarker(firstBrace, firstGraphic, BACK, FRONT, TOP)
				placeAtMarker(lastBrace, lastGraphic, FRONT, BACK, TOP)
				placeBetween(tupletNumber, firstBrace, lastBrace, BACK, FRONT, TOP)
				stretchBetween(firstBar, firstBrace, tupletNumber, BACK, FRONT, TOP)
				stretchBetween(lastBar, tupletNumber, lastBrace, BACK, FRONT, TOP)
		startingNotation = graphicList[util.getNext(graphicList, 0 , func(note): return note.type == REST || note.type == NOTE)]
		
		measureStartX = graphicList[util.getPrevious(graphicList, graphicList.size() - 2, func(graph): return graph.type == MEASURE_LINE)].position.x
		
		for item in graphicList:
			item.erase("baseNotation")
	
	
	func stretchBetween(sGraphic, fGraphic, bGraphic, fPoint, bPoint, yPoint):
		var fMarker: int = fGraphic.scale.x * (fGraphic.graphicData.frontMarker if fPoint == FRONT else fGraphic.graphicData.backMarker)
		var bMarker: int = bGraphic.scale.x * (bGraphic.graphicData.frontMarker if bPoint == FRONT else bGraphic.graphicData.backMarker)
		var stretchDistance: int = abs((bGraphic.position.x + bMarker) - (fGraphic.position.x + fMarker))
		var graphicDistance: int = abs(sGraphic.graphicData.backMarker - sGraphic.graphicData.frontMarker)
		sGraphic.scale.x = stretchDistance as float / graphicDistance as float
		sGraphic.position = Vector2(round(fGraphic.position.x + fMarker + sGraphic.graphicData.offset.x - scale * sGraphic.graphicData.frontMarker),
		round(fGraphic.position.y + (sGraphic.graphicData.offset.y if yPoint == TOP else sGraphic.graphicData.offset.y + fGraphic.graphicData.dimensions.y)))
	
	
	func placeBetween(pGraphic, fGraphic, bGraphic, fPoint, bPoint, yPoint):
		var fMarker: int = fGraphic.scale.x * (fGraphic.graphicData.frontMarker if fPoint == FRONT else fGraphic.graphicData.backMarker)
		var bMarker: int = bGraphic.scale.x * (bGraphic.graphicData.frontMarker if bPoint == FRONT else bGraphic.graphicData.backMarker)
		var centerX: int = (bGraphic.position.x + bMarker + fGraphic.position.x + fMarker) / 2
		var graphicCenter: int = abs(pGraphic.graphicData.backMarker - pGraphic.graphicData.frontMarker) / 2 * pGraphic.scale.x
		pGraphic.position = Vector2(round(centerX + pGraphic.graphicData.offset.x - graphicCenter),
		round(fGraphic.position.y + (pGraphic.graphicData.offset.y if yPoint == TOP else pGraphic.graphicData.offset.y + fGraphic.graphicData.dimensions.y)))
	
	
	func placeAtMarker(pGraphic, bGraphic, pPoint, bPoint, yPoint):
		var pMarker: int = pGraphic.scale.x * (pGraphic.graphicData.frontMarker if pPoint == FRONT else pGraphic.graphicData.backMarker)
		var bMarker: int = bGraphic.scale.x * (bGraphic.graphicData.frontMarker if bPoint == FRONT else bGraphic.graphicData.backMarker)
		pGraphic.position = Vector2(round(bGraphic.position.x + bMarker + pGraphic.graphicData.offset.x - pMarker),
		round(bGraphic.position.y + (pGraphic.graphicData.offset.y if yPoint == TOP else pGraphic.graphicData.offset.y + bGraphic.graphicData.dimensions.y)))


class measureTimingData:
	var fullTimingsList: Array
	var fullInputsList: Array
	var timings = []
	var userTimings = []
	var timeSignature: Dictionary
	var resetTime: float
	var swingDivision: float
	var gStartTime: float
	var firstActionIndex: int
	var lastActionIndex: int
	var score: float = 0
	
	
	@warning_ignore("shadowed_variable")
	func _init(gStartTime: float, fullTimingsList, fullInputsList, timeSignature, swingDivision: float):
		self.timeSignature = timeSignature
		self.swingDivision = swingDivision
		self.fullTimingsList = fullTimingsList
		self.fullInputsList = fullInputsList
		self.gStartTime = gStartTime
	
	
	func newTiming(startTime: float, action: int):
		if timings.size() == 0:
			firstActionIndex = fullTimingsList.size()
		lastActionIndex = fullTimingsList.size()
		var timing: Dictionary = {"startTime": startTime as float, "gStartTime": startTime as float + gStartTime as float, "action": action, "parentMeasure": self, "other": null}
		timings.append(timing)
		fullTimingsList.append(timing)
		return timing
	
	
	func newUserTiming(insertIndex: int, startTime: float, action: int, nearestAction):
		var output: Dictionary = {"startTime": startTime as float, "gStartTime": startTime as float + gStartTime as float, "action": action, "nearestAction": nearestAction, "score": score, "parentMeasure": self, "other": null}
		userTimings.append(output)
		if insertIndex == fullInputsList.size():
			fullInputsList.append(output)
		else:
			fullInputsList.insert(insertIndex, output)
		return output
	
	
	func clearInput():
		score = 0
		userTimings.clear()


var nextGroupNumber: int = 0
func generateMeasure(timeSigNum: int, timeSigDen: int):
	var output: Array = []
	var division: float
	var duration: float = (4.0 / timeSigDen) * timeSigNum
	nextGroupNumber = 0
	for d in divisionLookup:
		if fmod(duration / d, 1) == 0:
			division = d
			break
	
	var meter: int = findMeter(duration, division)
	var remainingDuration: float = duration
	var tempGroup: Array = []
	if meter % 2 == 0:
		if duration == division:
			output.append_array(generateGroup(duration, true))
		else:
			for g in range(2):
				tempGroup = generateGroup(duration / 2)
				tempGroup.front().frontStructBeam = false
				tempGroup.back().backStructBeam = false
				output.append_array(tempGroup)
	elif meter % 3 == 0:
		for g in range(3):
			tempGroup = generateGroup(duration / 3)
			tempGroup.front().frontStructBeam = false
			tempGroup.back().backStructBeam = false
			output.append_array(tempGroup)
	else:
		var maxDivision: float
		for d in divisionLookup:
			if duration - division * 3 - d >= 0:
				maxDivision = d
				break
		while remainingDuration > division * 3:
			tempGroup = generateGroup(maxDivision)
			tempGroup.front().frontStructBeam = false
			tempGroup.back().backStructBeam = false
			output.append_array(tempGroup)
			remainingDuration -= maxDivision
		if division >= 1:
			for g in range(3):
				tempGroup = generateGroup(division)
				tempGroup.front().frontStructBeam = false
				tempGroup.back().backStructBeam = false
				output.append_array(tempGroup)
		else:
			tempGroup = generateGroup(division * 3)
			tempGroup.front().frontStructBeam = false
			tempGroup.back().backStructBeam = false
			output.append_array(tempGroup)
	
	output.front().frontBeams = 0
	output.back().backBeams = 0
	var current: notation
	var followingIndex: int
	var following: notation
	var tempIndex: int = 0
	while tempIndex < output.size() - 1:
		current = output[tempIndex]
		if current.type == NOTE && current.division < 4.0:
			var startIndex: int = tempIndex
			var joinLength: int = 0
			while tempIndex < output.size() - 1:
				current = output[tempIndex]
				following = output[tempIndex + 1]
				if following.type == NOTE && current.division == following.division && current.timeMultiplier == following.timeMultiplier && ((!current.blockJoinBack && !following.blockJoinFront) || current.division >= 1.0):
					joinLength += 1
					tempIndex += 1
				else:
					break
			
			if joinLength > 0:
				var remJoins: int = 0
				for p in range(floor((joinLength + 1) as float / 2)):
					if util.weightedCoinProbability(sessionSettings.divProb[divisionLookup[current.division * 2]], sessionSettings.divProb[divisionLookup[current.division]] * 2):
						remJoins += 1
				
				var cSlot: int = 0
				var endSlot: int = joinLength
				while cSlot < endSlot:
					current = output[startIndex + cSlot]
					following = output[startIndex + cSlot + 1]
					if randf() <= (remJoins as float / floor((joinLength + 1 - cSlot) as float / 2) as float):
						current.division *= 2
						current.blockJoinBack = following.blockJoinBack
						current.defaultBeams = (log(current.division) / log(.5)) as int
						current.backStructBeam = following.backStructBeam
						current.connectBlockFront = true
						current.connectBlockBack = following.connectBlockBack || current.timeMultiplier == 1 || following.backStructBeam #allows combinations at the end of tuplets to combine
						output.remove_at(startIndex + cSlot + 1)
						remJoins -= 1
						endSlot -= 1
					else:
						current.connectBlockBack = true
						following.connectBlockFront = true
					cSlot += 1
		tempIndex += 1
	
	for n in range(output.size() - 1):
		current = output[n]
		if current.type == NOTE || current.type == REST:
			followingIndex = util.getNext(output, n + 1, func(note): return note.type == NOTE || note.type == REST)
			if followingIndex == -1:
				break
			else:
				following = output[followingIndex]
			
			if current.type == NOTE && !current.connectBlockBack && following.type == NOTE && !following.connectBlockFront && randf() < sessionSettings.tiedProb[divisionLookup[current.division]]:
				current.connect = true
				current.drawConnect = true
			if current.type == REST && following.type == REST:
				current.restConnect = true
	
	tempIndex = output.size() - 2
	while tempIndex >= 0:
		current = output[tempIndex]
		if current.connect && (current.backStructBeam || current.division >= 1.0) && current.timeMultiplier == 1.0:
			followingIndex = util.getNext(output, tempIndex + 1, func(note): return note.type == NOTE || note.type == REST)
			if followingIndex != -1:
				following = output[followingIndex]
				if following.type == NOTE && following.division == current.division / 2 && (following.frontStructBeam || following.division >= 0.5) && following.timeMultiplier == 1.0:
					current.dots = following.dots + 1
					current.drawConnect = following.drawConnect
					following.type = DOT
		tempIndex -= 1
	
	for n in range(output.size() - 1):
		current = output[n]
		if current.type == NOTE || REST:
			followingIndex = util.getNext(output, n + 1, func(note): return note.type == NOTE || note.type == REST)
			if followingIndex == -1:
				break
			else:
				following = output[followingIndex]
			
			if current.type == NOTE && current.backStructBeam && following.type == NOTE && following.frontStructBeam:
				current.beamsFromBack = following.defaultBeams
				current.backBeams = current.defaultBeams
				following.beamsFromFront = current.defaultBeams
				following.frontBeams = following.defaultBeams
				current.backStructBeam = current.beamsFromBack > 0 && current.backBeams > 0
				following.frontStructBeam = following.beamsFromFront > 0 && following.frontBeams > 0
			else:
				current.backStructBeam = false
				following.frontStructBeam = false
			
			if current.backBeams > 0 || current.frontBeams > 0:
				var backMatch: bool = current.defaultBeams == current.beamsFromBack
				var frontMatch: bool = current.defaultBeams == current.beamsFromFront
				if backMatch && !frontMatch:
					if current.frontBeams < current.beamsFromFront:
						current.beamsFromFront = current.frontBeams
					else:
						current.frontBeams = current.beamsFromFront
				elif frontMatch && !backMatch:
					if current.backBeams < current.beamsFromBack:
						current.beamsFromBack = current.backBeams
					else:
						current.backBeams = current.beamsFromBack
	
#	tempIndex = output.size() - 2
#	while tempIndex >= 0:
#		current = output[tempIndex]
#		if current.connect && !current.frontStructBeam && !current.backStructBeam && current.timeMultiplier == 1.0:
#			followingIndex = util.getNext(output, tempIndex + 1, func(note): return note.type == NOTE || note.type == REST || note.type == DOT)
#			if followingIndex != -1:
#				following = output[followingIndex]
#				if following.type == NOTE && following.division / 2 == current.division && !following.frontStructBeam && !following.backStructBeam && following.timeMultiplier == 1.0 && following.dots <= 0:
#					current.division *= 2
#					following.division *= 0.5
#					current.dots = 1
#					current.drawConnect = following.drawConnect
#					following.type = DOT
#		tempIndex -= 1
	
	return output


func generateGroup(duration: float, forceSplit: bool = false) -> Array:
	var groupNumber: int = nextGroupNumber
	nextGroupNumber += 1
	var group: Array = []
	var division: float
	var divisionIndex: int
	var actualDivision: float = -1
	for d in divisionLookup:
		if fmod(duration, d) == 0:
			division = d
			divisionIndex = divisionLookup[d]
			break
	
	var meter: int = findMeter(duration, division)
	
	if meter == 2:
		if division == duration && weighDivisionChance(divisionIndex):
			return [(notation.new(
					NOTE if randf() <= sessionSettings.noteProb[divisionIndex] else REST,
					division,
					1))]
		else:
			actualDivision = (division / 2) if duration == division else division
			if duration < 8.0 && division != 4.0: divisionIndex += 1
			if randf() <= sessionSettings.tripletProb[divisionIndex] && weighDivisionChance(divisionIndex):
				group.append(notation.new(TUPLET, division / 2, 1))
				group.append_array(generateShallowNotation(actualDivision, 3, true))
			else:
				var genArray: Array = []
				if divisionIndex >= smallestDivIndex:
					genArray.append_array(generateShallowNotation(actualDivision, 2))
				else:
					if forceSplit:
						var tempArray: Array = []
						tempArray = generateGroup(actualDivision)
						tempArray.back().backStructBeam = false
						tempArray.back().blockJoinBack = true
						genArray.append_array(tempArray)
						
						tempArray = generateGroup(actualDivision)
						tempArray.front().frontStructBeam = false
						tempArray.front().blockJoinFront = true
						genArray.append_array(tempArray)
					else:
						for n in range(2):
							genArray.append_array(generateGroup(actualDivision))
				if genArray.size() == 2:
					if genArray[0].type == NOTE && genArray[1].type == REST && randf() < sessionSettings.syncoProb[divisionIndex]:
						genArray[0].type = REST
						genArray[1].type = NOTE
					
					if genArray[0].type == REST && genArray[1].type == NOTE && randf() > sessionSettings.syncoProb[divisionIndex]:
						genArray[0].type = NOTE
						genArray[1].type = REST
					
					genArray[0].blockJoinBack = true
					genArray[1].blockJoinFront = true
					genArray[0].connectBlockBack = true
					genArray[1].connectBlockFront = true
				group.append_array(genArray)
	else:
		for n in range(meter):
			group.append_array(generateGroup(duration / meter))
		if duration / meter != division:
			actualDivision = -1
		else:
			actualDivision = division
	
	var current: notation = group.front()
	var following: notation
	var index: int = 0
	for note in group:
		if note.groupNumber == -1:
			note.groupNumber = groupNumber
	while index < group.size() - 1:
		current = group[index]
		following = group[index + 1]
		if current.type == REST && following.type == REST && current.division == actualDivision && following.division == actualDivision:
				current.division *= 2
				group.remove_at(index + 1)  
		index += 1
	if duration > .5 && group.any(func(note): return note.division <= .25):
		group.front().frontStructBeam = false
		group.back().backStructBeam = false
		group.front().blockJoinFront = true
		group.back().blockJoinBack = true
	if duration >= 2:
		group.front().frontStructBeam = false
		group.back().backStructBeam = false
		if group.size() == 4 && group[0].type != TUPLET && !forceSplit:
			group[1].backStructBeam = true
			group[2].frontStructBeam = true
	return group


func findMeter(duration: float, division: float) -> int:
	if duration == division:
		return 2
	var divs: int = (duration / division) as int
	var factor: int = 2
	while factor <= divs:
		if divs % factor == 0:
			break
		factor += 1
	return factor


func weighDivisionChance(index: int) -> bool:
	if index >= smallestDivIndex: return true
	var chanceList: Array = sessionSettings.divProb
	var divIndex: int = index
	var divisionChance: float = chanceList[divIndex]
	var followingChance: float = 0
	divIndex += 1
	while divIndex < smallestDivIndex:
		followingChance += chanceList[divIndex]
		divIndex += 1
	followingChance += chanceList[smallestDivIndex] / 2
	return randf_range(0, divisionChance + followingChance) <= divisionChance


func generateShallowNotation(division: float, parts: int, tuplet: bool = false) -> Array:
	var output: Array = []
	var timeMult: float = 2.0 / parts if tuplet else 1.0
	var noteProb: float = sessionSettings.noteProb[divisionLookup[division]]
	for part in range(parts):
		output.append(notation.new(
					NOTE if randf() < noteProb else REST,
					division,
					timeMult))
	if tuplet:
		if output[1].type != NOTE && output[2].type != NOTE:
			var forceIndex: int = randi_range(1, 2)
			output[forceIndex].type = NOTE
			output[0].connectBlockFront = forceIndex == 1
		var frontNoteChain: int = 0
		for note in output:
			if note.type == NOTE:
				frontNoteChain += 1
			else:
				break
		var rearRestChain: int = 0
		var index: int = output.size() - 1
		while index >= 0:
			if output[index].type == REST:
				rearRestChain += 1
				index -= 1
			else:
				break
		if rearRestChain + frontNoteChain == output.size():
			var ind: int = randi_range(1, frontNoteChain - 1)
			output[ind].blockJoinFront = true
			output[ind].connectBlockFront = true
		output.front().frontStructBeam = false
		output.back().backStructBeam = false
		output.front().blockJoinFront = true
		output.back().blockJoinBack = true
	
	return output


class notation:
	var timeMultiplier: float
	var division: float
	var type: int
	var subSequence: Array = []
	var groupNumber: int = -1
	
	var defaultBeams: int
	var frontStructBeam: bool = true
	var backStructBeam: bool = true
	var frontBeams: int = 0
	var backBeams: int = 0
	var beamsFromFront: int = 0
	var beamsFromBack: int = 0
	
	var blockJoinFront: bool = false
	var blockJoinBack: bool = false
	
	var connect: bool = false
	var drawConnect: bool = false
	var restConnect: bool = false
	var connectBlockFront: bool = false
	var connectBlockBack: bool = false
	
	var dots: int = 0
	
	@warning_ignore("shadowed_variable")
	func _init(type: int, division: float, timeMultiplier: float):
		self.type = type
		self.division = division
		self.timeMultiplier = timeMultiplier
		defaultBeams = (log(division) / log(.5)) as int
		if self.defaultBeams < 0: self.defaultBeams = 0
		self.subSequence = subSequence


func updateViewDimensions():
	VIEWPORT_WIDTH = get_viewport().get_visible_rect().size.x
	VIEWPORT_HEIGHT = get_viewport().get_visible_rect().size.y

func HPercentToPX(percent: float):
	return VIEWPORT_HEIGHT * percent

func WPercentToPX(percent: float):
	return VIEWPORT_HEIGHT * percent

func save():
	if allowSave:
		ResourceSaver.save(userSave, "user://userData.tres")
