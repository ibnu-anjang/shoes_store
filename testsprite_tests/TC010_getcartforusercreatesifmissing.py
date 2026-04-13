import requests
import uuid

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_get_cart_for_user_creates_if_missing():
    username = f"testuser_{uuid.uuid4().hex[:8]}"
    password = "TestPass123!"
    email = f"{username}@example.com"

    # Register new user first
    register_url = f"{BASE_URL}/register"
    register_payload = {
        "username": username,
        "email": email,
        "password": password
    }
    try:
        register_resp = requests.post(register_url, json=register_payload, timeout=TIMEOUT)
        assert register_resp.status_code == 200, f"Failed to register user: {register_resp.text}"
        user_data = register_resp.json()
        assert user_data.get("username") == username

        # Request cart for the new user - cart should be created automatically if missing
        cart_url = f"{BASE_URL}/cart"
        params = {"username": username}
        cart_resp = requests.get(cart_url, params=params, timeout=TIMEOUT)
        assert cart_resp.status_code == 200, f"GET /cart failed: {cart_resp.text}"
        cart_data = cart_resp.json()

        # Validate required fields in CartResponse
        # CartResponse schema details not explicitly given,
        # so minimally check presence of expected keys like 'id', 'username', 'items'
        assert "id" in cart_data or "cart_id" in cart_data, "CartResponse missing 'id' field"
        # Validate username in returned cart matches requested username if present
        if "username" in cart_data:
            assert cart_data["username"] == username
        # Items may be empty list
        assert "items" in cart_data, "CartResponse missing 'items' field"
        assert isinstance(cart_data["items"], list)

    finally:
        # Cleanup by deleting the created user and cart if needed
        # No user delete endpoint specified.
        # Cart is created on-demand, no delete cart endpoint specified.
        # So cleanup is not implemented here due to lack of API support.
        pass

test_get_cart_for_user_creates_if_missing()