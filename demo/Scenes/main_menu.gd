extends Control

@onready var titleLabel := %"TitleLabel"
@onready var playButton := %"PlayButton"
@onready var settingsButton := %"SettingsButton"
@onready var versionLabel := %"VersionLabel"

func _ready():
	titleLabel.text = "Beat Master"
	versionLabel.text = "v1.0"
	
	# Load user data on startup
	var save = util.loadSave()
	
	# Show welcome tutorial if enabled
	if save.tutorials.welcome:
		# Tutorial will be shown in settings or session screen

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/session_screen.tscn")

func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/settings_screen.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
