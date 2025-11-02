# API Testing Guide

This guide provides comprehensive testing procedures, curl examples, and testing tools for the Virtual Try-On API.

## Table of Contents

- [Testing Environment Setup](#testing-environment-setup)
- [Authentication Testing](#authentication-testing)
- [Endpoint Testing Examples](#endpoint-testing-examples)
- [API Client Testing](#api-client-testing)
- [Performance Testing](#performance-testing)
- [Security Testing](#security-testing)
- [Error Handling Testing](#error-handling-testing)
- [Testing Tools & Utilities](#testing-tools--utilities)

## Testing Environment Setup

### Environment Variables

Set up testing environment variables:

```bash
# API Configuration
export API_BASE_URL="https://staging-api.tryon.com/v1"
export API_KEY="your_api_key_here"
export CLIENT_ID="your_client_id"
export CLIENT_SECRET="your_client_secret"

# Test User Credentials
export TEST_EMAIL="test@example.com"
export TEST_PASSWORD="TestPassword123!"
export TEST_USER_ID="usr_test123"

# File Paths
export AVATAR_MODEL_PATH="/path/to/test_avatar.glb"
export PRODUCT_IMAGE_PATH="/path/to/test_image.jpg"
export TEST_DATA_PATH="/path/to/test_data.json"
```

### Postman Collection

Import the complete API collection:

```json
{
  "info": {
    "name": "Virtual Try-On API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "baseUrl",
      "value": "{{API_BASE_URL}}"
    },
    {
      "key": "accessToken",
      "value": ""
    }
  ],
  "auth": {
    "type": "bearer",
    "bearer": [
      {
        "key": "token",
        "value": "{{accessToken}}",
        "type": "string"
      }
    ]
  },
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"{{TEST_EMAIL}}\",\n  \"password\": \"{{TEST_PASSWORD}}\"\n}"
            },
            "url": {
              "raw": "{{baseUrl}}/api/auth/login",
              "host": ["{{baseUrl}}"],
              "path": ["api", "auth", "login"]
            }
          }
        },
        {
          "name": "Register",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"newuser@example.com\",\n  \"password\": \"SecurePass123!\",\n  \"firstName\": \"Test\",\n  \"lastName\": \"User\",\n  \"agreeToTerms\": true\n}"
            },
            "url": {
              "raw": "{{baseUrl}}/api/auth/register",
              "host": ["{{baseUrl}}"],
              "path": ["api", "auth", "register"]
            }
          }
        },
        {
          "name": "Refresh Token",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"refreshToken\": \"{{refreshToken}}\"\n}"
            },
            "url": {
              "raw": "{{baseUrl}}/api/auth/refresh",
              "host": ["{{baseUrl}}"],
              "path": ["api", "auth", "refresh"]
            }
          }
        }
      ]
    },
    {
      "name": "Avatar Scanning",
      "item": [
        {
          "name": "Start Scan",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              },
              {
                "key": "Authorization",
                "value": "Bearer {{accessToken}}"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"scanType\": \"photo_based\",\n  \"images\": [\n    {\n      \"url\": \"https://storage.tryon.com/scans/test_front.jpg\",\n      \"pose\": \"front\",\n      \"quality\": 0.95\n    },\n    {\n      \"url\": \"https://storage.tryon.com/scans/test_side.jpg\",\n      \"pose\": \"side\",\n      \"quality\": 0.92\n    }\n  ]\n}"
            },
            "url": {
              "raw": "{{baseUrl}}/api/scan",
              "host": ["{{baseUrl}}"],
              "path": ["api", "scan"]
            }
          }
        },
        {
          "name": "Get Scan Status",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{accessToken}}"
              }
            ],
            "url": {
              "raw": "{{baseUrl}}/api/scan/{{scanId}}/status",
              "host": ["{{baseUrl}}"],
              "path": ["api", "scan", "{{scanId}}", "status"]
            }
          }
        },
        {
          "name": "Get Avatar",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{accessToken}}"
              }
            ],
            "url": {
              "raw": "{{baseUrl}}/api/avatar/{{avatarId}}",
              "host": ["{{baseUrl}}"],
              "path": ["api", "avatar", "{{avatarId}}"]
            }
          }
        }
      ]
    },
    {
      "name": "Products",
      "item": [
        {
          "name": "Get Products",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{accessToken}}"
              }
            ],
            "url": {
              "raw": "{{baseUrl}}/api/products?page=1&limit=20&category=tops",
              "host": ["{{baseUrl}}"],
              "path": ["api", "products"],
              "query": [
                {
                  "key": "page",
                  "value": "1"
                },
                {
                  "key": "limit",
                  "value": "20"
                },
                {
                  "key": "category",
                  "value": "tops"
                }
              ]
            }
          }
        },
        {
          "name": "Search Products",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{accessToken}}"
              }
            ],
            "url": {
              "raw": "{{baseUrl}}/api/products/search?q=blue%20t-shirt&limit=10",
              "host": ["{{baseUrl}}"],
              "path": ["api", "products", "search"],
              "query": [
                {
                  "key": "q",
                  "value": "blue t-shirt"
                },
                {
                  "key": "limit",
                  "value": "10"
                }
              ]
            }
          }
        }
      ]
    }
  ]
}
```

## Authentication Testing

### Basic Login Test

```bash
#!/bin/bash
# test_login.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
TEST_EMAIL="test@example.com"
TEST_PASSWORD="TestPassword123!"

# Test login endpoint
response=$(curl -s -X POST "$API_BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
  }")

echo "Login Response:"
echo "$response" | jq '.'

# Extract access token
access_token=$(echo "$response" | jq -r '.data.tokens.accessToken')
refresh_token=$(echo "$response" | jq -r '.data.tokens.refreshToken')

if [ "$access_token" != "null" ]; then
    echo "✅ Login successful"
    echo "Access Token: $access_token"
    echo "Refresh Token: $refresh_token"
else
    echo "❌ Login failed"
    exit 1
fi
```

### Token Refresh Test

```bash
#!/bin/bash
# test_token_refresh.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
REFRESH_TOKEN="your_refresh_token_here"

# Test token refresh
response=$(curl -s -X POST "$API_BASE_URL/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }")

echo "Token Refresh Response:"
echo "$response" | jq '.'

# Extract new access token
new_access_token=$(echo "$response" | jq -r '.data.tokens.accessToken')

if [ "$new_access_token" != "null" ]; then
    echo "✅ Token refresh successful"
    echo "New Access Token: $new_access_token"
else
    echo "❌ Token refresh failed"
    exit 1
fi
```

### Registration Test

```bash
#!/bin/bash
# test_registration.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser_${TIMESTAMP}@example.com"

# Test user registration
response=$(curl -s -X POST "$API_BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"SecurePass123!\",
    \"firstName\": \"Test\",
    \"lastName\": \"User\",
    \"agreeToTerms\": true
  }")

echo "Registration Response:"
echo "$response" | jq '.'

# Check registration status
success=$(echo "$response" | jq -r '.success')

if [ "$success" = "true" ]; then
    echo "✅ Registration successful for: $TEST_EMAIL"
else
    echo "❌ Registration failed"
    exit 1
fi
```

## Endpoint Testing Examples

### Avatar Scanning Test

```bash
#!/bin/bash
# test_avatar_scanning.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
ACCESS_TOKEN="your_access_token_here"

# Start avatar scan
echo "Starting avatar scan..."
scan_response=$(curl -s -X POST "$API_BASE_URL/api/scan" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "scanType": "photo_based",
    "images": [
      {
        "url": "https://storage.tryon.com/scans/test_front.jpg",
        "pose": "front",
        "quality": 0.95
      },
      {
        "url": "https://storage.tryon.com/scans/test_side.jpg",
        "pose": "side",
        "quality": 0.92
      },
      {
        "url": "https://storage.tryon.com/scans/test_back.jpg",
        "pose": "back",
        "quality": 0.88
      }
    ],
    "userPreferences": {
      "bodyType": "athletic",
      "height": 175,
      "weight": 70
    }
  }')

echo "Scan Response:"
echo "$scan_response" | jq '.'

# Extract scan ID
scan_id=$(echo "$scan_response" | jq -r '.data.scanId')

if [ "$scan_id" != "null" ]; then
    echo "✅ Scan initiated successfully"
    echo "Scan ID: $scan_id"
    
    # Monitor scan status
    echo "Monitoring scan status..."
    for i in {1..30}; do
        status_response=$(curl -s -X GET "$API_BASE_URL/api/scan/$scan_id/status" \
          -H "Authorization: Bearer $ACCESS_TOKEN")
        
        status=$(echo "$status_response" | jq -r '.data.status')
        progress=$(echo "$status_response" | jq -r '.data.progress')
        
        echo "Status: $status, Progress: $progress%"
        
        if [ "$status" = "completed" ]; then
            avatar_id=$(echo "$status_response" | jq -r '.data.avatarId')
            echo "✅ Scan completed successfully"
            echo "Avatar ID: $avatar_id"
            break
        elif [ "$status" = "failed" ]; then
            echo "❌ Scan failed"
            echo "$status_response" | jq '.'
            break
        fi
        
        sleep 10
    done
else
    echo "❌ Failed to initiate scan"
    exit 1
fi
```

### Product Catalog Test

```bash
#!/bin/bash
# test_products.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
ACCESS_TOKEN="your_access_token_here"

# Test products listing
echo "Testing products endpoint..."
products_response=$(curl -s -X GET "$API_BASE_URL/api/products?page=1&limit=10&category=tops" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Products Response:"
echo "$products_response" | jq '.'

# Validate response structure
total_items=$(echo "$products_response" | jq -r '.data.pagination.totalItems')
current_page=$(echo "$products_response" | jq -r '.data.pagination.currentPage')
products_count=$(echo "$products_response" | jq '.data.products | length')

if [ "$total_items" != "null" ] && [ "$current_page" = "1" ]; then
    echo "✅ Products endpoint working correctly"
    echo "Total items: $total_items, Current page: $current_page, Products on page: $products_count"
else
    echo "❌ Products endpoint response invalid"
    exit 1
fi

# Test product search
echo "Testing product search..."
search_response=$(curl -s -X GET "$API_BASE_URL/api/products/search?q=t-shirt&limit=5" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Search Response:"
echo "$search_response" | jq '.'

search_results=$(echo "$search_response" | jq '.data.products | length')
if [ "$search_results" != "null" ]; then
    echo "✅ Search endpoint working correctly"
    echo "Search results: $search_results"
else
    echo "❌ Search endpoint failed"
    exit 1
fi
```

### Try-On Rendering Test

```bash
#!/bin/bash
# test_tryon_rendering.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
ACCESS_TOKEN="your_access_token_here"
AVATAR_ID="avatar_test123"
PRODUCT_ID="prod_test456"

# Start try-on render
echo "Starting try-on render..."
render_response=$(curl -s -X POST "$API_BASE_URL/api/render/tryon" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"avatarId\": \"$AVATOR_ID\",
    \"productId\": \"$PRODUCT_ID\",
    \"pose\": {
      \"type\": \"preset\",
      \"presetName\": \"standing_neutral\"
    },
    \"lighting\": {
      \"type\": \"studio\",
      \"preset\": \"soft_daylight\",
      \"intensity\": 0.8
    },
    \"camera\": {
      \"angle\": \"front\",
      \"zoom\": 1.0
    },
    \"output\": {
      \"format\": \"png\",
      \"resolution\": \"1080p\",
      \"quality\": \"high\"
    }
  }")

echo "Render Response:"
echo "$render_response" | jq '.'

# Extract render ID
render_id=$(echo "$render_response" | jq -r '.data.renderId')

if [ "$render_id" != "null" ]; then
    echo "✅ Render initiated successfully"
    echo "Render ID: $render_id"
    
    # Monitor render status
    echo "Monitoring render status..."
    for i in {1..20}; do
        status_response=$(curl -s -X GET "$API_BASE_URL/api/render/$render_id/status" \
          -H "Authorization: Bearer $ACCESS_TOKEN")
        
        status=$(echo "$status_response" | jq -r '.data.status')
        progress=$(echo "$status_response" | jq -r '.data.progress')
        
        echo "Status: $status, Progress: $progress%"
        
        if [ "$status" = "completed" ]; then
            final_url=$(echo "$status_response" | jq -r '.data.finalUrl')
            echo "✅ Render completed successfully"
            echo "Final URL: $final_url"
            break
        elif [ "$status" = "failed" ]; then
            echo "❌ Render failed"
            echo "$status_response" | jq '.'
            break
        fi
        
        sleep 15
    done
else
    echo "❌ Failed to initiate render"
    exit 1
fi
```

### Cart & Orders Test

```bash
#!/bin/bash
# test_cart_orders.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
ACCESS_TOKEN="your_access_token_here"

# Test cart operations
echo "Testing cart operations..."

# Add item to cart
add_response=$(curl -s -X POST "$API_BASE_URL/api/cart/add" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "prod_test123",
    "variantId": "var_test123_001",
    "quantity": 1
  }')

echo "Add to Cart Response:"
echo "$add_response" | jq '.'

# Get cart
cart_response=$(curl -s -X GET "$API_BASE_URL/api/cart" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Cart Response:"
echo "$cart_response" | jq '.'

item_count=$(echo "$cart_response" | jq -r '.data.itemCount')
total=$(echo "$cart_response" | jq -r '.data.total')

if [ "$item_count" != "0" ]; then
    echo "✅ Cart operations working correctly"
    echo "Items in cart: $item_count, Total: $total"
else
    echo "❌ Cart operations failed"
    exit 1
fi

# Create order
echo "Testing order creation..."
order_response=$(curl -s -X POST "$API_BASE_URL/api/order/create" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "cartId": "cart_test123",
    "shippingAddress": {
      "firstName": "Test",
      "lastName": "User",
      "street": "123 Test St",
      "city": "Test City",
      "state": "TS",
      "zipCode": "12345",
      "country": "US"
    },
    "shippingMethod": "standard"
  }')

echo "Order Creation Response:"
echo "$order_response" | jq '.'

order_id=$(echo "$order_response" | jq -r '.data.order.id')
if [ "$order_id" != "null" ]; then
    echo "✅ Order created successfully"
    echo "Order ID: $order_id"
else
    echo "❌ Order creation failed"
    exit 1
fi
```

## API Client Testing

### Flutter Integration Test

```dart
// test/integration/api_client_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:virtual_try_on/core/api/client.dart';
import 'package:virtual_try_on/core/api/endpoints/auth_endpoints.dart';

class MockDio extends Mock implements Dio {}

class MockTokenManager extends Mock implements TokenManager {}

void main() {
  group('ApiClient Integration Tests', () {
    late ApiClient apiClient;
    late MockDio mockDio;
    late MockTokenManager mockTokenManager;

    setUp(() {
      mockDio = MockDio();
      mockTokenManager = MockTokenManager();
      apiClient = ApiClient();
      
      // Override dio getter
      apiClient.dio = mockDio;
    });

    test('should successfully authenticate user', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      
      final mockResponse = Response(
        data: {
          'success': true,
          'data': {
            'user': {
              'id': 'usr_test123',
              'email': email,
              'firstName': 'Test',
              'lastName': 'User'
            },
            'tokens': {
              'accessToken': 'test_access_token',
              'refreshToken': 'test_refresh_token'
            }
          }
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/login'),
      );

      when(mockDio.post('/api/auth/login', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse);

      when(mockTokenManager.storeTokens(any))
          .thenAnswer((_) async {});

      // Act
      final authEndpoints = AuthEndpoints(apiClient);
      final response = await authEndpoints.login(
        LoginRequest(email: email, password: password),
      );

      // Assert
      expect(response.success, true);
      expect(response.data.user.email, email);
      expect(response.data.tokens.accessToken, 'test_access_token');
      
      verify(mockTokenManager.storeTokens(response.data.tokens)).called(1);
    });

    test('should handle network errors gracefully', () async {
      // Arrange
      when(mockDio.get('/api/products'))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/api/products'),
            error: 'Network error',
          ));

      // Act & Assert
      expect(
        () => apiClient.get('/api/products'),
        throwsA(isA<AppException>()),
      );
    });

    test('should handle rate limiting', () async {
      // Arrange
      final mockResponse = Response(
        data: {
          'success': false,
          'error': {
            'code': 'RATE_LIMIT_EXCEEDED',
            'message': 'Too many requests'
          }
        },
        statusCode: 429,
        requestOptions: RequestOptions(path: '/api/products'),
      );

      when(mockDio.get('/api/products'))
          .thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => apiClient.get('/api/products'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
```

### Unit Testing for Models

```dart
// test/unit/models/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_try_on/core/api/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('should deserialize user from JSON', () {
      // Arrange
      final json = {
        'id': 'usr_test123',
        'email': 'test@example.com',
        'firstName': 'Test',
        'lastName': 'User',
        'avatar': 'https://example.com/avatar.jpg',
        'emailVerified': true,
        'phoneVerified': false,
        'createdAt': '2025-01-15T10:30:00Z',
        'updatedAt': '2025-01-15T10:30:00Z'
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, 'usr_test123');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
      expect(user.emailVerified, true);
      expect(user.phoneVerified, false);
    });

    test('should serialize user to JSON', () {
      // Arrange
      const user = User(
        id: 'usr_test123',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        emailVerified: true,
        phoneVerified: false,
        createdAt: '2025-01-15T10:30:00Z',
        updatedAt: '2025-01-15T10:30:00Z',
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['id'], 'usr_test123');
      expect(json['email'], 'test@example.com');
      expect(json['firstName'], 'Test');
      expect(json['lastName'], 'User');
    });

    test('should create copy with updated fields', () {
      // Arrange
      const original = User(
        id: 'usr_test123',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        emailVerified: false,
        phoneVerified: false,
        createdAt: '2025-01-15T10:30:00Z',
        updatedAt: '2025-01-15T10:30:00Z',
      );

      // Act
      final updated = original.copyWith(emailVerified: true);

      // Assert
      expect(updated.emailVerified, true);
      expect(updated.email, original.email);
      expect(updated.firstName, original.firstName);
    });
  });
}
```

## Performance Testing

### Load Testing with Artillery

```yaml
# load-test.yml
config:
  target: 'https://staging-api.tryon.com/v1'
  phases:
    - duration: 60
      arrivalRate: 10
    - duration: 120
      arrivalRate: 50
    - duration: 60
      arrivalRate: 100
  payload:
    path: "test-data.csv"
    fields:
      - "email"
      - "password"
  variables:
    accessToken: ""

scenarios:
  - name: "User Journey"
    flow:
      - post:
          url: "/api/auth/login"
          json:
            email: "{{email}}"
            password: "{{password}}"
          capture:
            - json: "$.data.tokens.accessToken"
              as: "accessToken"
      
      - get:
          url: "/api/products?limit=20"
          headers:
            Authorization: "Bearer {{accessToken}}"
          expect:
            - statusCode: 200
            - hasProperty: "data.products"
      
      - post:
          url: "/api/scan"
          headers:
            Authorization: "Bearer {{accessToken}}"
          json:
            scanType: "photo_based"
            images:
              - url: "https://storage.tryon.com/scans/test_front.jpg"
                pose: "front"
                quality: 0.95
          expect:
            - statusCode: 202
            - hasProperty: "data.scanId"
```

### Stress Testing Script

```bash
#!/bin/bash
# stress_test.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
ACCESS_TOKEN="your_access_token_here"
CONCURRENT_USERS=50
TEST_DURATION=300  # 5 minutes

echo "Starting stress test with $CONCURRENT_USERS concurrent users for $TEST_DURATION seconds"

# Function to simulate user activity
simulate_user() {
    local user_id=$1
    local start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION))
    
    echo "User $user_id starting..."
    
    while [ $(date +%s) -lt $end_time ]; do
        # Simulate API calls
        curl -s "$API_BASE_URL/api/products?limit=10" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -w "User $user_id: %{http_code} in %{time_total}s\n" \
            -o /dev/null
        
        # Random delay between requests
        sleep $((RANDOM % 5 + 1))
    done
    
    echo "User $user_id finished"
}

# Start concurrent users
for i in $(seq 1 $CONCURRENT_USERS); do
    simulate_user $i &
done

# Wait for all users to complete
wait

echo "Stress test completed"

# Collect metrics
echo "Collecting performance metrics..."
echo "Total requests: $(($CONCURRENT_USERS * ($TEST_DURATION / 3)))"
```

## Security Testing

### Authentication Security Tests

```bash
#!/bin/bash
# security_test.sh

API_BASE_URL="https://staging-api.tryon.com/v1"

echo "Running security tests..."

# Test 1: Unauthorized access
echo "Test 1: Unauthorized access to protected endpoint"
response=$(curl -s -w "%{http_code}" "$API_BASE_URL/api/profile" -o /dev/null)
if [ "$response" = "401" ]; then
    echo "✅ Correctly rejected unauthorized access"
else
    echo "❌ Security issue: Expected 401, got $response"
fi

# Test 2: Invalid token
echo "Test 2: Invalid access token"
response=$(curl -s -w "%{http_code}" "$API_BASE_URL/api/profile" \
    -H "Authorization: Bearer invalid_token" -o /dev/null)
if [ "$response" = "401" ]; then
    echo "✅ Correctly rejected invalid token"
else
    echo "❌ Security issue: Expected 401, got $response"
fi

# Test 3: SQL injection attempt
echo "Test 3: SQL injection attempt"
response=$(curl -s -w "%{http_code}" "$API_BASE_URL/api/products/search?q='; DROP TABLE users; --" \
    -H "Authorization: Bearer $ACCESS_TOKEN" -o /dev/null)
if [ "$response" = "400" ]; then
    echo "✅ Correctly rejected SQL injection attempt"
else
    echo "❌ Security issue: Expected 400, got $response"
fi

# Test 4: XSS attempt
echo "Test 4: XSS attempt"
response=$(curl -s -w "%{http_code}" "$API_BASE_URL/api/products/search?q=<script>alert('xss')</script>" \
    -H "Authorization: Bearer $ACCESS_TOKEN" -o /dev/null)
if [ "$response" = "400" ]; then
    echo "✅ Correctly rejected XSS attempt"
else
    echo "❌ Security issue: Expected 400, got $response"
fi

# Test 5: Rate limiting
echo "Test 5: Rate limiting"
failed_requests=0
for i in {1..105}; do
    response=$(curl -s -w "%{http_code}" "$API_BASE_URL/api/products" \
        -H "Authorization: Bearer $ACCESS_TOKEN" -o /dev/null)
    if [ "$response" = "429" ]; then
        failed_requests=$((failed_requests + 1))
    fi
done

if [ $failed_requests -gt 0 ]; then
    echo "✅ Rate limiting working correctly ($failed_requests requests throttled)"
else
    echo "❌ Rate limiting not working"
fi

echo "Security tests completed"
```

### Penetration Testing Script

```bash
#!/bin/bash
# pentest.sh

API_BASE_URL="https://staging-api.tryon.com/v1"

echo "Running penetration tests..."

# Test for information disclosure
echo "Testing for information disclosure..."
curl -s "$API_BASE_URL/api/nonexistent" -v 2>&1 | grep -i "server\|version\|stack\|error"
echo "Information disclosure test completed"

# Test for directory traversal
echo "Testing for directory traversal..."
for payload in "../../../etc/passwd" "..\\..\\..\\windows\\system32\\drivers\\etc\\hosts" "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"; do
    response=$(curl -s "$API_BASE_URL/api/products/search?q=$payload" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    if echo "$response" | grep -q "root:\|localhost\|# Copyright"; then
        echo "❌ Directory traversal vulnerability found with payload: $payload"
    fi
done

# Test for command injection
echo "Testing for command injection..."
for payload in "; ls -la" "| whoami" "&& cat /etc/passwd" "`id`"; do
    response=$(curl -s "$API_BASE_URL/api/products/search?q=test $payload" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    if echo "$response" | grep -q "uid=\|gid=\|groups=\|root:"; then
        echo "❌ Command injection vulnerability found with payload: $payload"
    fi
done

echo "Penetration tests completed"
```

## Error Handling Testing

### HTTP Status Code Tests

```bash
#!/bin/bash
# test_http_status_codes.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
ACCESS_TOKEN="your_access_token_here"

echo "Testing HTTP status codes..."

declare -A expected_status=(
    ["GET:/api/products"]="200"
    ["GET:/api/products/nonexistent"]="404"
    ["POST:/api/auth/login"]="200"
    ["POST:/api/auth/login_invalid"]="400"
    ["POST:/api/scan"]="202"
    ["GET:/api/scan/nonexistent/status"]="404"
    ["GET:/api/profile"]="200"
    ["GET:/api/profile_without_auth"]="401"
    ["POST:/api/render/tryon"]="202"
    ["GET:/api/render/nonexistent/status"]="404"
)

for test_case in "${!expected_status[@]}"; do
    IFS=':' read -r method endpoint <<< "$test_case"
    expected=${expected_status[$test_case]}
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "%{http_code}" "$API_BASE_URL$endpoint" \
            -H "Authorization: Bearer $ACCESS_TOKEN" -o /dev/null)
    else
        response=$(curl -s -w "%{http_code}" -X "$method" "$API_BASE_URL$endpoint" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{}' -o /dev/null)
    fi
    
    if [ "$response" = "$expected" ]; then
        echo "✅ $method $endpoint -> $response (expected $expected)"
    else
        echo "❌ $method $endpoint -> $response (expected $expected)"
    fi
done

echo "HTTP status code tests completed"
```

### Error Response Format Tests

```bash
#!/bin/bash
# test_error_formats.sh

API_BASE_URL="https://staging-api.tryon.com/v1"

echo "Testing error response formats..."

# Test validation error
echo "Testing validation error..."
response=$(curl -s "$API_BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email": "invalid-email", "password": "123"}')

success=$(echo "$response" | jq -r '.success')
code=$(echo "$response" | jq -r '.error.code')
message=$(echo "$response" | jq -r '.error.message')

if [ "$success" = "false" ] && [ "$code" = "VALIDATION_ERROR" ] && [ "$message" != "null" ]; then
    echo "✅ Validation error format correct"
    echo "$response" | jq '.'
else
    echo "❌ Validation error format incorrect"
    echo "$response" | jq '.'
fi

# Test rate limit error
echo "Testing rate limit error..."
for i in {1..105}; do
    curl -s "$API_BASE_URL/api/products" \
        -H "Authorization: Bearer invalid_token" > /dev/null
done

rate_limit_response=$(curl -s "$API_BASE_URL/api/products" \
    -H "Authorization: Bearer invalid_token")

success=$(echo "$rate_limit_response" | jq -r '.success')
code=$(echo "$rate_limit_response" | jq -r '.error.code')

if [ "$success" = "false" ] && [ "$code" = "RATE_LIMIT_EXCEEDED" ]; then
    echo "✅ Rate limit error format correct"
else
    echo "❌ Rate limit error format incorrect"
    echo "$rate_limit_response" | jq '.'
fi

echo "Error response format tests completed"
```

## Testing Tools & Utilities

### Automated Test Suite

```bash
#!/bin/bash
# run_full_test_suite.sh

API_BASE_URL="https://staging-api.tryon.com/v1"
TEST_EMAIL="test@example.com"
TEST_PASSWORD="TestPassword123!"

echo "🚀 Starting comprehensive API test suite..."

# Create test results directory
mkdir -p test-results
TIMESTAMP=$(date +%s)
RESULTS_DIR="test-results/$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

# Run individual test suites
echo "📋 Running authentication tests..."
bash test_authentication.sh > "$RESULTS_DIR/auth_test.log" 2>&1

echo "📋 Running avatar scanning tests..."
bash test_avatar_scanning.sh > "$RESULTS_DIR/avatar_test.log" 2>&1

echo "📋 Running product tests..."
bash test_products.sh > "$RESULTS_DIR/product_test.log" 2>&1

echo "📋 Running try-on tests..."
bash test_tryon_rendering.sh > "$RESULTS_DIR/tryon_test.log" 2>&1

echo "📋 Running cart & order tests..."
bash test_cart_orders.sh > "$RESULTS_DIR/cart_test.log" 2>&1

echo "📋 Running security tests..."
bash security_test.sh > "$RESULTS_DIR/security_test.log" 2>&1

echo "📋 Running performance tests..."
bash stress_test.sh > "$RESULTS_DIR/performance_test.log" 2>&1

# Generate test report
echo "📊 Generating test report..."
{
    echo "# API Test Suite Results - $(date)"
    echo ""
    echo "## Test Summary"
    echo ""
    
    for log_file in "$RESULTS_DIR"/*.log; do
        test_name=$(basename "$log_file" .log)
        passed=$(grep -c "✅" "$log_file" || echo 0)
        failed=$(grep -c "❌" "$log_file" || echo 0)
        total=$((passed + failed))
        
        if [ $total -gt 0 ]; then
            pass_rate=$((passed * 100 / total))
            echo "- **$test_name**: $passed/$total passed ($pass_rate%)"
        fi
    done
    
    echo ""
    echo "## Detailed Results"
    echo ""
    
    for log_file in "$RESULTS_DIR"/*.log; do
        test_name=$(basename "$log_file" .log)
        echo "### $test_name"
        echo ""
        echo '```'
        tail -20 "$log_file"
        echo '```'
        echo ""
    done
    
} > "$RESULTS_DIR/test_report.md"

echo "✅ Test suite completed"
echo "📄 Results saved to: $RESULTS_DIR"
echo "📊 View report: $RESULTS_DIR/test_report.md"

# Summary
total_tests=$(find "$RESULTS_DIR" -name "*.log" -exec grep -c "✅\|❌" {} \; | awk '{sum += $1} END {print sum}')
total_passed=$(find "$RESULTS_DIR" -name "*.log" -exec grep -c "✅" {} \; | awk '{sum += $1} END {print sum}')
total_failed=$((total_tests - total_passed))

echo ""
echo "🎯 Test Summary:"
echo "Total Tests: $total_tests"
echo "Passed: $total_passed"
echo "Failed: $total_failed"

if [ $total_failed -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed. Please review the logs."
    exit 1
fi
```

### Test Data Generator

```javascript
// test-data-generator.js
const fs = require('fs');

// Generate test user data
const generateTestUsers = (count) => {
    const users = [];
    for (let i = 1; i <= count; i++) {
        users.push({
            email: `testuser${i}@example.com`,
            password: 'TestPassword123!',
            firstName: `Test${i}`,
            lastName: `User${i}`,
            dateOfBirth: '1990-01-01',
            agreeToTerms: true
        });
    }
    return users;
};

// Generate test products
const generateTestProducts = (count) => {
    const products = [];
    const categories = ['tops', 'bottoms', 'dresses', 'outerwear'];
    const brands = ['BrandA', 'BrandB', 'BrandC'];
    
    for (let i = 1; i <= count; i++) {
        products.push({
            name: `Test Product ${i}`,
            description: `Description for test product ${i}`,
            price: Math.random() * 100 + 10,
            category: categories[Math.floor(Math.random() * categories.length)],
            brand: brands[Math.floor(Math.random() * brands.length)],
            tryonAvailable: Math.random() > 0.2,
            rating: {
                average: Math.random() * 5,
                count: Math.floor(Math.random() * 1000)
            }
        });
    }
    return products;
};

// Generate test scan requests
const generateScanRequests = (count) => {
    const requests = [];
    const poses = ['front', 'side', 'back'];
    
    for (let i = 1; i <= count; i++) {
        const images = [];
        for (let j = 0; j < 3; j++) {
            images.push({
                url: `https://storage.tryon.com/scans/test_${i}_${j}.jpg`,
                pose: poses[j],
                quality: Math.random() * 0.3 + 0.7
            });
        }
        
        requests.push({
            scanType: 'photo_based',
            images: images,
            userPreferences: {
                bodyType: ['slim', 'athletic', 'curvy'][Math.floor(Math.random() * 3)],
                height: Math.floor(Math.random() * 100) + 150,
                weight: Math.floor(Math.random() * 50) + 50
            }
        });
    }
    return requests;
};

// Generate test files
console.log('Generating test data...');

// Generate CSV for load testing
const users = generateTestUsers(100);
const csvHeader = 'email,password\n';
const csvData = users.map(u => `${u.email},${u.password}`).join('\n');
fs.writeFileSync('test-data.csv', csvHeader + csvData);

// Generate JSON for API testing
const testData = {
    users: generateTestUsers(10),
    products: generateTestProducts(50),
    scanRequests: generateScanRequests(20)
};
fs.writeFileSync('test-data.json', JSON.stringify(testData, null, 2));

console.log('✅ Test data generated:');
console.log('- test-data.csv (for load testing)');
console.log('- test-data.json (for API testing)');
```

This comprehensive testing guide provides all the tools and scripts needed to thoroughly test the Virtual Try-On API, ensuring reliability, security, and performance.