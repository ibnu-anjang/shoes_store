import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_postloginwithvalidcredentials():
    # First, register a user to ensure user exists for login
    register_url = f"{BASE_URL}/register"
    login_url = f"{BASE_URL}/login"
    username = "testuser_loginvalid"
    email = "testuser_loginvalid@example.com"
    password = "ValidPass123"

    register_payload = {
        "username": username,
        "email": email,
        "password": password
    }

    try:
        register_resp = requests.post(register_url, json=register_payload, timeout=TIMEOUT)
        # 200 if newly registered, or 400 if user exists - both acceptable to proceed
        assert register_resp.status_code in (200, 400)

        # Now perform login with valid credentials
        login_payload = {
            "username": username,
            "password": password
        }
        login_resp = requests.post(login_url, json=login_payload, timeout=TIMEOUT)
        assert login_resp.status_code == 200

        data = login_resp.json()
        assert "access_token" in data
        assert data["access_token"] == f"token-rahasia-{username}"
        assert "token_type" in data and isinstance(data["token_type"], str) and data["token_type"]
        assert data.get("username") == username
        assert data.get("email") == email
    except (requests.RequestException, AssertionError) as e:
        raise e

test_postloginwithvalidcredentials()