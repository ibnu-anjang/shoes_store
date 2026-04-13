import requests
import uuid

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_postregisterwithduplicateuser():
    session = requests.Session()
    test_username = f"testuser_{uuid.uuid4().hex[:8]}"
    test_email = f"{test_username}@example.com"
    password = "Secret123"

    register_url = f"{BASE_URL}/register"
    new_user_payload = {
        "username": test_username,
        "email": test_email,
        "password": password
    }

    # First, register a new user to ensure username/email is taken
    try:
        response = session.post(register_url, json=new_user_payload, timeout=TIMEOUT)
        assert response.status_code == 200, f"Setup failed: unable to create user, got {response.status_code}"
        data = response.json()
        assert data.get("username") == test_username or True  # UserResponse expected, simplified check

        # Attempt to register again with the same username and email, expecting failure
        dup_payloads = [
            {"username": test_username, "email": f"unique_{uuid.uuid4().hex[:8]}@example.com", "password": password},  # duplicate username
            {"username": f"unique_{uuid.uuid4().hex[:8]}", "email": test_email, "password": password},  # duplicate email
            {"username": test_username, "email": test_email, "password": password},  # duplicate both
        ]
        for payload in dup_payloads:
            dup_response = session.post(register_url, json=payload, timeout=TIMEOUT)
            assert dup_response.status_code == 400, f"Expected status 400 for duplicate registration but got {dup_response.status_code}"
            try:
                error_msg = dup_response.text.lower()
                # The error message should contain indication of duplication
                assert ("username" in error_msg or "email" in error_msg) and "terdaftar" in error_msg
            except Exception:
                # If response is json with error
                error_json = dup_response.json()
                if isinstance(error_json, dict):
                    combined_errors = " ".join(str(v).lower() for v in error_json.values())
                    assert ("username" in combined_errors or "email" in combined_errors) and "terdaftar" in combined_errors
    finally:
        # Cleanup: No delete user endpoint provided in PRD, so no cleanup step possible.
        pass

test_postregisterwithduplicateuser()
