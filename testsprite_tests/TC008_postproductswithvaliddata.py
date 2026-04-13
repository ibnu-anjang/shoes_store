import requests
import uuid

BASE_URL = "http://localhost:8000"
TIMEOUT = 30

def test_post_products_with_valid_data():
    url = f"{BASE_URL}/products"
    product_data = {
        "name": "Test Shoe Model X",
        "price": 149.99,
        "description": "High quality running shoe with excellent support.",
        "image": "http://example.com/images/shoe-model-x.jpg",
        "category": "sport",
        "rating": 4.7,
        "skus": [
            {
                "size": "42",
                "stock": 50,
                "variant_name": "Model X Size 42",
                "price": 149.99
            },
            {
                "size": "43",
                "stock": 40,
                "variant_name": "Model X Size 43",
                "price": 149.99
            }
        ],
        "colors": [
            {
                "color_code": "BLK",
                "color_name": "Black",
                "color_hex": "#000000"
            },
            {
                "color_code": "RED",
                "color_name": "Red",
                "color_hex": "#FF0000"
            }
        ]
    }

    response = requests.post(url, json=product_data, timeout=TIMEOUT)
    
    try:
        # Validate response status
        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}. Response: {response.text}"
        
        # Validate response body schema keys presence for ProductResponse (basic check)
        json_resp = response.json()
        
        expected_keys = {"name", "price", "description", "image", "category", "rating", "skus", "colors"}
        for key in expected_keys:
            assert key in json_resp, f"Missing expected key in response: {key}"
        
        assert isinstance(json_resp["skus"], list) and len(json_resp["skus"]) == 2, "SKUs list missing or incorrect length"
        assert isinstance(json_resp["colors"], list) and len(json_resp["colors"]) == 2, "Colors list missing or incorrect length"

        for sku in json_resp["skus"]:
            assert "id" in sku and isinstance(sku["id"], int), "SKU missing id or incorrect type"
            assert "size" in sku and isinstance(sku["size"], str), "SKU missing size or incorrect type"
            # stock and other fields may or may not be returned, so no strict check
            assert "variant_name" in sku and isinstance(sku["variant_name"], str), "SKU missing variant_name or incorrect type"
            assert "price" in sku and (isinstance(sku["price"], float) or isinstance(sku["price"], int)), "SKU missing price or incorrect type"

        for color in json_resp["colors"]:
            assert "color_code" in color and isinstance(color["color_code"], str), "Color missing color_code or incorrect type"
            assert "color_name" in color and isinstance(color["color_name"], str), "Color missing color_name or incorrect type"
            # color_hex is optional but usually present, so check
            assert "color_hex" in color and isinstance(color["color_hex"], str), "Color missing color_hex or incorrect type"

    finally:
        # Attempt to clean up by deleting created product if product ID returned in response
        product_id = None
        try:
            product_id = json_resp.get("id")
        except Exception:
            product_id = None

        if product_id:
            try:
                del_response = requests.delete(f"{BASE_URL}/admin/products/{product_id}", timeout=TIMEOUT)
                assert del_response.status_code in (200, 404), f"Failed to delete product id {product_id}, status {del_response.status_code}"
            except Exception:
                pass

test_post_products_with_valid_data()
