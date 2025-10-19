extends Node
class_name GameManager

# Central Game Manager - Coordinates all game systems and manages overall state
# This singleton manages the main game flow, scene transitions, and system coordination

# Reference to the API manager for backend communication
var api_manager: APIManager

# Current game state tracking
var current_user: Dictionary = {}           # Currently logged in user data
var current_lesson: Dictionary = {}         # Active lesson being played
var game_settings: Dictionary = {}          # User preferences and settings
var is_paused: bool = false                # Game pause state

# Game state signals
signal user_logged_in(user_data: Dictionary)    # Fired when user successfully logs in
signal lesson_started(lesson: Dictionary)       # Fired when a lesson begins
signal lesson_completed(score: int)             # Fired when lesson is finished
signal game_paused(paused: bool)               # Fired when game pause state changes

func _ready() -> void:
	# Initialize game manager as singleton
	setup_game_manager()
	
	# Load user settings from file
	load_game_settings()

# Initialize the game manager and connect to API manager
func setup_game_manager() -> void:
	# Create and setup API manager
	api_manager = APIManager.new()
	add_child(api_manager)
	
	# Connect to API manager signals
	api_manager.api_error.connect(_on_api_error)
	api_manager.connection_status_changed.connect(_on_connection_changed)

# Start a music lesson for the current user
# @param lesson_data: Dictionary containing lesson information
func start_lesson(lesson_data: Dictionary) -> void:
	current_lesson = lesson_data
	lesson_started.emit(lesson_data)
	
	# Update user progress that lesson was accessed
	if current_user.has("id"):
		api_manager.progress_api.update_progress(
			current_user.id, 
			lesson_data.get("id", 0), 
			0,  # 0% progress at start
			0   # 0 minutes spent initially
		)

# Complete the current lesson with a score
# @param score: Final score achieved (0-100)
func complete_lesson(score: int) -> void:
	if current_lesson.is_empty():
		return
	
	lesson_completed.emit(score)
	
	# Record lesson completion via API
	if current_user.has("id") and api_manager.lessons_api:
		api_manager.lessons_api.mark_lesson_completed(
			current_lesson.get("id", 0),
			current_user.id,
			score
		)
	
	# Check for achievement triggers
	if api_manager.achievements_api:
		var action_data = {
			"type": "lesson_completed",
			"lesson_id": current_lesson.get("id", 0),
			"score": score
		}
		api_manager.achievements_api.check_achievement_conditions(current_user.id, action_data)
	
	# Clear current lesson
	current_lesson = {}

# Save user settings to persistent storage
func save_game_settings() -> void:
	var config = ConfigFile.new()
	
	# Store various game settings
	for key in game_settings:
		config.set_value("settings", key, game_settings[key])
	
	# Save to user://settings.cfg
	config.save("user://settings.cfg")

# Load user settings from persistent storage
func load_game_settings() -> void:
	var config = ConfigFile.new()
	
	# Load settings file
	var err = config.load("user://settings.cfg")
	if err != OK:
		# Set default settings if file doesn't exist
		game_settings = {
			"master_volume": 0.8,
			"music_volume": 0.7,
			"sfx_volume": 0.9,
			"fullscreen": false,
			"auto_save": true
		}
		return
	
	# Load settings from file
	for key in config.get_section_keys("settings"):
		game_settings[key] = config.get_value("settings", key)

# Handle API errors by showing user-friendly messages
func _on_api_error(message: String) -> void:
	print("Game Manager - API Error: ", message)
	# TODO: Show error dialog to user

# Handle connection status changes
func _on_connection_changed(connected: bool) -> void:
	print("Game Manager - Connection status: ", "Connected" if connected else "Disconnected")
	# TODO: Update UI to show connection status
