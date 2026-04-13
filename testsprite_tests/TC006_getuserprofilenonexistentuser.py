import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_get_user_profile_nonexistent_user():
    username = "thisuserdoesnotexist12345"
    url = f"{BASE_URL}/users/{username}"

    try:
        response = requests.get(url, timeout=TIMEOUT)
    except requests.RequestException as e:
        assert False, f"Request failed: {e}"

    assert response.status_code == 404, f"Expected status code 404 but got {response.status_code}"
    try:
        resp_json = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    # The response body for 404 is a plain error message string or JSON with message?
    # From PRD examples: "User tidak ditemukan"
    # We'll accept either a JSON with message or plain text equal to the error string.
    if isinstance(resp_json, dict):
        # Accept "detail" or "message" keys if present
        error_message = resp_json.get("detail") or resp_json.get("message") or ""
        assert "User tidak ditemukan" in error_message, f"Error message mismatch: {resp_json}"
    else:
        # If the response is a string directly
        assert "User tidak ditemukan" in response.text, f"Error message mismatch: {response.text}"

test_get_user_profile_nonexistent_user()