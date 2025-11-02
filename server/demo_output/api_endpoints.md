# Virtual Try-On Mock Server - API Endpoints

## Authentication Endpoints
```
POST   /api/auth/register        - User registration
POST   /api/auth/login           - User login  
POST   /api/auth/refresh         - Token refresh
GET    /api/auth/profile         - Get user profile
POST   /api/auth/logout          - User logout
POST   /api/auth/mock-login      - Mock login (testing)
```

## Scan & Avatar Endpoints
```
POST   /api/scan/start           - Start avatar scan
GET    /api/scan/status/:id      - Get scan status
GET    /api/scan/result/:id      - Get scan result
GET    /api/avatar/              - List user avatars
POST   /api/avatar/              - Create new avatar
GET    /api/avatar/:id           - Get avatar details
PATCH  /api/avatar/:id           - Update avatar
DELETE /api/avatar/:id           - Delete avatar
```

## Product Catalog Endpoints
```
GET    /api/products             - List products (with filtering)
GET    /api/products/:id         - Get product details
GET    /api/products/meta/categories  - Get categories
GET    /api/products/meta/filters     - Get filter options
GET    /api/products/featured/list    - Get featured products
GET    /api/products/search/suggestions - Search suggestions
```

## Cart Management Endpoints
```
GET    /api/cart                 - Get user cart
POST   /api/cart                 - Add item to cart
PUT    /api/cart/items/:id       - Update cart item
DELETE /api/cart/items/:id       - Remove cart item
DELETE /api/cart                 - Clear entire cart
POST   /api/cart/apply-coupon    - Apply discount coupon
```

## Order Management Endpoints
```
POST   /api/orders               - Create new order
GET    /api/orders               - List user orders
GET    /api/orders/:id           - Get order details
PATCH  /api/orders/:id/status    - Update order status (admin)
PATCH  /api/orders/:id/cancel    - Cancel order
POST   /api/orders/:id/return    - Request return
GET    /api/orders/stats/overview - Order statistics
```

## Payment Processing Endpoints
```
POST   /api/payments/create-intent  - Create payment intent
POST   /api/payments/confirm        - Confirm payment
GET    /api/payments/:id            - Get payment status
GET    /api/payments                - Payment history
POST   /api/payments/:id/refund     - Refund payment (admin)
POST   /api/payments/webhook        - Payment webhook
```

## Try-On Rendering Endpoints
```
POST   /api/tryon/start             - Start try-on process
GET    /api/tryon/status/:id        - Get try-on status
GET    /api/tryon/result/:id        - Get try-on result
GET    /api/tryon/history           - Try-on history
POST   /api/tryon/batch             - Batch try-on multiple products
GET    /api/tryon/batch/:id/status  - Get batch try-on status
POST   /api/tryon/:id/favorite      - Save try-on result
GET    /api/tryon/settings          - Get try-on settings
PATCH  /api/tryon/settings          - Update try-on settings
```

## User Management Endpoints
```
GET    /api/users/profile           - Get user profile
PATCH  /api/users/profile           - Update user profile
POST   /api/users/avatar            - Upload user avatar
DELETE /api/users/account           - Delete user account
GET    /api/users/stats             - User statistics
GET    /api/users/activity          - User activity feed
PATCH  /api/users/preferences       - Update user preferences
```

## Closet System Endpoints
```
GET    /api/closet                  - List user closets
POST   /api/closet                  - Create new closet
GET    /api/closet/:id              - Get closet details
PATCH  /api/closet/:id              - Update closet
DELETE /api/closet/:id              - Delete closet
POST   /api/closet/:id/items        - Add item to closet
DELETE /api/closet/:id/items/:productId - Remove item from closet
GET    /api/closet/:id/items        - Get closet items
POST   /api/closet/:id/outfits      - Create outfit
POST   /api/closet/:id/share        - Share closet
GET    /api/closet/shared/:token    - Get shared closet
```

## Health & System Endpoints
```
GET    /health                      - Server health check
GET    /api/health                  - API health check
GET    /static/*                    - Static file serving
GET    /models/*                    - 3D model serving
```

## Mock Data Generated
- ✅ 120+ Fashion Products across 7 categories
- ✅ 10+ User Profiles with complete data
- ✅ 15+ Avatar Templates
- ✅ 20+ Orders with various statuses
- ✅ Shopping Carts with realistic items
- ✅ Payment History
- ✅ Virtual Closets
- ✅ Try-on Results

## Authentication
- JWT-based authentication
- Mock authentication for development
- Role-based access control (user/admin)
- Token refresh mechanism

## Rate Limiting
- 100 requests per 15 minutes per IP
- Configurable rate limits
- Protection against abuse

## Static Assets
- 3D Models (GLB/GLTF) serving
- Product images with optimization
- Avatar images and thumbnails
- Proper MIME type handling
- Gzip compression for large files

