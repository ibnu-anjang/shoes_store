import requests
import uuid

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_get_user_profile_existing_user():
    # We need an existing user. We'll register a new unique user for the test then delete it after.
    username = f"testuser_{uuid.uuid4().hex[:8]}"
    email = f"{username}@example.com"
    password = "Secret123"
    register_url = f"{BASE_URL}/register"
    user_url = f"{BASE_URL}/users/{username}"

    # Register the user
    try:
        register_resp = requests.post(
            register_url,
            json={"username": username, "email": email, "password": password},
            timeout=TIMEOUT,
        )
        # Assert registration succeeded
        assert register_resp.status_code == 200, f"Register failed: {register_resp.text}"
        user_data = register_resp.json()
        assert user_data.get("username") == username
        assert user_data.get("email") == email

        # Now GET /users/{username}
        get_resp = requests.get(user_url, timeout=TIMEOUT)
        assert get_resp.status_code == 200, f"Get user failed: {get_resp.text}"
        user_profile = get_resp.json()

        # Validate expected user keys exist in response
        assert isinstance(user_profile, dict), "UserResponse should be an object"
        # Check must have username and email keys matching registered
        assert user_profile.get("username") == username
        assert user_profile.get("email") == email

    finally:
        # Cleanup: no DELETE endpoint detailed, so ignoring user cleanup
        # If there was a delete user endpoint, call it here
        pass

test_get_user_profile_existing_user()