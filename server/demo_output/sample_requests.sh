#!/bin/bash

# Sample API requests for testing the Virtual Try-On Mock Server

BASE_URL="http://localhost:3000"
API_URL="$BASE_URL/api"

echo "🧪 Testing Virtual Try-On Mock Server APIs"
echo "=========================================="

# Health check
echo "1. Health Check:"
curl -s "$BASE_URL/health" | jq '.'
echo ""

# Mock login
echo "2. Mock Login:"
curl -s -X POST "$API_URL/auth/mock-login" \
  -H "Content-Type: application/json" \
  -d '{"userId": "demo_user_1"}' | jq '.'
echo ""

# Get products
echo "3. Get Products:"
curl -s "$API_URL/products?limit=5&category=tops" | jq '.'
echo ""

# Create cart
echo "4. Add Item to Cart:"
curl -s -X POST "$API_URL/cart" \
  -H "Authorization: Bearer mock_token" \
  -H "Content-Type: application/json" \
  -d '{"productId": "prod_1", "quantity": 1}' | jq '.'
echo ""

# Create order
echo "5. Create Order:"
curl -s -X POST "$API_URL/orders" \
  -H "Authorization: Bearer mock_token" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [{"productId": "prod_1", "quantity": 1}],
    "shippingAddress": {
      "street": "123 Main St",
      "city": "New York",
      "state": "NY",
      "zipCode": "10001",
      "country": "United States"
    }
  }' | jq '.'
echo ""

echo "✅ Sample API requests generated"
echo "Run this script after starting the server:"
echo "bash demo_output/sample_requests.sh"
