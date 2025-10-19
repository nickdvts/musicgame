extends HTTPRequest
class_name ProgressAPI

# Progress API - Tracks user learning progress, statistics, and practice sessions
# Manages all data related to user advancement through the music learning program

# Signals for progress-related operations
signal progress_loaded(progress_data: Dictionary)        # Fired when user progress is retrieved
signal progress_updated(success: bool)                   # Fired when progress update completes
signal statistics_loaded(stats: Dictionary)              # Fired when user statistics are loaded

# Base URL for all progress-related endpoints
const BASE_URL = "http://localhost:3000/api/progress"

# Retrieve comprehensive progress data for a specific user
# @param user_id: ID of the user whose progress to fetch
# Returns: Overall progress percentage, completed lessons, current level, etc.
func get_user_progress(user_id: int) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch user's progress data
	request(BASE_URL + "/user/" + str(user_id), headers, HTTPClient.METHOD_GET)

# Update progress for a specific lesson and user
# @param user_id: ID of the user making progress
# @param lesson_id: ID of the lesson being progressed
# @param progress_percent: How much of the lesson is complete (0-100)
# @param time_spent: Time in minutes spent on this lesson session
func update_progress(user_id: int, lesson_id: int, progress_percent: int, time_spent: int) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var body = JSON.stringify({                       # Create progress update payload
		"user_id": user_id,
		"lesson_id": lesson_id,
		"progress_percent": progress_percent,
		"time_spent": time_spent,
		"last_accessed": Time.get_datetime_string_from_system()  # When this update occurred
	})
	
	# Send POST request to update progress
	request(BASE_URL + "/update", headers, HTTPClient.METHOD_POST, body)

# Get detailed learning statistics for a user
# @param user_id: ID of the user whose stats to retrieve
# Returns: Total practice time, accuracy rates, streak counts, etc.
func get_user_statistics(user_id: int) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch user statistics
	request(BASE_URL + "/stats/" + str(user_id), headers, HTTPClient.METHOD_GET)

# Record a completed practice session with performance metrics
# @param user_id: ID of the user who practiced
# @param session_data: Dictionary containing session metrics (duration, exercises, accuracy)
func save_practice_session(user_id: int, session_data: Dictionary) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var body = JSON.stringify({                       # Create session record
		"user_id": user_id,
		"session_duration": session_data.get("duration", 0),      # Minutes practiced
		"exercises_completed": session_data.get("exercises", 0),   # Number of exercises done
		"accuracy": session_data.get("accuracy", 0),              # Accuracy percentage
		"session_date": Time.get_datetime_string_from_system()     # When session occurred
	})
	
	# Send POST request to save practice session
	request(BASE_URL + "/session", headers, HTTPClient.METHOD_POST, body)

# Handle HTTP request completion for all progress operations
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
		if "/user/" in url:
			progress_loaded.emit(response_data)      # User progress data loaded
		elif "/stats/" in url:
			statistics_loaded.emit(response_data)    # User statistics loaded
		elif "/update" in url or "/session" in url:
			progress_updated.emit(true)              # Progress/session update successful
	else:
		# Handle error responses for update operations
		if "/update" in get_meta("last_url", "") or "/session" in get_meta("last_url", ""):
			progress_updated.emit(false)  # Update/session save failed
