extends Node2D

class_name graphicLine

var baseTween
var destinationPosition: Vector2
var lineNumber: int
var dimensions: Vector2
var normalDimensions: Vector2
var lineData


@warning_ignore("shadowed_variable")
func _init(lineData, startPosition: Vector2):
	self.lineData = lineData
	self.lineNumber = lineData.lineNumber
	self.destinationPosition = startPosition
	self.position = startPosition
	dimensions = lineData.dimensions
	normalDimensions = dimensions


func prepareForTap():
	dimensions = normalDimensions


func prepareForFeedback(feedbackDisplayHeight):
	dimensions = normalDimensions
	dimensions.y += feedbackDisplayHeight + 5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func is_moving():
	return position != destinationPosition


func slideToPosition(newPosition: Vector2, timem):
	destinationPosition = newPosition
	baseTween = create_tween()
	baseTween.tween_property(self, "position", newPosition, timem as float / 1000)


func teleToPosition(newPosition: Vector2):
	if typeof(baseTween) == 24:
		baseTween.kill()
	destinationPosition = newPosition
	position = newPosition
