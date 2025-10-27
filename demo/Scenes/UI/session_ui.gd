extends CanvasLayer

signal settings_pressed

signal restart_pressed

signal scroll_up_pressed

signal scroll_down_pressed

signal play_pressed

signal stop_pressed

var upButtonTween
var downButtonTween
var mainContainer: Control

var countGraphicList: Array = [
			preload("res://UI/countInGo.png"), preload("res://UI/countIn1.png"), preload("res://UI/countIn2.png"), preload("res://UI/countIn3.png"),
			preload("res://UI/countIn4.png"), preload("res://UI/countIn5.png"), preload("res://UI/countIn6.png"),
			preload("res://UI/countIn7.png"), preload("res://UI/countIn8.png"), preload("res://UI/countIn9.png"),
			preload("res://UI/countIn10.png"), preload("res://UI/countIn11.png"), preload("res://UI/countIn12.png"),
		]

var scrollUpButton: Button
var scrollDownButton: Button
var playButton: Button
var settingsButton: Button
var restartButton: Button
var stopButton: Button
var spacer: Container

@onready var countContainer: CenterContainer = %"CountdownContainer"
@onready var countGraphic: TextureRect = %"CountdownNumber"
@onready var countBacking: ColorRect = %"CountdownBacking"
var countTween
var backingTween

@onready var tapHint := %"TapHint"
var tapTween
var tapDelayTween

# Called when the node enters the scene tree for the first time.
func _ready():
	scrollUpButton = get_node("%Scroll Button Up")
	scrollDownButton = get_node("%Scroll Button Down")
	playButton = get_node("%Play Button")
	stopButton = get_node("%Stop Button")
	spacer = get_node("%Stop Spacer")
	settingsButton = get_node("%SettingsButton")
	restartButton = get_node("%Restart Button")
	mainContainer = get_node("%Main Button Container")
	countGraphic.custom_minimum_size.x = get_viewport().get_visible_rect().size.x
	countBacking.custom_minimum_size.x = get_viewport().get_visible_rect().size.x
	scrollUpButton.self_modulate.a = 0
	scrollDownButton.self_modulate.a = 0
	hideScrollButtons()


func setMainButtonPadding(anchorIn: float):
	mainContainer.anchor_right = 1.0 - anchorIn
	mainContainer.anchor_left = anchorIn


func setMainButtonSize(sideLength: int):
	var newSize = Vector2(sideLength, sideLength)
	restartButton.custom_minimum_size = newSize
	settingsButton.custom_minimum_size = newSize
	playButton.custom_minimum_size = newSize
	stopButton.custom_minimum_size = newSize
	spacer.custom_minimum_size = newSize


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_restart_button_pressed():
	emit_signal("restart_pressed")


func _on_settings_button_pressed():
	emit_signal("settings_pressed")


func _on_scroll_up_button_pressed():
	emit_signal("scroll_up_pressed")


func _on_scroll_down_button_pressed():
	emit_signal("scroll_down_pressed")


func hideCountdown():
	if countTween:
		countTween.kill()
	countTween = create_tween()
	countTween.tween_property(countContainer, "modulate:a", 0, 0.2)
	countTween.tween_property(countContainer, "visible", false, 0)


func showCountdown():
	if countContainer.visible: return
	countContainer.visible = true
	countContainer.custom_minimum_size = Vector2(get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y / 4 + 20)
	countContainer.modulate.a = 1.0
	countBacking.color.a = 0
	if typeof(backingTween) == 24:
		backingTween.kill()
	backingTween = create_tween()
	backingTween.tween_property(countBacking, "color:a", 0.25, 0.2)


func pulseCount(beatLength, countNumber):
	countGraphic.texture = countGraphicList[countNumber]
	countGraphic.custom_minimum_size.y = get_viewport().get_visible_rect().size.y / 4
	if countTween:
		countTween.kill()
	countTween = create_tween()
	countTween.tween_property(countGraphic, "custom_minimum_size:y", get_viewport().get_visible_rect().size.y / 5, beatLength as float / 4000)
	if countNumber == 0:
		countTween.tween_property(countContainer, "modulate:a", 0, beatLength as float * 2 / 4000)
		countTween.tween_property(countContainer, "visible", false, 0)


func hideScrollButtons():
	scrollUpButton.visible = false
	scrollDownButton.visible = false


func showScrollButtons():
	scrollUpButton.visible = true
	scrollDownButton.visible = true


func showPlayButton():
	playButton.visible = true


func hidePlayButton():
	playButton.visible = false


func showStopButton():
	stopButton.visible = true
	spacer.visible = false


func hideStopButton():
	stopButton.visible = false
	spacer.visible = true


func flashButtons():
	if scrollUpButton.self_modulate.a == 0:
		upButtonTween = create_tween()
		upButtonTween.tween_property(scrollUpButton, "self_modulate", Color(1, 1, 1, 1), 1)
		upButtonTween.tween_property(scrollUpButton, "self_modulate", Color(1, 1, 1, 0), .5)
		upButtonTween.set_loops(2)
	if scrollDownButton.self_modulate.a == 0:
		downButtonTween = create_tween()
		downButtonTween.tween_property(scrollDownButton, "self_modulate", Color(1, 1, 1, 1), 1)
		downButtonTween.tween_property(scrollDownButton, "self_modulate", Color(1, 1, 1, 0), .5)
		downButtonTween.set_loops(2)


func enableTapHint():
	disableTapHint()
	tapDelayTween = create_tween()
	tapDelayTween.tween_interval(5)
	tapDelayTween.tween_callback(beginTapHint)


func beginTapHint():
	disableTapHint()
	
	tapTween = create_tween()
	tapTween.tween_property(tapHint, "anchor_top", 0.38, 0)
	tapTween.parallel().tween_property(tapHint, "anchor_bottom", 0.72, 0)
	
	tapTween.tween_property(tapHint, "anchor_top", 0.4, 0.2)
	tapTween.parallel().tween_property(tapHint, "anchor_bottom", 0.7, 0.2)
	tapTween.parallel().tween_property(tapHint, "modulate:a", 0.5, 0.2)
	
	tapTween.tween_property(tapHint, "anchor_top", 0.3, 1)
	tapTween.parallel().tween_property(tapHint, "anchor_bottom", 0.8, 1)
	tapTween.parallel().tween_property(tapHint, "modulate:a", 0.0, 1)
	tapTween.tween_interval(0.1)
	tapTween.set_loops()
	tapHint.visible = true


func disableTapHint():
	if tapDelayTween:
		tapDelayTween.kill()
	
	if tapTween:
		tapTween.kill()
	tapHint.visible = false


func _on_tap_button_button_up():
	Input.action_release("tap")


func _on_tap_button_button_down():
	Input.action_press("tap")


func _on_play_button_pressed():
	emit_signal("play_pressed")


func _on_stop_button_pressed():
	emit_signal("stop_pressed")
