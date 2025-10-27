extends ColorRect

var metronomeTween

@export_category("Dimensions")
@export_range(0.0, 1.0, 0.001) var xAnchorDimension: float = 0.5
@export_range(0.0, 1.0, 0.001) var yAnchorDimension: float = 0.05

@export_category("Position")
@export_range(0.0, 1.0, 0.001) var yAnchorPosition: float = 0.5
@export_range(0.0, 1.0, 0.001) var xAnchorPosition: float = 0.5

var bigPulseRightAnchor: float
var bigPulseLeftAnchor: float
var pulseRightAnchor: float
var pulseLeftAnchor: float
var endRightAnchor: float
var endLeftAnchor: float

@onready var pulseAudio: AudioStreamPlayer = %"Pulse Audio"
@onready var bigPulseAudio: AudioStreamPlayer = %"Big Pulse Audio"

# Called when the node enters the scene tree for the first time.
func _ready():
	var centerDif: float = xAnchorDimension / 2
	bigPulseRightAnchor = xAnchorPosition + centerDif
	bigPulseLeftAnchor = xAnchorPosition - centerDif
	pulseRightAnchor = xAnchorPosition + centerDif * 0.8
	pulseLeftAnchor = xAnchorPosition - centerDif * 0.8
	endRightAnchor = xAnchorPosition + centerDif * 0.75
	endLeftAnchor = xAnchorPosition - centerDif * 0.75
	anchor_left = endLeftAnchor
	anchor_right = endRightAnchor
	anchor_top = yAnchorPosition - yAnchorDimension / 2
	anchor_bottom = yAnchorPosition + yAnchorDimension / 2


func _process(_delta):
	pass

func setVolumePercent(percent: float):
	bigPulseAudio.volume_db = util.valueAtPercentRange(percent, -24, 0)
	pulseAudio.volume_db = util.valueAtPercentRange(percent, -24, 0) - 2


func audioPulse():
	pulseAudio.play()


func bigAudioPulse():
	bigPulseAudio.play()


func pulse(beatLength):
	if typeof(metronomeTween) == 24:
		metronomeTween.kill()
	anchor_left = pulseLeftAnchor
	anchor_right = pulseRightAnchor
	metronomeTween = create_tween()
	metronomeTween.tween_property(self, "anchor_left", endLeftAnchor, beatLength as float / 4000)
	metronomeTween.parallel().tween_property(self, "anchor_right", endRightAnchor, beatLength as float / 4000)


func bigPulse(beatLength):
	if typeof(metronomeTween) == 24:
		metronomeTween.kill()
	anchor_left = bigPulseLeftAnchor
	anchor_right = bigPulseRightAnchor
	metronomeTween = create_tween()
	metronomeTween.tween_property(self, "anchor_left", endLeftAnchor, beatLength as float / 4000)
	metronomeTween.parallel().tween_property(self, "anchor_right", endRightAnchor, beatLength as float / 4000)
