import requests

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_post_products_with_invalid_data():
    url = f"{BASE_URL}/products"
    headers = {"Content-Type": "application/json"}

    # Test case 1: Missing required fields (e.g., missing "name", "price", "skus", "colors")
    invalid_payloads = [
        # Missing 'name'
        {
            "price": 49.99,
            "description": "Test product missing name",
            "image": "http://example.com/image.jpg",
            "category": "sport",
            "rating": 4.0,
            "skus": [{"sku": "SKU001", "stock": 10}],
            "colors": [{"name": "red", "hex": "#FF0000"}]
        },
        # Missing 'price'
        {
            "name": "Invalid Product",
            "description": "Test product missing price",
            "image": "http://example.com/image.jpg",
            "category": "sport",
            "rating": 4.0,
            "skus": [{"sku": "SKU002", "stock": 10}],
            "colors": [{"name": "blue", "hex": "#0000FF"}]
        },
        # Missing 'skus'
        {
            "name": "Invalid Product",
            "price": 59.99,
            "description": "Test product missing skus",
            "image": "http://example.com/image.jpg",
            "category": "sport",
            "rating": 4.0,
            "colors": [{"name": "green", "hex": "#00FF00"}]
        },
        # Missing 'colors'
        {
            "name": "Invalid Product",
            "price": 59.99,
            "description": "Test product missing colors",
            "image": "http://example.com/image.jpg",
            "category": "sport",
            "rating": 4.0,
            "skus": [{"sku": "SKU004", "stock": 10}]
        },
    ]

    for payload in invalid_payloads:
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)
            # Expecting 422 status code due to validation errors
            assert response.status_code == 422, f"Expected 422 but got {response.status_code} for payload missing required field"
        except requests.RequestException as e:
            assert False, f"Request failed for invalid data (missing required): {e}"

    # Test case 2: Duplicate SKU data within 'skus' array (duplicate SKU strings in same product)
    duplicate_sku_payload = {
        "name": "Product with Duplicate SKUs",
        "price": 79.99,
        "description": "Test product with duplicate SKUs",
        "image": "http://example.com/image.jpg",
        "category": "casual",
        "rating": 4.2,
        "skus": [
            {"sku": "DUPSKU01", "stock": 5},
            {"sku": "DUPSKU01", "stock": 10}  # Duplicate SKU
        ],
        "colors": [
            {"name": "black", "hex": "#000000"}
        ]
    }

    try:
        response = requests.post(url, json=duplicate_sku_payload, headers=headers, timeout=TIMEOUT)
        # Expecting 422 status code for duplicate SKU error (validation error)
        assert response.status_code == 422, f"Expected 422 but got {response.status_code} for duplicate SKU payload"
    except requests.RequestException as e:
        assert False, f"Request failed for duplicate SKU data: {e}"

test_post_products_with_invalid_data()
