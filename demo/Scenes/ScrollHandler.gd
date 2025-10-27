extends Node

class_name  ScrollHandler

@export var verticalScrolling: bool = true
@export var acceptGlobalInputs: bool = false

@export_category("Drag Scrolling")
@export var enableDragScrolling: bool = true
@export var dragDeadzone: float = 24
@export var touchToDragTimeMS: int = 100
@export var staleHoldTimeMS: int = 150
@export_range(0, 180, 1, "Degrees") var dragDirectionLeniency: float = 100

@export_category("Mouse Scrolling")
@export var enableMouseScrolling: bool = true
@export var scrollStep: float = 32

var initialTouchTimeMS: int = 0
var mouseHeld: bool = false
var dragging: bool = false
var blockDrag: bool = false
var initialTouchPosition: Vector2 = Vector2(0,0)
var initialParentPosition: Vector2

@onready var parent: Node = get_parent()
@onready var parentBasePosition: Vector2 = parent.position
@onready var parentLeftOffset: float = parent.offset_left
@onready var parentRightOffset: float = parent.offset_right
@onready var parentTopOffset: float = parent.offset_top
@onready var parentBottomOffset: float = parent.offset_bottom

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var currentTime: int = Time.get_ticks_msec()
	if mouseHeld && currentTime > initialTouchTimeMS + touchToDragTimeMS:
		var relativePosition: Vector2 = get_viewport().get_mouse_position() - initialTouchPosition
		if !dragging && !blockDrag:
			var relativeAngle: float = fmod(rad_to_deg(relativePosition.angle_to(Vector2(0,-1) if verticalScrolling else Vector2(-1,0))), 180)
			if relativeAngle > 90: relativeAngle -= 180
			
			if relativePosition.length() >= dragDeadzone:
				if abs(relativeAngle) <= dragDirectionLeniency / 2:
					dragging = true
				else:
					if currentTime > initialTouchTimeMS + staleHoldTimeMS:
						blockDrag = true
		
		if dragging:
			if verticalScrolling:
				parent.position.y = initialParentPosition.y + relativePosition.y
			else:
				parent.position.x = initialParentPosition.x + relativePosition.x
			checkBoundingBox()


func _input(event):
	if !event is InputEventMouseButton: return
	
	if enableDragScrolling && event.button_index == MOUSE_BUTTON_LEFT && event.is_released():
		mouseHeld = false
		dragging = false
		blockDrag = false
	
	if !acceptGlobalInputs && !(event.pressed && event.global_position.x >= parent.position.x && event.global_position.x <= parent.position.x + parent.size.x && event.global_position.y >= parent.position.y && event.global_position.y <= parent.position.y + parent.size.x):
		return
	
	if enableDragScrolling && event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed() && !mouseHeld:
		initialTouchPosition = event.global_position
		initialTouchTimeMS = Time.get_ticks_msec()
		initialParentPosition = parent.position
		mouseHeld = true
	
	if enableMouseScrolling && (event.button_index == MOUSE_BUTTON_WHEEL_UP || event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var positionChange: float
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			positionChange = scrollStep
		else:
			positionChange = -scrollStep
		
		var initialPosition: Vector2 = parent.position
		if verticalScrolling:
			parent.position.y += positionChange
		else:
			parent.position.x += positionChange
		
		checkBoundingBox()
		initialParentPosition += parent.position - initialPosition


func checkBoundingBox():
	var boxDimensions: Vector2 = parentBasePosition + parent.size - get_viewport().get_visible_rect().size
	if verticalScrolling:
		if parent.position.y < parentBasePosition.y - boxDimensions.y:
			parent.position.y = parentBasePosition.y - boxDimensions.y
		
		if parent.position.y > parentBasePosition.y:
			parent.position.y = parentBasePosition.y
	else:
		if parent.position.x < parentBasePosition.x - boxDimensions.x:
			parent.position.x = parentBasePosition.x - boxDimensions.x
		
		if parent.position.x > parentBasePosition.x:
			parent.position.x = parentBasePosition.x


func resetPosition():
	refreshSize()
	parent.position = parentBasePosition
	initialParentPosition = parentBasePosition


func refreshSize():
	parent.size = Vector2.ZERO
	parent.offset_left = parentLeftOffset
	parent.offset_right = parentRightOffset
	parent.offset_top = parentTopOffset
	parent.offset_bottom = parentBottomOffset
	checkBoundingBox()
