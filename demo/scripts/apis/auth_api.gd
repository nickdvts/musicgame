extends HTTPRequest
class_name AuthAPI

# Authentication API - Handles user login, registration, and logout operations
# This class manages all user authentication with the backend server

# Signals emitted when authentication operations complete
signal login_completed(success: bool, user_data: Dictionary)    # Fired when login attempt finishes
signal register_completed(success: bool, message: String)       # Fired when registration attempt finishes  
signal logout_completed()                                       # Fired when logout completes

# Base URL for all authentication endpoints on the backend server
const BASE_URL = "http://localhost:3000/api/auth"

# Attempt to log in a user with username and password
# @param username: User's login name
# @param password: User's password in plain text (will be sent securely via HTTPS)
func login(username: String, password: String) -> void:
	var headers = ["Content-Type: application/json"]  # Set request content type to JSON
	var body = JSON.stringify({                       # Create JSON payload with credentials
		"username": username,
		"password": password
	})
	
	# Send POST request to login endpoint
	request(BASE_URL + "/login", headers, HTTPClient.METHOD_POST, body)

# Register a new user account with username, email and password
# @param username: Desired username (must be unique)
# @param email: User's email address for account recovery
# @param password: Password in plain text (will be hashed on server)
func register(username: String, email: String, password: String) -> void:
	var headers = ["Content-Type: application/json"]  # Set request content type to JSON
	var body = JSON.stringify({                       # Create JSON payload with registration data
		"username": username,
		"email": email,
		"password": password
	})
	
	# Send POST request to registration endpoint
	request(BASE_URL + "/register", headers, HTTPClient.METHOD_POST, body)

# Log out the current user and invalidate their session
func logout() -> void:
	var headers = ["Content-Type: application/json"]  # Set request content type to JSON
	# Send POST request to logout endpoint (no body needed)
	request(BASE_URL + "/logout", headers, HTTPClient.METHOD_POST)

# Handle HTTP request completion for all authentication operations
# This method is automatically called when any HTTP request finishes
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()                                    # Create JSON parser
	var parse_result = json.parse(body.get_string_from_utf8())  # Parse response body to JSON
	
	# Exit early if JSON parsing failed
	if parse_result != OK:
		return
	
	var response_data = json.data  # Extract parsed JSON data
	
	# Handle successful responses (HTTP 200 OK)
	if response_code == 200:
		# Determine which endpoint was called and emit appropriate signal
		if "/login" in get_meta("last_url", ""):
			login_completed.emit(true, response_data)  # Login successful
		elif "/register" in get_meta("last_url", ""):
			register_completed.emit(true, response_data.get("message", "Registration successful"))  # Registration successful
		elif "/logout" in get_meta("last_url", ""):
			logout_completed.emit()  # Logout successful
	else:
		# Handle error responses (HTTP 400+ status codes)
		if "/login" in get_meta("last_url", ""):
			login_completed.emit(false, {})  # Login failed
		elif "/register" in get_meta("last_url", ""):
			register_completed.emit(false, response_data.get("message", "Registration failed"))  # Registration failed
