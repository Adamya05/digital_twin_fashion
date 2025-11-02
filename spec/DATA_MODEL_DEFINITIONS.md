# API Data Model Definitions

This document provides comprehensive specifications for all data models used in the Virtual Try-On API.

## Table of Contents

- [User Models](#user-models)
- [Avatar Models](#avatar-models)
- [Product Models](#product-models)
- [Cart & Order Models](#cart--order-models)
- [Scan & Render Models](#scan--render-models)
- [Payment Models](#payment-models)
- [Common Models](#common-models)

## User Models

### User

Basic user information returned in authentication responses.

```json
{
  "id": "usr_123456789",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "avatar": "https://cdn.tryon.com/avatars/usr_123456789.jpg",
  "emailVerified": true,
  "phoneVerified": false,
  "createdAt": "2024-12-01T08:00:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

**Field Specifications:**
- `id` (string): Unique user identifier, format `usr_[a-zA-Z0-9]{9,}`
- `email` (string): User email address, valid email format
- `firstName` (string): User's first name, 1-50 characters
- `lastName` (string): User's last name, 1-50 characters
- `avatar` (string): URL to user's avatar image
- `emailVerified` (boolean): Whether email is verified
- `phoneVerified` (boolean): Whether phone is verified
- `createdAt` (string): ISO 8601 timestamp of account creation
- `updatedAt` (string): ISO 8601 timestamp of last profile update

### UserProfile

Extended user profile with preferences and additional data.

```json
{
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
```

**Field Specifications:**
- `dateOfBirth` (string): Date in YYYY-MM-DD format
- `gender` (enum): "male", "female", "non_binary", "prefer_not_to_say"
- `phoneNumber` (string): International format with country code
- `preferences.notifications.email` (boolean): Email notification preference
- `preferences.notifications.push` (boolean): Push notification preference
- `preferences.notifications.marketing` (boolean): Marketing communication consent
- `preferences.privacy.profileVisibility` (enum): "public", "friends", "private"
- `preferences.privacy.dataSharing` (boolean): Consent to data sharing for analytics
- `preferences.units.height` (enum): "cm", "in"
- `preferences.units.weight` (enum): "kg", "lbs"
- `stats.avatarScans` (integer): Total number of avatar scans performed
- `stats.tryOnsGenerated` (integer): Total number of try-on renders generated
- `stats.ordersPlaced` (integer): Total number of orders placed
- `stats.totalSpent` (number): Total amount spent (in currency units)

### AuthTokens

JWT tokens for authentication.

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c3JfMTIzNDU2NzgiLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJpYXQiOjE3Mjc0MDAwMDAsImV4cCI6MTcyNzQwNjYwMH0.signature_here",
  "accessTokenExpires": "2025-01-15T11:30:00Z",
  "refreshToken": "refresh_token_abc123def456",
  "refreshTokenExpires": "2025-01-22T10:30:00Z"
}
```

**JWT Token Claims:**
- `sub`: User ID
- `email`: User email
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp
- `type`: "access" or "refresh"

## Avatar Models

### Avatar

Complete avatar data including 3D model information.

```json
{
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
  "measurements": {
    "height": 175.5,
    "weight": 70.2,
    "chest": 95.0,
    "waist": 82.0,
    "hips": 98.0,
    "shoulderWidth": 45.0,
    "armLength": 62.0,
    "legLength": 105.0
  },
  "qualityScore": 0.94,
  "processingTime": 245,
  "createdAt": "2025-01-15T10:35:00Z",
  "updatedAt": "2025-01-15T10:35:00Z"
}
```

**Field Specifications:**
- `id` (string): Unique avatar identifier, format `avatar_[a-zA-Z0-9]{9,}`
- `name` (string): User-defined avatar name
- `status` (enum): "active", "archived", "processing"
- `model.url` (string): Signed URL to 3D model file
- `model.format` (enum): "glb", "gltf", "fbx", "obj"
- `model.size` (string): File size in human-readable format
- `model.polycount` (integer): Number of polygons in the 3D model
- `model.textures` (array): Available texture types
- `measurements.height` (number): Height in centimeters
- `measurements.weight` (number): Weight in kilograms
- `qualityScore` (number): Quality score from 0.0 to 1.0
- `processingTime` (integer): Total processing time in seconds

### ScanRequest

Request data for starting avatar scan.

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

**Field Specifications:**
- `scanType` (enum): "photo_based", "video_based", "body_measurement"
- `images` (array): 3-10 input images required
- `images[].pose` (enum): "front", "side_left", "side_right", "back", "custom"
- `images[].quality` (number): Image quality score from 0.0 to 1.0
- `userPreferences.bodyType` (enum): "slim", "athletic", "curvy", "plus_size"
- `userPreferences.height` (integer): Height in centimeters (100-250)
- `userPreferences.weight` (number): Weight in kilograms (30-300)

### ScanStatusResponse

Response data for scan status queries.

```json
{
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
```

**Processing Stages:**
- `image_analysis` - Analyzing input image quality
- `feature_detection` - Detecting facial/body features
- `mesh_generation` - Creating 3D geometry
- `texture_mapping` - Applying textures
- `optimization` - Optimizing for performance
- `finalization` - Final processing and quality checks

## Product Models

### Product

Basic product information for catalog listings.

```json
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
    },
    {
      "url": "https://cdn.tryon.com/products/prod_123abc456_back.jpg",
      "type": "back",
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
      "sku": "TSH-001-M-BLU",
      "price": 49.99
    }
  ],
  "rating": {
    "average": 4.3,
    "count": 127
  },
  "tryonAvailable": true,
  "tags": ["cotton", "casual", "summer"],
  "createdAt": "2025-01-10T12:00:00Z",
  "updatedAt": "2025-01-14T16:30:00Z"
}
```

**Field Specifications:**
- `id` (string): Unique product identifier, format `prod_[a-zA-Z0-9]{9,}`
- `price` (number): Current selling price
- `originalPrice` (number): Original price before discount
- `currency` (string): ISO 4217 currency code
- `category` (enum): "tops", "bottoms", "dresses", "outerwear", "shoes", "accessories", "activewear", "formal"
- `images[].type` (enum): "front", "back", "side", "detail", "lifestyle"
- `images[].resolution` (enum): "low", "medium", "high", "4k"
- `model3D.format` (enum): "glb", "gltf", "fbx"
- `variants[].colorHex` (string): Hex color code in format #RRGGBB
- `variants[].stock` (integer): Available quantity (0 = out of stock)
- `rating.average` (number): Average rating from 0.0 to 5.0
- `tryonAvailable` (boolean): Whether product supports virtual try-on

### ProductDetail

Extended product information with detailed specifications.

```json
{
  "id": "prod_123abc456",
  "name": "Premium Cotton T-Shirt",
  "description": "High-quality cotton blend t-shirt with modern fit",
  "detailedDescription": "Made from premium organic cotton with sustainable production methods...",
  "price": 49.99,
  "originalPrice": 69.99,
  "currency": "USD",
  "brand": "FashionBrand",
  "category": "tops",
  "subcategory": "shirts",
  "specifications": {
    "material": "100% Organic Cotton",
    "care": "Machine wash cold",
    "origin": "Made in Portugal",
    "fit": "Regular fit",
    "sleeve": "Short sleeve",
    "neck": "Crew neck"
  },
  "sizing": {
    "fit": "regular",
    "sizeGuide": {
      "XS": {"chest": 34, "waist": 28, "shoulder": 16, "sleeve": 24},
      "S": {"chest": 36, "waist": 30, "shoulder": 17, "sleeve": 25},
      "M": {"chest": 38, "waist": 32, "shoulder": 18, "sleeve": 26},
      "L": {"chest": 40, "waist": 34, "shoulder": 19, "sleeve": 27},
      "XL": {"chest": 42, "waist": 36, "shoulder": 20, "sleeve": 28}
    }
  },
  "images": [...],
  "model3D": {...},
  "variants": [...],
  "rating": {...},
  "reviews": [
    {
      "id": "rev_001",
      "userId": "usr_123",
      "userName": "Fashion Lover",
      "rating": 5,
      "title": "Great quality!",
      "comment": "This shirt is amazing quality and fits perfectly. The fabric is soft and breathable.",
      "helpful": 12,
      "verified": true,
      "createdAt": "2025-01-10T14:30:00Z"
    }
  ],
  "relatedProducts": ["prod_789def123", "prod_456ghi789"],
  "tryonAvailable": true,
  "material": "100% Organic Cotton",
  "careInstructions": "Machine wash cold, tumble dry low, iron low",
  "returnPolicy": "30-day return policy, items must be unworn with tags attached",
  "shipping": {
    "weight": 0.2,
    "dimensions": {"length": 30, "width": 25, "height": 2},
    "freeShippingThreshold": 75.00
  },
  "createdAt": "2025-01-10T12:00:00Z",
  "updatedAt": "2025-01-14T16:30:00Z"
}
```

**Field Specifications:**
- `detailedDescription` (string): Extended product description
- `specifications` (object): Technical specifications in key-value pairs
- `sizing.fit` (enum): "slim", "regular", "relaxed", "oversized"
- `sizing.sizeGuide` (object): Size measurements in centimeters
- `reviews[].rating` (integer): Rating from 1 to 5
- `reviews[].helpful` (integer): Number of users who found review helpful
- `reviews[].verified` (boolean): Whether reviewer purchased the product
- `shipping.weight` (number): Weight in kilograms
- `shipping.dimensions` (object): Package dimensions in centimeters
- `shipping.freeShippingThreshold` (number): Minimum order value for free shipping

## Cart & Order Models

### CartItem

Individual item in shopping cart.

```json
{
  "id": "cart_item_001",
  "product": {
    "id": "prod_123abc456",
    "name": "Premium Cotton T-Shirt",
    "price": 49.99,
    "image": "https://cdn.tryon.com/products/prod_123abc456_front.jpg",
    "brand": "FashionBrand"
  },
  "quantity": 1,
  "addedAt": "2025-01-15T10:30:00Z",
  "metadata": {
    "tryonRenderId": "render_xyz789abc",
    "size_confirmed": true,
    "color_confirmed": true
  }
}
```

### Cart

Shopping cart with totals and metadata.

```json
{
  "id": "cart_abc123def456",
  "items": [
    {
      "id": "cart_item_001",
      "product": {...},
      "quantity": 1,
      "addedAt": "2025-01-15T10:30:00Z"
    }
  ],
  "subtotal": 49.99,
  "tax": 4.00,
  "shipping": 5.99,
  "discount": 5.00,
  "total": 54.98,
  "itemCount": 1,
  "couponCode": "WELCOME10",
  "estimatedDelivery": "2025-01-18",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

**Field Specifications:**
- `subtotal` (number): Sum of item prices before tax and shipping
- `tax` (number): Calculated tax amount
- `shipping` (number): Shipping cost
- `discount` (number): Total discount amount
- `total` (number): Final total (subtotal + tax + shipping - discount)
- `itemCount` (integer): Total number of items in cart
- `estimatedDelivery` (string): Estimated delivery date in YYYY-MM-DD format

### Order

Order information without sensitive details.

```json
{
  "id": "order_abc123def456",
  "userId": "usr_123456789",
  "items": [
    {
      "id": "cart_item_001",
      "product": {
        "id": "prod_123abc456",
        "name": "Premium Cotton T-Shirt",
        "price": 49.99
      },
      "quantity": 1
    }
  ],
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
  "notes": "Leave at front door",
  "createdAt": "2025-01-15T10:45:00Z",
  "updatedAt": "2025-01-16T14:30:00Z"
}
```

**Status Values:**
- `pending` - Order placed, awaiting payment
- `processing` - Payment received, being prepared
- `confirmed` - Order confirmed, ready to ship
- `shipped` - Order shipped with tracking
- `delivered` - Order delivered successfully
- `cancelled` - Order cancelled
- `refunded` - Order refunded

### OrderDetail

Extended order information with addresses and payment details.

```json
{
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
  "notes": "Leave at front door",
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
    "firstName": "John",
    "lastName": "Doe",
    "street": "123 Main St",
    "apartment": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "US"
  },
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
```

## Address Model

### Address

Shipping/billing address information.

```json
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
```

**Field Specifications:**
- `firstName` (string): Recipient's first name
- `lastName` (string): Recipient's last name
- `street` (string): Street address
- `apartment` (string): Apartment/Suite number (optional)
- `city` (string): City name
- `state` (string): State/Province/Territory
- `zipCode` (string): Postal/ZIP code
- `country` (string): ISO 3166-1 alpha-2 country code
- `phone` (string): Contact phone number in international format
- `isDefault` (boolean): Whether this is the user's default address

## Scan & Render Models

### TryOnRequest

Request for generating try-on render.

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

**Field Specifications:**
- `pose.type` (enum): "preset", "custom"
- `pose.presetName` (string): Name of preset pose
- `pose.customAdjustments` (object): Custom pose adjustments in degrees/pixels
- `lighting.type` (enum): "studio", "natural", "custom"
- `lighting.preset` (string): Lighting preset name
- `lighting.intensity` (number): Lighting intensity from 0.0 to 2.0
- `camera.angle` (enum): "front", "side", "back", "three_quarter"
- `camera.zoom` (number): Zoom factor from 0.5 to 3.0
- `camera.perspective` (enum): "realistic", "high_fashion", "editorial"
- `output.format` (enum): "png", "jpg", "webp", "gif"
- `output.resolution` (enum): "720p", "1080p", "4k"
- `output.quality` (enum): "low", "medium", "high"
- `output.background` (enum): "transparent", "white", "black", "custom"

### RenderStatusResponse

Status of try-on render operation.

```json
{
  "renderId": "render_xyz789abc",
  "status": "processing",
  "progress": 45,
  "stage": "mesh_fitting",
  "estimatedTimeRemaining": 90,
  "previewUrl": "https://cdn.tryon.com/renders/render_xyz789abc_preview.jpg",
  "error": {
    "code": "MODEL_INCOMPATIBILITY",
    "message": "Avatar model incompatible with product",
    "details": {
      "avatar_format": "glb",
      "product_format": "fbx",
      "suggestion": "Convert avatar to FBX format"
    }
  }
}
```

**Render Stages:**
- `queued` - Waiting in processing queue
- `asset_loading` - Loading 3D assets
- `mesh_fitting` - Fitting product mesh to avatar
- `texture_mapping` - Applying textures and materials
- `lighting_setup` - Setting up lighting environment
- `rendering` - Final render processing
- `optimization` - Optimizing output for delivery

## Payment Models

### PaymentOrder

Payment order for processing transactions.

```json
{
  "paymentOrderId": "pay_abc123def456",
  "amount": 129.97,
  "currency": "USD",
  "status": "pending",
  "paymentUrl": "https://checkout.tryon.com/pay/pay_abc123def456",
  "transactionId": "txn_789xyz123"
}
```

### PaymentVerificationResponse

Result of payment verification.

```json
{
  "paymentId": "pay_123456789",
  "status": "verified",
  "orderId": "order_abc123def456",
  "transactionDetails": {
    "amount": 129.97,
    "currency": "USD",
    "paymentMethod": "card",
    "last4": "4242",
    "brand": "visa",
    "processedAt": "2025-01-15T10:50:00Z"
  }
}
```

## Common Models

### Pagination

Pagination metadata for list responses.

```json
{
  "currentPage": 1,
  "totalPages": 10,
  "totalItems": 200,
  "itemsPerPage": 20,
  "hasNext": true,
  "hasPrevious": false
}
```

**Field Specifications:**
- `currentPage` (integer): Current page number (1-indexed)
- `totalPages` (integer): Total number of pages
- `totalItems` (integer): Total number of items across all pages
- `itemsPerPage` (integer): Number of items per page
- `hasNext` (boolean): Whether there are more pages after current
- `hasPrevious` (boolean): Whether there are pages before current

### ErrorResponse

Standard error response format.

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid data",
    "details": {
      "fields": [
        {
          "field": "email",
          "message": "Email address is required",
          "code": "REQUIRED"
        },
        {
          "field": "password",
          "message": "Password must be at least 8 characters",
          "code": "MIN_LENGTH"
        }
      ]
    }
  }
}
```

### RateLimitError

Rate limiting error response.

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "details": {
      "limit": 100,
      "remaining": 0,
      "resetTime": "2025-01-15T11:00:00Z"
    }
  }
}
```

## Data Validation Rules

### Email Validation
- Must be valid email format
- Maximum length: 254 characters
- Case-insensitive, stored lowercase

### Password Requirements
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit
- At least one special character (@$!%*?&)

### Phone Numbers
- International format with country code
- E.164 format: +[country][area][local]
- Example: +1-555-0123

### Date Formats
- ISO 8601 with timezone: `2025-01-15T10:30:00Z`
- Date only: `2025-01-15`
- All dates in UTC unless specified otherwise

### File URLs
- HTTPS only
- Signed URLs with expiration
- Maximum file size varies by type:
  - Images: 10MB
  - 3D Models: 50MB
  - Videos: 100MB

### Currency
- ISO 4217 codes: USD, EUR, GBP, CAD, AUD
- Amounts in smallest currency unit (cents for USD)
- Prices with 2 decimal places maximum

### Quality Scores
- Range: 0.0 to 1.0
- 0.0 = Poor quality
- 1.0 = Excellent quality
- Precision: 3 decimal places

### Measurements
- Height: centimeters (100-250 cm range)
- Weight: kilograms (30-300 kg range)
- Body measurements: centimeters
- All measurements are approximate and user-reported

## Model Relationships

### User Relationships
- User → Avatar (one-to-many)
- User → Cart (one-to-one, current cart)
- User → Orders (one-to-many)
- User → Closet Items (one-to-many)

### Product Relationships
- Product → Variants (one-to-many)
- Product → Cart Items (one-to-many)
- Product → Closet Items (one-to-many)
- Product → Try-on Renders (one-to-many)

### Order Relationships
- Order → Cart Items (one-to-many)
- Order → Payment (one-to-one)
- Order → Shipping Address (one-to-one)
- Order → Billing Address (one-to-one)

### Avatar Relationships
- Avatar → Try-on Renders (one-to-many)
- Avatar → Scan (one-to-one)

These relationships are maintained through foreign keys and ensure data integrity across the system.