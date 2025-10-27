extends Node2D

class_name feedbackDisplay

var dimensions: Vector2
var measureData
var lastAction: int
var lastInput
const restColor = Color(.9, .45, .9)
const noteColor = Color(0, .65, .9)
const inputColor = Color(.4, .8, .4)
const badInputColor = Color(.8, .4, .4)
var beats
var beatLength: float
var coverBoxSize: Vector2
var padSize: int

enum {HOLD, RELEASE}

@warning_ignore("shadowed_variable", "shadowed_variable_base_class")
func _init(measureData, position: Vector2, dimensions: Vector2, lastAction: int, lastInput):
	self.dimensions = dimensions
	self.position = position
	self.measureData = measureData
	self.lastAction = lastAction
	self.lastInput = lastInput
	self.beats = measureData.timeSignature.numerator
	self.beatLength = 4.0 / measureData.timeSignature.denominator as float
	coverBoxSize = Vector2(round((dimensions.x) / beats) - 4, dimensions.y)
	padSize = round(coverBoxSize.y / 9 + 2)


# Called when the node enters the scene tree for the first time.
func _ready():
	var backBox = ColorRect.new()
	backBox.size = Vector2((coverBoxSize.x + 4) * beats, coverBoxSize.y)
	dimensions.x = backBox.size.x
	backBox.color = Color(0.8, 0.8, 0.8)
	add_child(backBox)
	var boxPosition = Vector2.ZERO
	boxPosition.x += 4
	for beat in range(beats):
		var coverBox = ColorRect.new()
		coverBox.size = coverBoxSize
		coverBox.position = boxPosition
		boxPosition.x += coverBoxSize.x + 4
		add_child(coverBox)
	backBox.size.x += 4
	createTimingDisplay(measureData.timings, RELEASE, HOLD, coverBoxSize.y / 9, restColor, lastAction == RELEASE, true)
	createTimingDisplay(measureData.timings, HOLD, RELEASE, coverBoxSize.y / 9, noteColor, lastAction == HOLD, true)
	createTimingDisplay(measureData.userTimings, HOLD, RELEASE, coverBoxSize.y / 9 * 5, inputColor, lastInput != null && lastInput.action == HOLD, false, badInputColor)


func createTimingDisplay(timingList: Array, timingStartType: int, timingEndType: int, yPosition, color, openStart, pad: bool, wrongColor = null):
	var lastStartBox: ColorRect
	var openEnded
	if openStart == true:
		lastStartBox = createActionBox(Vector2(0, yPosition), color)
		add_child(lastStartBox)
		lastStartBox.visible = false
		openEnded = true
	for timing in timingList:
		if timing.action == timingStartType && timing.startTime != timing.parentMeasure.resetTime:
			if wrongColor != null && timing.score <= 0.0:
				lastStartBox = createActionBox(Vector2(timing.startTime * dimensions.x / beatLength / beats + 3, yPosition), wrongColor)
			else:
				lastStartBox = createActionBox(Vector2(timing.startTime * dimensions.x / beatLength / beats + 3, yPosition), color)
			lastStartBox.set_meta("_goodTail", wrongColor == null || (timing.other != null && timing.other.score > 0.0));
			add_child(lastStartBox)
			openEnded = true
		elif timing.action == timingEndType && openEnded:
			add_child(createHoldBox(lastStartBox, (timing.startTime * dimensions.x / beatLength / beats) - (padSize if pad else 0), null if wrongColor == null else (wrongColor if timing.score <= 0 else inputColor)))
			openEnded = false
	if openEnded:
		if wrongColor == null:
			add_child(createHoldBox(
					lastStartBox,
					dimensions.x + extendBack(timingList.back())))
		else:
			add_child(createHoldBox(
					lastStartBox, dimensions.x + extendBack(timingList.back()),
					color if lastStartBox.get_meta("_goodTail") else wrongColor))


func extendBack(back) -> int:
	if back == null || back.other == null:
		return 25
	if (back.other.gStartTime > back.gStartTime && back.other.startTime == 0):
		return - coverBoxSize.y / 6 as int
	else:
		return 25


@warning_ignore("shadowed_variable_base_class")
func createActionBox(position: Vector2, color: Color):
	var actionBox = ColorRect.new()
	var diamondSize = coverBoxSize.y as float / 3 / sqrt(2)
	actionBox.set_rotation_degrees(45)
	actionBox.size = Vector2(diamondSize, diamondSize)
	actionBox.position = position
	position.x += diamondSize / sqrt(2) / 2
	position.x = round(position.x)
	position.y = round(position.y)
	actionBox.color = color
	actionBox.set_meta("_dimensions", Vector2(coverBoxSize.y as float / 3, coverBoxSize.y as float / 3))
	actionBox.set_meta("_untailed", true)
	return actionBox


func createHoldBox(actionBox: ColorRect, finalX, overrideColor = null):
	var holdBox = ColorRect.new()
	holdBox.position = actionBox.position
	holdBox.position.y += floor(actionBox.get_meta("_dimensions").y / 4)
	holdBox.size = Vector2(finalX - holdBox.position.x, actionBox.get_meta("_dimensions").y / 2)
	holdBox.color = actionBox.color if overrideColor == null else overrideColor
	actionBox.set_meta("_untailed", false)
	actionBox.z_index = 1
	return holdBox


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
