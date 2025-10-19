extends Control
class_name MenuController

# Menu Controller - Manages UI menus, navigation, and user interactions
# Handles main menu, lesson selection, settings, and other UI screens

# References to UI elements (assign in editor)
@onready var main_menu: Control
@onready var lesson_menu: Control
@onready var settings_menu: Control
@onready var login_dialog: AcceptDialog

# Reference to game manager for system communication
var game_manager: GameManager

# Menu navigation signals
signal menu_changed(menu_name: String)        # Fired when menu screen changes
signal lesson_selected(lesson_id: int)        # Fired when user selects a lesson

func _ready() -> void:
	# Get reference to game manager - use singleton pattern
	game_manager = get_node_or_null("/root/GameManager")
	
	# If game manager doesn't exist as singleton, try to find it in scene tree
	if not game_manager:
		game_manager = find_child("GameManager", true, false) as GameManager
	
	# Connect to game manager signals if available
	if game_manager:
		if game_manager.has_signal("user_logged_in"):
			game_manager.user_logged_in.connect(_on_user_logged_in)
		if game_manager.has_signal("lesson_completed"):
			game_manager.lesson_completed.connect(_on_lesson_completed)
	else:
		print("Warning: GameManager not found in MenuController")
	
	# Show main menu by default
	show_main_menu()

# Display the main menu screen
func show_main_menu() -> void:
	hide_all_menus()
	if main_menu:
		main_menu.show()
	menu_changed.emit("main_menu")

# Display the lesson selection menu
func show_lesson_menu() -> void:
	hide_all_menus()
	if lesson_menu:
		lesson_menu.show()
		# Load available lessons from API
		load_lessons()
	menu_changed.emit("lesson_menu")

# Display the settings/preferences menu
func show_settings_menu() -> void:
	hide_all_menus()
	if settings_menu:
		settings_menu.show()
		# Load current settings into UI
		populate_settings()
	menu_changed.emit("settings_menu")

# Hide all menu screens
func hide_all_menus() -> void:
	if main_menu: main_menu.hide()
	if lesson_menu: lesson_menu.hide()
	if settings_menu: settings_menu.hide()

# Load and display available lessons
func load_lessons() -> void:
	# Check if game manager and API are available
	if not game_manager:
		print("Error: Cannot load lessons - GameManager not available")
		return
	
	if not game_manager.api_manager:
		print("Error: Cannot load lessons - APIManager not available")
		return
	
	if not game_manager.api_manager.lessons_api:
		print("Error: Cannot load lessons - LessonsAPI not available")
		return
	
	# Connect to lessons loaded signal (disconnect first to avoid duplicate connections)
	var lessons_api = game_manager.api_manager.lessons_api
	
	# Safely disconnect if already connected
	if lessons_api.lessons_loaded.is_connected(_on_lessons_loaded):
		lessons_api.lessons_loaded.disconnect(_on_lessons_loaded)
	
	# Connect to lessons loaded signal
	lessons_api.lessons_loaded.connect(_on_lessons_loaded)
	
	# Request all lessons from API
	lessons_api.get_all_lessons()

# Populate settings menu with current values
func populate_settings() -> void:
	if not game_manager:
		print("Warning: Cannot populate settings - GameManager not available")
		return
	
	var settings = game_manager.game_settings
	
	# Update UI controls with current settings
	# TODO: Set volume sliders, checkboxes, etc. based on settings dictionary
	print("Settings loaded: ", settings)

# Handle successful user login
func _on_user_logged_in(user_data: Dictionary) -> void:
	print("User logged in: ", user_data.get("username", "Unknown"))
	# Update UI to show logged in state
	# TODO: Update user display, unlock lesson menu access

# Handle lesson completion
func _on_lesson_completed(score: int) -> void:
	print("Lesson completed with score: ", score)
	# Show completion dialog with score
	# TODO: Display results screen with score and next lesson suggestion

# Handle lessons data loaded from API
func _on_lessons_loaded(lessons: Array) -> void:
	print("Lessons loaded: ", lessons.size(), " lessons available")
	# Populate lesson menu with available lessons
	# TODO: Create lesson buttons/cards for each lesson in the array
	
	# Safely disconnect signal to prevent duplicate connections
	if game_manager and game_manager.api_manager and game_manager.api_manager.lessons_api:
		var lessons_api = game_manager.api_manager.lessons_api
		if lessons_api.lessons_loaded.is_connected(_on_lessons_loaded):
			lessons_api.lessons_loaded.disconnect(_on_lessons_loaded)

# Handle lesson selection by user
func _on_lesson_button_pressed(lesson_id: int) -> void:
	print("Lesson selected: ", lesson_id)
	lesson_selected.emit(lesson_id)
	
	# Start the selected lesson
	if game_manager and game_manager.api_manager and game_manager.api_manager.lessons_api:
		game_manager.api_manager.lessons_api.get_lesson_by_id(lesson_id)
	else:
		print("Error: Cannot start lesson - API not available")
