# API Endpoint Reference

This document provides a comprehensive reference for all API endpoints in the Virtual Try-On system.

## Table of Contents

- [Authentication](#authentication)
- [Avatar Scanning](#avatar-scanning)
- [Product Catalog](#product-catalog)
- [Try-On Rendering](#try-on-rendering)
- [Shopping Cart](#shopping-cart)
- [Order Management](#order-management)
- [User Profile](#user-profile)
- [Virtual Closet](#virtual-closet)
- [Payment Processing](#payment-processing)

## Authentication

### POST /api/auth/login

Authenticate user with email/password or social login.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_123456789",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "avatar": "https://cdn.tryon.com/avatars/usr_123456789.jpg",
      "emailVerified": true,
      "createdAt": "2025-01-15T10:30:00Z"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "accessTokenExpires": "2025-01-15T11:30:00Z",
      "refreshToken": "refresh_token_abc123",
      "refreshTokenExpires": "2025-01-22T10:30:00Z"
    }
  }
}
```

**Headers:**
- `Authorization: Bearer {accessToken}` - Required for all authenticated endpoints
- `Set-Cookie: refresh_token={refreshToken}; HttpOnly; Secure; SameSite=Strict` - HTTP-only refresh token

### POST /api/auth/register

Register a new user account.

**Request:**
```json
{
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "firstName": "Jane",
  "lastName": "Smith",
  "dateOfBirth": "1995-08-15",
  "agreeToTerms": true,
  "marketingConsent": false
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_987654321",
      "email": "newuser@example.com",
      "firstName": "Jane",
      "lastName": "Smith",
      "emailVerified": false,
      "createdAt": "2025-01-15T10:30:00Z"
    },
    "verificationEmailSent": true,
    "emailVerificationRequired": true
  }
}
```

### POST /api/auth/refresh

Refresh expired access token.

**Request:**
```json
{
  "refreshToken": "refresh_token_abc123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "accessTokenExpires": "2025-01-15T12:30:00Z",
      "refreshToken": "refresh_token_xyz456",
      "refreshTokenExpires": "2025-01-22T10:30:00Z"
    }
  }
}
```

## Avatar Scanning

### POST /api/scan

Start 3D avatar scanning process.

**Request:**
```json
{
  "scanType": "photo_based",
  "images": [
    {
      "url": "https://storage.tryon.com/scans/tmp_1.jpg",
      "pose": "front",
      "quality": 0.95
    },
    {
      "url": "https://storage.tryon.com/scans/tmp_2.jpg",
      "pose": "side",
      "quality": 0.92
    },
    {
      "url": "https://storage.tryon.com/scans/tmp_3.jpg",
      "pose": "back",
      "quality": 0.88
    }
  ],
  "userPreferences": {
    "bodyType": "athletic",
    "height": 175,
    "weight": 70,
    "preferences": ["casual", "business"]
  }
}
```

**Response (202):**
```json
{
  "success": true,
  "data": {
    "scanId": "scan_789xyz123",
    "status": "processing",
    "estimatedTimeMinutes": 5,
    "queuePosition": 3,
    "createdAt": "2025-01-15T10:30:00Z",
    "webhookUrl": "https://app.tryon.com/webhooks/scan-complete"
  }
}
```

### GET /api/scan/{id}/status

Check scan processing status.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "scanId": "scan_789xyz123",
    "status": "processing",
    "progress": 65,
    "stage": "mesh_generation",
    "estimatedTimeRemaining": 120,
    "messages": [
      "Analyzing input images...",
      "Generating 3D mesh...",
      "Applying texture mapping..."
    ]
  }
}
```

**Status Values:**
- `queued` - Waiting in processing queue
- `processing` - Currently being processed
- `completed` - Successfully completed
- `failed` - Processing failed

### GET /api/avatar/{id}

Retrieve completed avatar data.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "avatar_abc456def",
    "name": "My Avatar",
    "status": "active",
    "model": {
      "url": "https://cdn.tryon.com/models/avatar_abc456def.glb",
      "format": "glb",
      "size": "12.4MB",
      "polycount": 15420,
      "textures": ["diffuse", "normal", "roughness"]
    },
    "preview": {
      "thumbnail": "https://cdn.tryon.com/previews/avatar_abc456def_thumb.jpg",
      "fullSize": "https://cdn.tryon.com/previews/avatar_abc456def_full.jpg"
    },
    "createdAt": "2025-01-15T10:35:00Z",
    "updatedAt": "2025-01-15T10:35:00Z"
  }
}
```

## Product Catalog

### GET /api/products

Get paginated products with filtering.

**Query Parameters:**
- `page` (integer, default: 1) - Page number
- `limit` (integer, default: 20, max: 100) - Items per page
- `category` (string) - Filter by category
- `brand` (string) - Filter by brand
- `priceMin` (number) - Minimum price
- `priceMax` (number) - Maximum price
- `size` (array) - Available sizes
- `color` (array) - Available colors
- `sortBy` (enum: name, price_asc, price_desc, rating, newest, popularity)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": "prod_123abc456",
        "name": "Premium Cotton T-Shirt",
        "description": "High-quality cotton blend t-shirt with modern fit",
        "price": 49.99,
        "originalPrice": 69.99,
        "currency": "USD",
        "brand": "FashionBrand",
        "category": "tops",
        "subcategory": "shirts",
        "images": [
          {
            "url": "https://cdn.tryon.com/products/prod_123abc456_front.jpg",
            "type": "front",
            "resolution": "high"
          }
        ],
        "model3D": {
          "url": "https://cdn.tryon.com/models/prod_123abc456.glb",
          "format": "glb",
          "size": "8.2MB",
          "polycount": 8450
        },
        "variants": [
          {
            "id": "var_123_001",
            "size": "M",
            "color": "blue",
            "colorHex": "#2563EB",
            "stock": 25,
            "sku": "TSH-001-M-BLU"
          }
        ],
        "rating": {
          "average": 4.3,
          "count": 127
        },
        "tryonAvailable": true,
        "createdAt": "2025-01-10T12:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 25,
      "totalItems": 487,
      "itemsPerPage": 20,
      "hasNext": true,
      "hasPrevious": false
    }
  }
}
```

### GET /api/products/{id}

Get detailed product information.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "prod_123abc456",
    "name": "Premium Cotton T-Shirt",
    "description": "High-quality cotton blend t-shirt with modern fit",
    "detailedDescription": "Made from premium organic cotton...",
    "price": 49.99,
    "originalPrice": 69.99,
    "currency": "USD",
    "brand": "FashionBrand",
    "category": "tops",
    "subcategory": "shirts",
    "specifications": {
      "material": "100% Organic Cotton",
      "care": "Machine wash cold",
      "origin": "Made in Portugal"
    },
    "sizing": {
      "fit": "regular",
      "sizeGuide": {
        "S": {"chest": 36, "waist": 30, "shoulder": 17, "sleeve": 25},
        "M": {"chest": 38, "waist": 32, "shoulder": 18, "sleeve": 26}
      }
    },
    "images": [...],
    "model3D": {...},
    "variants": [...],
    "rating": {
      "average": 4.3,
      "count": 127
    },
    "reviews": [
      {
        "id": "rev_001",
        "userId": "usr_123",
        "userName": "Fashion Lover",
        "rating": 5,
        "title": "Great quality!",
        "comment": "This shirt is amazing...",
        "helpful": 12,
        "verified": true,
        "createdAt": "2025-01-10T14:30:00Z"
      }
    ],
    "tryonAvailable": true,
    "createdAt": "2025-01-10T12:00:00Z"
  }
}
```

### GET /api/products/search

Search products with text query.

**Query Parameters:**
- `q` (string, required) - Search query (min 2 chars)
- `suggest` (boolean) - Return search suggestions
- `limit` (integer, max: 50) - Maximum results

**Response (200):**
```json
{
  "success": true,
  "data": {
    "products": [...],
    "suggestions": [
      {"text": "blue jeans", "type": "category"},
      {"text": "denim jacket", "type": "product"}
    ],
    "totalResults": 156
  }
}
```

## Try-On Rendering

### POST /api/render/tryon

Generate 3D virtual try-on render.

**Request:**
```json
{
  "avatarId": "avatar_abc456def",
  "productId": "prod_123abc456",
  "variantId": "var_123_001",
  "pose": {
    "type": "preset",
    "presetName": "standing_neutral",
    "customAdjustments": {
      "arm_rotation": 15,
      "leg_position": "slightly_apart"
    }
  },
  "lighting": {
    "type": "studio",
    "preset": "soft_daylight",
    "intensity": 0.8
  },
  "camera": {
    "angle": "front",
    "zoom": 1.0,
    "perspective": "realistic"
  },
  "output": {
    "format": "png",
    "resolution": "1080p",
    "quality": "high",
    "background": "transparent"
  }
}
```

**Response (202):**
```json
{
  "success": true,
  "data": {
    "renderId": "render_xyz789abc",
    "status": "processing",
    "estimatedTimeMinutes": 3,
    "queuePosition": 1,
    "createdAt": "2025-01-15T10:40:00Z",
    "webhookUrl": "https://app.tryon.com/webhooks/render-complete"
  }
}
```

### GET /api/render/{id}/status

Check render processing status.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "renderId": "render_xyz789abc",
    "status": "processing",
    "progress": 45,
    "stage": "mesh_fitting",
    "estimatedTimeRemaining": 90,
    "previewUrl": "https://cdn.tryon.com/renders/render_xyz789abc_preview.jpg"
  }
}
```

## Shopping Cart

### GET /api/cart

Get user's shopping cart.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "cart_abc123def456",
    "items": [
      {
        "id": "cart_item_001",
        "product": {
          "id": "prod_123abc456",
          "name": "Premium Cotton T-Shirt",
          "price": 49.99,
          "image": "https://cdn.tryon.com/products/prod_123abc456_front.jpg"
        },
        "quantity": 1,
        "addedAt": "2025-01-15T10:30:00Z"
      }
    ],
    "subtotal": 49.99,
    "tax": 4.00,
    "shipping": 5.99,
    "discount": 0,
    "total": 59.98,
    "itemCount": 1,
    "estimatedDelivery": "2025-01-18",
    "updatedAt": "2025-01-15T10:30:00Z"
  }
}
```

### POST /api/cart/add

Add item to cart.

**Request:**
```json
{
  "productId": "prod_123abc456",
  "variantId": "var_123_001",
  "quantity": 1,
  "metadata": {
    "tryonRenderId": "render_xyz789abc",
    "size_confirmed": true,
    "color_confirmed": true
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "cartItem": {...},
    "cart": {...}
  }
}
```

### DELETE /api/cart/item/{itemId}

Remove specific item from cart.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "Item removed from cart successfully"
  }
}
```

### PUT /api/cart/item/{itemId}/quantity

Update item quantity.

**Request:**
```json
{
  "quantity": 2,
  "operation": "set"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "cartItem": {...},
    "cart": {...}
  }
}
```

## Order Management

### POST /api/order/create

Create new order from cart.

**Request:**
```json
{
  "cartId": "cart_abc123def456",
  "shippingAddress": {
    "firstName": "John",
    "lastName": "Doe",
    "street": "123 Main St",
    "apartment": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "US",
    "phone": "+1-555-0123"
  },
  "billingAddress": {
    "sameAsShipping": true
  },
  "paymentMethodId": "pm_123456789",
  "shippingMethod": "standard",
  "notes": "Leave at front door",
  "couponCode": "WELCOME10"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "order": {
      "id": "order_abc123def456",
      "userId": "usr_123456789",
      "items": [...],
      "subtotal": 49.99,
      "tax": 4.00,
      "shipping": 5.99,
      "discount": 5.00,
      "totalAmount": 54.98,
      "status": "pending",
      "paymentStatus": "pending",
      "shippingMethod": "standard",
      "estimatedDelivery": "2025-01-18",
      "trackingNumber": null,
      "createdAt": "2025-01-15T10:45:00Z"
    },
    "paymentRequired": true,
    "paymentUrl": "https://checkout.tryon.com/pay/order_abc123def456"
  }
}
```

### GET /api/order/{id}

Get detailed order information.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "order_abc123def456",
    "userId": "usr_123456789",
    "items": [...],
    "subtotal": 49.99,
    "tax": 4.00,
    "shipping": 5.99,
    "discount": 5.00,
    "totalAmount": 54.98,
    "status": "shipped",
    "paymentStatus": "completed",
    "shippingMethod": "standard",
    "trackingNumber": "1Z999AA1234567890",
    "trackingUrl": "https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=1Z999AA1234567890",
    "estimatedDelivery": "2025-01-18",
    "shippingAddress": {...},
    "billingAddress": {...},
    "paymentMethod": {
      "type": "card",
      "last4": "4242",
      "brand": "visa",
      "expiryMonth": 12,
      "expiryYear": 2025
    },
    "payment": {
      "transactionId": "txn_123456789",
      "paymentDate": "2025-01-15T10:45:00Z"
    },
    "timeline": [
      {
        "status": "order_placed",
        "timestamp": "2025-01-15T10:45:00Z",
        "message": "Order placed successfully"
      },
      {
        "status": "processing",
        "timestamp": "2025-01-15T11:00:00Z",
        "message": "Order is being processed"
      },
      {
        "status": "shipped",
        "timestamp": "2025-01-16T14:30:00Z",
        "message": "Order shipped with tracking number 1Z999AA1234567890"
      }
    ],
    "createdAt": "2025-01-15T10:45:00Z",
    "updatedAt": "2025-01-16T14:30:00Z"
  }
}
```

## User Profile

### GET /api/profile

Get user profile information.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "usr_123456789",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "dateOfBirth": "1990-05-15",
    "gender": "male",
    "phoneNumber": "+1-555-0123",
    "avatar": "https://cdn.tryon.com/avatars/usr_123456789.jpg",
    "emailVerified": true,
    "phoneVerified": false,
    "preferences": {
      "notifications": {
        "email": true,
        "push": true,
        "marketing": false
      },
      "privacy": {
        "profileVisibility": "private",
        "dataSharing": false
      },
      "units": {
        "height": "cm",
        "weight": "kg"
      }
    },
    "addresses": [
      {
        "id": "addr_001",
        "firstName": "John",
        "lastName": "Doe",
        "street": "123 Main St",
        "apartment": "Apt 4B",
        "city": "New York",
        "state": "NY",
        "zipCode": "10001",
        "country": "US",
        "phone": "+1-555-0123",
        "isDefault": true
      }
    ],
    "stats": {
      "avatarScans": 3,
      "tryOnsGenerated": 127,
      "ordersPlaced": 8,
      "totalSpent": 1247.89
    },
    "createdAt": "2024-12-01T08:00:00Z",
    "updatedAt": "2025-01-15T10:30:00Z"
  }
}
```

### PUT /api/profile

Update user profile.

**Request:**
```json
{
  "firstName": "John",
  "lastName": "Smith",
  "phoneNumber": "+1-555-0123",
  "preferences": {
    "notifications": {
      "email": true,
      "push": false,
      "marketing": true
    },
    "privacy": {
      "profileVisibility": "friends",
      "dataSharing": true
    }
  }
}
```

## Virtual Closet

### GET /api/closet

Get user's virtual closet.

**Query Parameters:**
- `type` (enum: owned, liked, wishlist, all) - Filter by type
- `category` (string) - Filter by category
- `page` (integer, default: 1) - Page number
- `limit` (integer, default: 20, max: 100) - Items per page

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "closet_001",
        "productId": "prod_123abc456",
        "product": {
          "id": "prod_123abc456",
          "name": "Premium Cotton T-Shirt",
          "price": 49.99,
          "image": "https://cdn.tryon.com/products/prod_123abc456_front.jpg",
          "brand": "FashionBrand",
          "category": "tops"
        },
        "type": "owned",
        "purchaseInfo": {
          "orderId": "order_xyz789abc",
          "purchaseDate": "2025-01-10",
          "price": 49.99
        },
        "notes": "My favorite t-shirt",
        "usageCount": 15,
        "lastUsed": "2025-01-12T14:30:00Z",
        "createdAt": "2025-01-10T12:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 58,
      "itemsPerPage": 20,
      "hasNext": true,
      "hasPrevious": false
    },
    "stats": {
      "totalItems": 58,
      "ownedItems": 42,
      "likedItems": 12,
      "wishlistItems": 4
    }
  }
}
```

### POST /api/closet/add

Add item to closet.

**Request:**
```json
{
  "productId": "prod_789def123",
  "variantId": "var_789_002",
  "type": "liked"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "Item added to closet successfully"
  }
}
```

## Payment Processing

### POST /api/payment/create-order

Create payment order for order processing.

**Request:**
```json
{
  "orderId": "order_abc123def456",
  "amount": 129.97,
  "currency": "USD",
  "paymentMethod": {
    "type": "card",
    "cardId": "card_123456789",
    "saveForFuture": true
  },
  "billingAddress": {
    "firstName": "John",
    "lastName": "Doe",
    "street": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "US"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "paymentOrderId": "pay_abc123def456",
    "amount": 129.97,
    "currency": "USD",
    "status": "pending",
    "paymentUrl": "https://checkout.tryon.com/pay/pay_abc123def456",
    "transactionId": "txn_789xyz123"
  }
}
```

### POST /api/payment/verify

Verify and confirm payment transaction.

**Request:**
```json
{
  "paymentOrderId": "pay_abc123def456",
  "transactionId": "txn_789xyz123",
  "verificationCode": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "paymentId": "pay_123456789",
    "status": "verified",
    "orderId": "order_abc123def456",
    "transactionDetails": {
      "amount": 129.97,
      "currency": "USD",
      "paymentMethod": "card",
      "last4": "4242",
      "processedAt": "2025-01-15T10:50:00Z"
    }
  }
}
```

## Error Handling

All API responses follow a consistent error format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "specific_field",
      "reason": "detailed_reason"
    }
  }
}
```

### Common Error Codes

- `INVALID_CREDENTIALS` - Authentication failed
- `INVALID_TOKEN` - Expired or invalid access token
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `VALIDATION_ERROR` - Request data validation failed
- `NOT_FOUND` - Requested resource not found
- `INSUFFICIENT_STOCK` - Product out of stock
- `PAYMENT_FAILED` - Payment processing failed
- `AVATAR_NOT_READY` - Avatar still processing
- `PRODUCT_NOT_TRYONABLE` - Product doesn't support try-on
- `INVALID_IMAGE_QUALITY` - Uploaded image quality too low

### HTTP Status Codes

- `200` - Success
- `201` - Created successfully
- `202` - Accepted (async processing)
- `400` - Bad Request (validation error)
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `415` - Unsupported Media Type
- `422` - Unprocessable Entity
- `429` - Too Many Requests (rate limit)
- `500` - Internal Server Error

## Rate Limiting

- **Authentication endpoints**: 5 requests per minute per IP
- **Scan endpoints**: 3 requests per hour per user
- **Render endpoints**: 10 requests per hour per user
- **Product endpoints**: 100 requests per minute per user
- **General endpoints**: 1000 requests per hour per user

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642234567
```

## Pagination

All list endpoints support pagination using `page` and `limit` query parameters:

- `page` (integer, default: 1) - Page number (1-indexed)
- `limit` (integer, default: 20, max: 100) - Items per page

Response includes pagination metadata:
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "currentPage": 1,
      "totalPages": 10,
      "totalItems": 200,
      "itemsPerPage": 20,
      "hasNext": true,
      "hasPrevious": false
    }
  }
}
```

## Data Formats

### Dates
All dates are in ISO 8601 format with timezone: `2025-01-15T10:30:00Z`

### Currency
All amounts are in the smallest currency unit (e.g., cents for USD):
```json
{
  "price": 4999,  // $49.99
  "currency": "USD"
}
```

### File URLs
All file URLs are absolute HTTPS URLs with signed expiration for security:
```
https://cdn.tryon.com/models/avatar_abc456def.glb?expires=1642234567&signature=abc123
```