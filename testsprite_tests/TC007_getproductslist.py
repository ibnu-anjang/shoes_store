import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_get_products_list():
    url = f"{BASE_URL}/products"
    try:
        response = requests.get(url, timeout=TIMEOUT)
        assert response.status_code == 200, f"Expected status 200, got {response.status_code}"
        products = response.json()
        assert isinstance(products, list), f"Expected response to be a list, got {type(products)}"
        # Checking each item if present is a dict (likely ProductResponse object)
        for product in products:
            assert isinstance(product, dict), f"Expected product to be dict, got {type(product)}"
        # If empty list, that is also correct per requirements
    except requests.RequestException as e:
        assert False, f"Request failed: {e}"

test_get_products_list()