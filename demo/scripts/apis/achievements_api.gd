extends HTTPRequest
class_name AchievementsAPI

# Achievements API - Manages user achievements, badges, and leaderboards
# Handles unlocking achievements, tracking progress, and competitive features

# Signals for achievement-related operations
signal achievements_loaded(achievements: Array)          # Fired when achievements list is retrieved
signal achievement_unlocked(achievement: Dictionary)     # Fired when new achievement is unlocked
signal leaderboard_loaded(leaderboard: Array)          # Fired when leaderboard data is loaded

# Base URL for all achievement-related endpoints
const BASE_URL = "http://localhost:3000/api/achievements"

# Retrieve all achievements earned by a specific user
# @param user_id: ID of the user whose achievements to fetch
# Returns: Array of achievement objects with unlock dates and progress
func get_user_achievements(user_id: int) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch user's achievements
	request(BASE_URL + "/user/" + str(user_id), headers, HTTPClient.METHOD_GET)

# Unlock a specific achievement for a user
# @param user_id: ID of the user earning the achievement
# @param achievement_id: Unique identifier of the achievement to unlock
func unlock_achievement(user_id: int, achievement_id: String) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var body = JSON.stringify({                       # Create unlock payload
		"user_id": user_id,
		"achievement_id": achievement_id,
		"unlocked_at": Time.get_datetime_string_from_system()  # Timestamp when unlocked
	})
	
	# Send POST request to unlock achievement
	request(BASE_URL + "/unlock", headers, HTTPClient.METHOD_POST, body)

# Get list of all available achievements that can be earned
# Returns: All achievements with descriptions, requirements, and reward information
func get_available_achievements() -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch all available achievements
	request(BASE_URL + "/available", headers, HTTPClient.METHOD_GET)

# Retrieve leaderboard rankings for a specific category
# @param category: Leaderboard category - "overall", "weekly", "monthly", "accuracy", etc.
# Returns: Ranked list of users with scores and positions
func get_leaderboard(category: String = "overall") -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch leaderboard for specified category
	request(BASE_URL + "/leaderboard/" + category, headers, HTTPClient.METHOD_GET)

# Check if user actions trigger any achievement unlocks
# @param user_id: ID of the user whose actions to check
# @param action_data: Dictionary containing action details (lesson completed, score achieved, etc.)
func check_achievement_conditions(user_id: int, action_data: Dictionary) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var body = JSON.stringify({                       # Create action check payload
		"user_id": user_id,
		"action": action_data                         # Details of the action performed
	})
	
	# Send POST request to check for achievement triggers
	request(BASE_URL + "/check", headers, HTTPClient.METHOD_POST, body)

# Handle HTTP request completion for all achievement operations
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()                                    # Create JSON parser
	var parse_result = json.parse(body.get_string_from_utf8())  # Parse response body
	
	# Exit if JSON parsing failed
	if parse_result != OK:
		return
	
	var response_data = json.data  # Extract parsed data
	
	# Handle successful responses
	if response_code == 200:
		var url = get_meta("last_url", "")  # Get request URL to determine response type
		# Route response to appropriate signal based on endpoint called
		if "/user/" in url or "/available" in url:
			achievements_loaded.emit(response_data)       # Achievements data loaded
		elif "/unlock" in url:
			achievement_unlocked.emit(response_data)      # Achievement successfully unlocked
		elif "/leaderboard" in url:
			leaderboard_loaded.emit(response_data)        # Leaderboard data loaded
