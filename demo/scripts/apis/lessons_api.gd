extends HTTPRequest
class_name LessonsAPI

# Lessons API - Manages music lessons and educational content
# Handles fetching lesson data, tracking completion, and lesson categorization

# Signals for lesson-related operations
signal lessons_loaded(lessons: Array)                    # Fired when lesson list is retrieved
signal lesson_details_loaded(lesson: Dictionary)        # Fired when specific lesson details are loaded
signal lesson_completed(success: bool)                  # Fired when lesson completion is recorded

# Base URL for all lesson-related endpoints
const BASE_URL = "http://localhost:3000/api/lessons"

# Retrieve all available music lessons from the server
# Returns a list of lessons with basic information (id, title, difficulty, etc.)
func get_all_lessons() -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch all lessons
	request(BASE_URL, headers, HTTPClient.METHOD_GET)

# Get detailed information for a specific lesson by its ID
# @param lesson_id: Unique identifier of the lesson to retrieve
func get_lesson_by_id(lesson_id: int) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch specific lesson details
	request(BASE_URL + "/" + str(lesson_id), headers, HTTPClient.METHOD_GET)

# Get all lessons filtered by category (e.g., "scales", "chords", "rhythm")
# @param category: Category name to filter lessons by
func get_lessons_by_category(category: String) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch lessons in specific category
	request(BASE_URL + "/category/" + category, headers, HTTPClient.METHOD_GET)

# Mark a lesson as completed by the user and record their score
# @param lesson_id: ID of the completed lesson
# @param user_id: ID of the user who completed the lesson
# @param score: Score achieved (0-100 percentage or points)
func mark_lesson_completed(lesson_id: int, user_id: int, score: int) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var body = JSON.stringify({                       # Create completion record
		"lesson_id": lesson_id,
		"user_id": user_id,
		"score": score,
		"completed_at": Time.get_datetime_string_from_system()  # Timestamp of completion
	})
	
	# Send POST request to record lesson completion
	request(BASE_URL + "/" + str(lesson_id) + "/complete", headers, HTTPClient.METHOD_POST, body)

# Handle HTTP request completion for all lesson operations
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()                                    # Create JSON parser
	var parse_result = json.parse(body.get_string_from_utf8())  # Parse response body
	
	# Exit if JSON parsing failed
	if parse_result != OK:
		return
	
	var response_data = json.data  # Extract parsed data
	
	# Handle successful responses
	if response_code == 200:
		var url = get_meta("last_url", "")  # Get the request URL to determine response type
		# Check URL pattern to determine which signal to emit
		if url.ends_with("/lessons") or "/category/" in url:
			lessons_loaded.emit(response_data)        # Lesson list retrieved
		elif "/complete" in url:
			lesson_completed.emit(true)               # Lesson completion recorded
		else:
			lesson_details_loaded.emit(response_data) # Individual lesson details loaded
	else:
		# Handle error responses for completion requests
		if "/complete" in get_meta("last_url", ""):
			lesson_completed.emit(false)  # Failed to record completion
