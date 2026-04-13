import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_post_login_with_invalid_credentials():
    url = f"{BASE_URL}/login"
    headers = {
        "Content-Type": "application/json"
    }
    # Test with invalid username and valid password
    payloads = [
        {"username": "invaliduser", "password": "Secret123"},
        {"username": "alice", "password": "wrongpassword"},
        {"username": "invaliduser", "password": "wrongpassword"},
        {"username": "", "password": "Secret123"},
        {"username": "alice", "password": ""}
    ]
    for payload in payloads:
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=TIMEOUT)
        except requests.RequestException as e:
            assert False, f"Request failed: {e}"
        assert response.status_code == 400, f"Expected status 400 but got {response.status_code} for payload {payload}"
        try:
            resp_json = response.json()
        except ValueError:
            resp_json = None
        # The error message from PRD is string "Username atau password salah"
        # It might come as JSON with message or as plain text, so check both
        if resp_json:
            # We expect some field with error msg
            assert (
                "Username atau password salah" in str(resp_json.values()) or
                "Username atau password salah" in str(resp_json)
            ), f"Expected error message not found in response: {resp_json}"
        else:
            # Response is not json, check text content
            assert "Username atau password salah" in response.text, f"Expected error message not found in response text: {response.text}"

test_post_login_with_invalid_credentials()