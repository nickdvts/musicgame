extends HTTPRequest
class_name MusicContentAPI

# Music Content API - Provides access to music theory content and exercises
# Handles scales, chords, exercises, theory lessons, and content validation

# Signals for music content operations
signal scales_loaded(scales: Array)                      # Fired when scales data is retrieved
signal chords_loaded(chords: Array)                      # Fired when chords data is retrieved
signal exercises_loaded(exercises: Array)                # Fired when exercises are loaded
signal content_loaded(content: Dictionary)               # Fired when theory content is loaded
signal validation_completed(is_correct: bool, feedback: Dictionary)  # Fired when answer validation completes

# Base URL for all music content endpoints
const BASE_URL = "http://localhost:3000/api/music"

# Retrieve musical scales filtered by difficulty level
# @param difficulty: Optional filter - "beginner", "intermediate", "advanced", or "" for all
# Returns: Array of scale objects with notes, fingerings, and practice exercises
func get_scales(difficulty: String = "") -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var url = BASE_URL + "/scales"                    # Base scales endpoint
	if difficulty != "":
		url += "?difficulty=" + difficulty            # Add difficulty filter if specified
	# Send GET request to fetch scales
	request(url, headers, HTTPClient.METHOD_GET)

# Retrieve chord information filtered by chord type
# @param chord_type: Optional filter - "major", "minor", "seventh", "suspended", etc.
# Returns: Array of chord objects with notes, fingerings, and progressions
func get_chords(chord_type: String = "") -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var url = BASE_URL + "/chords"                    # Base chords endpoint
	if chord_type != "":
		url += "?type=" + chord_type                  # Add chord type filter if specified
	# Send GET request to fetch chords
	request(url, headers, HTTPClient.METHOD_GET)

# Get practice exercises for a specific category and difficulty
# @param category: Type of exercises - "scales", "chords", "rhythm", "ear_training", etc.
# @param difficulty: Optional difficulty filter - "beginner", "intermediate", "advanced"
func get_exercises(category: String, difficulty: String = "") -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var url = BASE_URL + "/exercises/" + category     # Exercises endpoint with category
	if difficulty != "":
		url += "?difficulty=" + difficulty            # Add difficulty filter if specified
	# Send GET request to fetch exercises
	request(url, headers, HTTPClient.METHOD_GET)

# Get music theory content for a specific topic
# @param topic: Theory topic - "intervals", "key_signatures", "time_signatures", etc.
# Returns: Detailed explanation, examples, and related exercises
func get_theory_content(topic: String) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	# Send GET request to fetch theory content
	request(BASE_URL + "/theory/" + topic, headers, HTTPClient.METHOD_GET)

# Validate a user's answer sequence against the expected correct sequence
# @param sequence: Array of notes/chords the user played
# @param expected: Array of the correct notes/chords for comparison
# Returns: Validation result with correctness and detailed feedback
func validate_note_sequence(sequence: Array, expected: Array) -> void:
	var headers = ["Content-Type: application/json"]  # Set JSON content type
	var body = JSON.stringify({                       # Create validation payload
		"user_sequence": sequence,                    # What the user played
		"expected_sequence": expected                 # What should have been played
	})
	
	# Send POST request to validate the sequence
	request(BASE_URL + "/validate", headers, HTTPClient.METHOD_POST, body)

# Handle HTTP request completion for all music content operations
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
		if "/scales" in url:
			scales_loaded.emit(response_data)         # Scales data loaded
		elif "/chords" in url:
			chords_loaded.emit(response_data)         # Chords data loaded
		elif "/exercises" in url:
			exercises_loaded.emit(response_data)      # Exercises loaded
		elif "/theory" in url:
			content_loaded.emit(response_data)        # Theory content loaded
		elif "/validate" in url:
			validation_completed.emit(              # Validation completed
				response_data.get("is_correct", false),
				response_data.get("feedback", {})
			)
