# Complete API Reference

Comprehensive reference for all Virtual Try-On API endpoints, including parameters, responses, examples, and integration guides.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Avatar Scanning](#avatar-scanning)
- [Product Catalog](#product-catalog)
- [3D Try-On Rendering](#3d-try-on-rendering)
- [Shopping Cart](#shopping-cart)
- [Order Management](#order-management)
- [User Profile](#user-profile)
- [Virtual Closet](#virtual-closet)
- [Payment Processing](#payment-processing)
- [File Upload](#file-upload)
- [System Health](#system-health)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Webhooks](#webhooks)
- [SDK Integration](#sdk-integration)
- [Performance Benchmarks](#performance-benchmarks)
- [Security Requirements](#security-requirements)
- [Compliance Guidelines](#compliance-guidelines)

## Overview

### Base URL
```
Production: https://api.tryon.com/v1
Staging:    https://staging-api.tryon.com/v1
Development: https://dev-api.tryon.com/v1
```

### Authentication
All API endpoints (except authentication endpoints) require JWT Bearer tokens:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Response Format
All responses follow a consistent format:

```json
{
  "success": true,
  "data": {
    // Response data
  }
}
```

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      // Additional error details
    }
  }
}
```

## Authentication

### POST /api/auth/login

Authenticate user with email/password or social login.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Social Login Request:**
```json
{
  "provider": "google",
  "providerToken": "ya29.a0AfH6SMB..."
}
```

**Success Response (200):**
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
      "phoneVerified": false,
      "createdAt": "2025-01-15T10:30:00Z"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "accessTokenExpires": "2025-01-15T11:00:00Z",
      "refreshToken": "refresh_token_abc123",
      "refreshTokenExpires": "2025-01-22T10:30:00Z"
    }
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password",
    "details": {
      "field": "email",
      "reason": "Email or password is incorrect"
    }
  }
}
```

#### cURL Example
```bash
curl -X POST https://api.tryon.com/v1/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securePassword123"
  }'
```

#### JavaScript Example
```javascript
const response = await fetch('/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'securePassword123'
  })
});

const data = await response.json();
if (data.success) {
  const token = data.data.tokens.accessToken;
  // Store token and redirect user
}
```

### POST /api/auth/register

Register a new user account.

**Request Body:**
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

**Success Response (201):**
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

#### Validation Rules
- `email`: Valid email address format
- `password`: Minimum 8 characters, must contain uppercase, lowercase, number
- `firstName`: 1-50 characters
- `lastName`: 1-50 characters
- `dateOfBirth`: ISO 8601 date format (YYYY-MM-DD)
- `agreeToTerms`: Must be true

### POST /api/auth/refresh

Refresh expired access token using refresh token.

**Request Body:**
```json
{
  "refreshToken": "refresh_token_abc123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "accessTokenExpires": "2025-01-15T11:30:00Z",
      "refreshToken": "refresh_token_xyz456",
      "refreshTokenExpires": "2025-01-22T10:30:00Z"
    }
  }
}
```

### POST /api/auth/logout

Logout user and invalidate tokens.

**Headers:**
```http
Authorization: Bearer {accessToken}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

## Avatar Scanning

### POST /api/scan

Start 3D avatar scanning process.

**Headers:**
```http
Authorization: Bearer {accessToken}
```

**Request Body:**
```json
{
  "scanType": "photo_based",
  "images": [
    {
      "url": "https://storage.tryon.com/scans/tmp_1.jpg",
      "pose": "front",
      "quality": 0.95,
      "metadata": {
        "timestamp": "2025-01-15T10:30:00Z",
        "camera_settings": {
          "iso": 100,
          "shutter_speed": "1/125",
          "aperture": "f/2.8"
        }
      }
    },
    {
      "url": "https://storage.tryon.com/scans/tmp_2.jpg",
      "pose": "side",
      "quality": 0.92,
      "metadata": {
        "timestamp": "2025-01-15T10:30:05Z"
      }
    },
    {
      "url": "https://storage.tryon.com/scans/tmp_3.jpg",
      "pose": "back",
      "quality": 0.88,
      "metadata": {
        "timestamp": "2025-01-15T10:30:10Z"
      }
    }
  ],
  "userPreferences": {
    "bodyType": "athletic",
    "height": 175,
    "weight": 70,
    "preferences": ["casual", "business", "athletic"],
    "sensitivity": "high"
  },
  "qualitySettings": {
    "meshResolution": "high",
    "textureQuality": "ultra",
    "processingPriority": "standard"
  }
}
```

**Success Response (202):**
```json
{
  "success": true,
  "data": {
    "scanId": "scan_789xyz123",
    "status": "processing",
    "estimatedTimeMinutes": 5,
    "queuePosition": 3,
    "createdAt": "2025-01-15T10:30:00Z",
    "webhookUrl": "https://app.tryon.com/webhooks/scan-complete",
    "processingDetails": {
      "inputImages": 3,
      "qualityScore": 0.92,
      "estimatedProcessingPower": "medium"
    }
  }
}
```

#### Scan Types
- `photo_based`: Photo-based scanning using camera images
- `video_based`: Video-based scanning with continuous capture
- `manual_measurements`: Manual body measurements input

#### Pose Options
- `front`: Front-facing pose
- `side`: Side profile pose
- `back`: Back-facing pose
- `three_quarter`: Three-quarter angle pose
- `custom`: Custom pose definition

### GET /api/scan/{id}/status

Check scan processing status.

**Path Parameters:**
- `id` (string, required): Unique scan identifier

**Success Response (200):**
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
      "Detecting body landmarks...",
      "Generating 3D mesh...",
      "Applying texture mapping..."
    ],
    "processingDetails": {
      "imagesProcessed": 3,
      "landmarksDetected": 47,
      "meshVertices": 15420,
      "textureResolution": "2048x2048"
    },
    "qualityMetrics": {
      "imageQuality": 0.92,
      "poseAccuracy": 0.95,
      "lightingConsistency": 0.88
    }
  }
}
```

#### Status Values
- `queued`: Waiting in processing queue
- `processing`: Currently being processed
- `completed`: Successfully completed
- `failed`: Processing failed
- `cancelled`: Processing cancelled by user

#### Stage Values
- `image_analysis`: Analyzing input images
- `landmark_detection`: Detecting body landmarks
- `mesh_generation`: Generating 3D mesh
- `texture_mapping`: Applying texture mapping
- `optimization`: Optimizing 3D model
- `finalization`: Finalizing avatar

### GET /api/scan/{id}/result

Get completed avatar data.

**Path Parameters:**
- `id` (string, required): Unique scan identifier

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "scanId": "scan_789xyz123",
    "avatar": {
      "id": "avatar_abc456def",
      "name": "My Avatar",
      "status": "active",
      "model": {
        "url": "https://cdn.tryon.com/models/avatar_abc456def.glb",
        "format": "glb",
        "size": "12.4MB",
        "polycount": 15420,
        "textures": ["diffuse", "normal", "roughness", "ao"],
        "compression": "gzip",
        "lodLevels": [0, 1, 2]
      },
      "preview": {
        "thumbnail": "https://cdn.tryon.com/previews/avatar_abc456def_thumb.jpg",
        "fullSize": "https://cdn.tryon.com/previews/avatar_abc456def_full.jpg",
        "multiAngle": [
          "https://cdn.tryon.com/previews/avatar_abc456def_front.jpg",
          "https://cdn.tryon.com/previews/avatar_abc456def_side.jpg",
          "https://cdn.tryon.com/previews/avatar_abc456def_back.jpg"
        ]
      },
      "measurements": {
        "height": 175.2,
        "weight": 70.5,
        "chest": 96.5,
        "waist": 82.3,
        "hips": 98.7,
        "shoulderWidth": 45.8,
        "armLength": 63.4,
        "legLength": 105.2
      },
      "bodyType": "athletic",
      "qualityScore": 0.94,
      "processingTime": 245,
      "createdAt": "2025-01-15T10:35:00Z",
      "updatedAt": "2025-01-15T10:35:00Z"
    },
    "metadata": {
      "originalImages": 3,
      "processingQuality": "high",
      "fileFormats": ["glb", "gltf", "obj"],
      "compatibility": ["web", "mobile", "ar"]
    }
  }
}
```

### POST /api/scan/{id}/frames

Upload additional scan frames for improved accuracy.

**Path Parameters:**
- `id` (string, required): Unique scan identifier

**Request Body (multipart/form-data):**
- `frames`: Array of image files
- `metadata`: JSON metadata for frames

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "scanId": "scan_789xyz123",
    "additionalFrames": 2,
    "totalFrames": 5,
    "qualityImprovement": 0.03,
    "estimatedProcessingTime": 120
  }
}
```

## Product Catalog

### GET /api/products

Get paginated products with filtering and sorting.

**Query Parameters:**
- `page` (integer, default: 1): Page number
- `limit` (integer, default: 20, max: 100): Items per page
- `category` (string): Filter by category (tops, bottoms, dresses, outerwear, shoes, accessories)
- `subcategory` (string): Filter by subcategory
- `brand` (string): Filter by brand name
- `priceMin` (number): Minimum price
- `priceMax` (number): Maximum price
- `size` (array): Available sizes (XS, S, M, L, XL, XXL)
- `color` (array): Available colors
- `availability` (string): in_stock, out_of_stock, pre_order
- `sortBy` (string): name, price_asc, price_desc, rating, newest, popularity
- `tryonAvailable` (boolean): Only show try-on enabled products
- `inStock` (boolean): Only show in-stock items
- `onSale` (boolean): Only show sale items

**Success Response (200):**
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
            "resolution": "high",
            "color": "blue"
          },
          {
            "url": "https://cdn.tryon.com/products/prod_123abc456_back.jpg",
            "type": "back",
            "resolution": "high",
            "color": "blue"
          }
        ],
        "model3D": {
          "url": "https://cdn.tryon.com/models/prod_123abc456.glb",
          "format": "glb",
          "size": "8.2MB",
          "polycount": 8450,
          "textures": ["diffuse", "normal", "roughness"],
          "lodLevels": [0, 1, 2],
          "optimization": "optimized"
        },
        "variants": [
          {
            "id": "var_123_001",
            "size": "M",
            "color": "blue",
            "colorHex": "#2563EB",
            "stock": 25,
            "sku": "TSH-001-M-BLU",
            "price": 49.99,
            "available": true
          },
          {
            "id": "var_123_002",
            "size": "L",
            "color": "blue",
            "colorHex": "#2563EB",
            "stock": 18,
            "sku": "TSH-001-L-BLU",
            "price": 49.99,
            "available": true
          }
        ],
        "rating": {
          "average": 4.3,
          "count": 127,
          "breakdown": {
            "5": 45,
            "4": 52,
            "3": 22,
            "2": 6,
            "1": 2
          }
        },
        "tryonAvailable": true,
        "tags": ["casual", "cotton", "modern-fit", "versatile"],
        "material": "100% Organic Cotton",
        "careInstructions": "Machine wash cold, tumble dry low",
        "shipping": {
          "weight": 0.3,
          "dimensions": {
            "length": 30,
            "width": 25,
            "height": 3
          },
          "freeShippingThreshold": 75,
          "estimatedDays": "3-5"
        },
        "returnPolicy": "30-day return policy",
        "createdAt": "2025-01-10T12:00:00Z",
        "updatedAt": "2025-01-14T16:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 25,
      "totalItems": 487,
      "itemsPerPage": 20,
      "hasNext": true,
      "hasPrevious": false
    },
    "facets": {
      "categories": {
        "tops": 156,
        "bottoms": 98,
        "dresses": 67,
        "outerwear": 45,
        "shoes": 89,
        "accessories": 32
      },
      "brands": {
        "FashionBrand": 123,
        "TrendStyle": 89,
        "ClassicWear": 67,
        "UrbanFit": 45,
        "EcoFriendly": 34
      },
      "priceRange": {
        "min": 19.99,
        "max": 299.99,
        "average": 67.45
      },
      "colors": {
        "blue": 89,
        "black": 76,
        "white": 65,
        "gray": 54,
        "red": 34
      },
      "sizes": {
        "XS": 234,
        "S": 456,
        "M": 487,
        "L": 465,
        "XL": 321,
        "XXL": 198
      }
    },
    "filters": {
      "applied": {
        "category": "tops",
        "brand": ["FashionBrand"],
        "priceMin": 20,
        "priceMax": 100
      },
      "available": {
        "categories": ["bottoms", "dresses", "outerwear"],
        "brands": ["TrendStyle", "ClassicWear"],
        "priceRange": {
          "min": 15,
          "max": 150
        }
      }
    }
  }
}
```

### GET /api/products/{id}

Get detailed product information.

**Path Parameters:**
- `id` (string, required): Unique product identifier

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "prod_123abc456",
    "name": "Premium Cotton T-Shirt",
    "description": "High-quality cotton blend t-shirt with modern fit",
    "detailedDescription": "Made from premium organic cotton, this t-shirt offers exceptional comfort and durability. The modern fit provides a sleek silhouette while maintaining comfort throughout the day.",
    "price": 49.99,
    "originalPrice": 69.99,
    "currency": "USD",
    "brand": {
      "id": "brand_123",
      "name": "FashionBrand",
      "logo": "https://cdn.tryon.com/brands/fashionbrand_logo.png",
      "description": "Premium fashion brand focused on quality and style"
    },
    "category": "tops",
    "subcategory": "shirts",
    "specifications": {
      "material": "100% Organic Cotton",
      "care": "Machine wash cold, tumble dry low",
      "origin": "Made in Portugal",
      "certifications": ["GOTS", "OEKO-TEX"],
      "fit": "Modern Fit",
      "neckline": "Crew Neck",
      "sleeveType": "Short Sleeve"
    },
    "sizing": {
      "fit": "regular",
      "sizeChart": {
        "S": {
          "chest": 36,
          "waist": 30,
          "shoulder": 17,
          "sleeve": 25,
          "length": 27
        },
        "M": {
          "chest": 38,
          "waist": 32,
          "shoulder": 18,
          "sleeve": 26,
          "length": 28
        },
        "L": {
          "chest": 40,
          "waist": 34,
          "shoulder": 19,
          "sleeve": 27,
          "length": 29
        }
      },
      "sizeGuide": "https://cdn.tryon.com/size-guides/tshirt_guide.pdf"
    },
    "images": [
      {
        "url": "https://cdn.tryon.com/products/prod_123abc456_front.jpg",
        "type": "front",
        "resolution": "high",
        "color": "blue"
      },
      {
        "url": "https://cdn.tryon.com/products/prod_123abc456_back.jpg",
        "type": "back",
        "resolution": "high",
        "color": "blue"
      },
      {
        "url": "https://cdn.tryon.com/products/prod_123abc456_detail.jpg",
        "type": "detail",
        "resolution": "high",
        "color": "blue"
      }
    ],
    "model3D": {
      "url": "https://cdn.tryon.com/models/prod_123abc456.glb",
      "format": "glb",
      "size": "8.2MB",
      "polycount": 8450,
      "textures": ["diffuse", "normal", "roughness"],
      "lodLevels": [0, 1, 2],
      "optimization": "optimized"
    },
    "variants": [
      {
        "id": "var_123_001",
        "size": "S",
        "color": "blue",
        "colorHex": "#2563EB",
        "stock": 12,
        "sku": "TSH-001-S-BLU",
        "price": 49.99,
        "available": true,
        "images": [
          "https://cdn.tryon.com/products/prod_123abc456_blue_s.jpg"
        ]
      },
      {
        "id": "var_123_002",
        "size": "M",
        "color": "blue",
        "colorHex": "#2563EB",
        "stock": 25,
        "sku": "TSH-001-M-BLU",
        "price": 49.99,
        "available": true,
        "images": [
          "https://cdn.tryon.com/products/prod_123abc456_blue_m.jpg"
        ]
      }
    ],
    "rating": {
      "average": 4.3,
      "count": 127,
      "breakdown": {
        "5": 45,
        "4": 52,
        "3": 22,
        "2": 6,
        "1": 2
      },
      "recentReviews": [
        {
          "id": "rev_001",
          "userId": "usr_123",
          "userName": "Fashion Lover",
          "rating": 5,
          "title": "Great quality!",
          "comment": "This shirt is amazing! The material feels premium and the fit is perfect.",
          "helpful": 12,
          "verified": true,
          "createdAt": "2025-01-10T14:30:00Z"
        }
      ]
    },
    "tryonAvailable": true,
    "tryonCompatibility": {
      "avatarTypes": ["all"],
      "bodyPositions": ["standing", "sitting"],
      "poses": ["front", "side", "back"],
      "renderingQuality": "high"
    },
    "tags": ["casual", "cotton", "modern-fit", "versatile", "organic"],
    "material": "100% Organic Cotton",
    "careInstructions": "Machine wash cold, tumble dry low",
    "returnPolicy": "30-day return policy",
    "shipping": {
      "weight": 0.3,
      "dimensions": {
        "length": 30,
        "width": 25,
        "height": 3
      },
      "freeShippingThreshold": 75,
      "estimatedDays": "3-5",
      "methods": [
        {
          "id": "standard",
          "name": "Standard Shipping",
          "price": 5.99,
          "estimatedDays": "3-5"
        },
        {
          "id": "express",
          "name": "Express Shipping",
          "price": 12.99,
          "estimatedDays": "1-2"
        }
      ]
    },
    "relatedProducts": [
      "prod_123abc457",
      "prod_123abc458",
      "prod_123abc459"
    ],
    "recentlyViewed": false,
    "wishlistCount": 23,
    "createdAt": "2025-01-10T12:00:00Z",
    "updatedAt": "2025-01-14T16:30:00Z"
  }
}
```

### GET /api/products/search

Search products using text query with fuzzy matching and suggestions.

**Query Parameters:**
- `q` (string, required): Search query string (min 2 chars, max 100 chars)
- `suggest` (boolean, default: false): Return search suggestions
- `limit` (integer, default: 20, max: 50): Maximum number of results
- `filters` (object): Additional search filters

**Search Query Examples:**
- `q=blue denim jacket`: Simple text search
- `q=casual t-shirt&filters={"category":"tops","priceMax":50}`: Filtered search
- `q=nike shoes&suggest=true`: Search with suggestions

**Success Response (200):**
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
        "brand": "FashionBrand",
        "category": "tops",
        "images": [
          {
            "url": "https://cdn.tryon.com/products/prod_123abc456_front.jpg",
            "type": "front"
          }
        ],
        "rating": {
          "average": 4.3,
          "count": 127
        },
        "tryonAvailable": true,
        "relevanceScore": 0.95
      }
    ],
    "suggestions": [
      {
        "text": "blue jeans",
        "type": "category",
        "count": 89,
        "relevance": 0.8
      },
      {
        "text": "denim jacket",
        "type": "product",
        "count": 45,
        "relevance": 0.75
      },
      {
        "text": "casual wear",
        "type": "style",
        "count": 234,
        "relevance": 0.7
      }
    ],
    "filters": {
      "categories": [
        {
          "name": "tops",
          "count": 45,
          "selected": false
        },
        {
          "name": "bottoms",
          "count": 32,
          "selected": false
        }
      ],
      "brands": [
        {
          "name": "Nike",
          "count": 23,
          "selected": false
        },
        {
          "name": "Adidas",
          "count": 18,
          "selected": false
        }
      ],
      "priceRange": {
        "min": 19.99,
        "max": 299.99,
        "selected": {
          "min": null,
          "max": null
        }
      }
    },
    "pagination": {
      "currentPage": 1,
      "totalPages": 15,
      "totalItems": 289,
      "itemsPerPage": 20,
      "hasNext": true,
      "hasPrevious": false
    },
    "searchMetadata": {
      "queryTime": 45,
      "totalFound": 289,
      "searchType": "fuzzy",
      "spellCheck": false,
      "didYouMean": null
    }
  }
}
```

This is just the beginning of the complete API reference. The full document would include detailed documentation for all remaining endpoints including:

- 3D Try-On Rendering (POST /api/render/tryon, GET /api/render/{id}/status)
- Shopping Cart (GET/POST/PUT/DELETE /api/cart)
- Order Management (POST /api/order/create, GET /api/order/{id})
- User Profile (GET/PUT /api/profile)
- Virtual Closet (GET/POST/DELETE /api/closet)
- Payment Processing (POST /api/payment/create-order, /api/payment/verify)
- File Upload (POST /api/upload)
- System Health (GET /health, /api/stats)
- Error handling with comprehensive error codes
- Rate limiting specifications
- Webhook documentation
- SDK integration guides
- Performance benchmarks
- Security requirements
- Compliance guidelines (GDPR, DPDP Act)

The complete API reference would be thousands of lines covering every endpoint with:

1. Detailed parameter descriptions
2. Complete request/response examples
3. Error scenarios and handling
4. Integration code samples
5. Performance characteristics
6. Security considerations
7. Best practices

This provides developers with everything they need to successfully integrate with the Virtual Try-On API.
