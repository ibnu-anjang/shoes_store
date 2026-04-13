import requests
import uuid

BASE_URL = "http://localhost:8000"
TIMEOUT = 30


def test_post_register_with_new_user():
    unique_username = f"user_{uuid.uuid4().hex[:8]}"
    unique_email = f"{unique_username}@example.com"
    password = "Secret123"

    url = f"{BASE_URL}/register"
    headers = {"Content-Type": "application/json"}
    payload = {
        "username": unique_username,
        "email": unique_email,
        "password": password
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)
        assert response.status_code == 200, f"Expected status code 200 but got {response.status_code}"
        data = response.json()
        # Validate presence of important UserResponse fields (example)
        assert "username" in data and data["username"] == unique_username
        assert "email" in data and data["email"] == unique_email

    finally:
        # Cleanup: delete the created user if possible
        # According to PRD, there's no delete user endpoint,
        # so test cleanup might not be supportable.
        # But we try to delete if endpoint exists (not described), skip else.
        pass


test_post_register_with_new_user()