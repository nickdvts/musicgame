extends Node
class_name APIManager

# API instance variables - holds references to each API module
var auth_api        # Handles user authentication (login, register, logout)
var lessons_api     # Manages music lessons and educational content
var progress_api    # Tracks user learning progress and statistics  
var music_content_api  # Provides music theory content (scales, chords, exercises)
var achievements_api   # Handles user achievements and leaderboards

# User session data
var current_user_id: int = -1  # ID of currently logged in user (-1 means not logged in)
var auth_token: String = ""    # Authentication token for API requests

# Signals for communication with other parts of the game
signal api_error(message: String)              # Emitted when API requests fail
signal connection_status_changed(connected: bool)  # Emitted when connection status changes

func _ready() -> void:
	# Initialize all API modules when the manager starts
	setup_apis()

func setup_apis() -> void:
	# Check if auth_api.gd exists and load it for user authentication
	if FileAccess.file_exists("res://demo/scripts/apis/auth_api.gd"):
		var AuthAPI = load("res://demo/scripts/apis/auth_api.gd")          # Load the auth API class
		auth_api = AuthAPI.new()                              # Create new instance
		add_child(auth_api)                                   # Add to scene tree for HTTP requests
		auth_api.request_completed.connect(_on_request_completed)  # Connect completion signal
	
	# Check if lessons_api.gd exists and load it for lesson management
	if FileAccess.file_exists("res://demo/scripts/apis/lessons_api.gd"):
		var LessonsAPI = load("res://demo/scripts/apis/lessons_api.gd")    # Load the lessons API class
		lessons_api = LessonsAPI.new()                        # Create new instance
		add_child(lessons_api)                                # Add to scene tree for HTTP requests
		lessons_api.request_completed.connect(_on_request_completed)  # Connect completion signal
	
	# Check if progress_api.gd exists and load it for progress tracking
	if FileAccess.file_exists("res://demo/scripts/apis/progress_api.gd"):
		var ProgressAPI = load("res://demo/scripts/apis/progress_api.gd")  # Load the progress API class
		progress_api = ProgressAPI.new()                      # Create new instance
		add_child(progress_api)                               # Add to scene tree for HTTP requests
		progress_api.request_completed.connect(_on_request_completed)  # Connect completion signal
	
	# Check if music_content_api.gd exists and load it for music theory content
	if FileAccess.file_exists("res://demo/scripts/apis/music_content_api.gd"):
		var MusicContentAPI = load("res://demo/scripts/apis/music_content_api.gd")  # Load the music content API class
		music_content_api = MusicContentAPI.new()            # Create new instance
		add_child(music_content_api)                          # Add to scene tree for HTTP requests
		music_content_api.request_completed.connect(_on_request_completed)  # Connect completion signal
	
	# Check if achievements_api.gd exists and load it for achievements system
	if FileAccess.file_exists("res://demo/scripts/apis/achievements_api.gd"):
		var AchievementsAPI = load("res://demo/scripts/apis/achievements_api.gd")  # Load the achievements API class
		achievements_api = AchievementsAPI.new()             # Create new instance
		add_child(achievements_api)                           # Add to scene tree for HTTP requests
		achievements_api.request_completed.connect(_on_request_completed)  # Connect completion signal

# Public method to log in a user with username and password
func login(username: String, password: String) -> void:
	if auth_api:  # Check if auth API is available
		auth_api.login(username, password)  # Call login method on auth API

# Public method to register a new user account
func register(username: String, email: String, password: String) -> void:
	if auth_api:  # Check if auth API is available
		auth_api.register(username, email, password)  # Call register method on auth API

# Load all user-related data after successful login
func load_user_data(user_id: int) -> void:
	current_user_id = user_id  # Store the logged in user's ID
	if progress_api:  # Check if progress API is available
		progress_api.get_user_progress(user_id)  # Load user's learning progress
	if achievements_api:  # Check if achievements API is available
		achievements_api.get_user_achievements(user_id)  # Load user's achievements

# Check if the game has internet connectivity for API calls
func is_online() -> bool:
	return true # TODO: Implement actual connectivity check (ping server, check network status)

# Global handler for all API request completions
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates an error (400+ status codes)
	if response_code >= 400:
		var error_message = "API Error: " + str(response_code)  # Create error message with status code
		api_error.emit(error_message)  # Emit error signal for UI to handle
	
	# Update connection status based on response (0 means no response/connection failed)
	connection_status_changed.emit(response_code != 0)
