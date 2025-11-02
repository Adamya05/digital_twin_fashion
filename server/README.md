# Virtual Try-On Mock Server

A comprehensive Node.js/Express mock server that simulates a complete Virtual Try-On application backend with 3D model support, payment processing, and fashion catalog functionality.

## 🚀 Features

### Core API Endpoints
- **Authentication**: User registration, login, JWT token management
- **Avatar Scanning**: Mock avatar generation with progress tracking
- **Product Catalog**: 120+ fashion items with search, filtering, and pagination
- **Shopping Cart**: Full cart management with item validation
- **Order Management**: Complete order lifecycle with status tracking
- **Payment Processing**: Mock Razorpay integration with payment intents
- **Try-On Rendering**: 3D try-on simulation with mock processing
- **User Management**: Profile management and preferences
- **Closet System**: Virtual closet with outfit creation

### Technical Features
- **Static Asset Serving**: GLB/GLTF 3D models, product images, avatars
- **In-Memory Database**: Mock data persistence with backup/restore
- **Authentication & Authorization**: JWT-based with role-based access
- **Rate Limiting**: Request throttling and abuse prevention
- **Validation**: Request validation and sanitization
- **Logging**: Comprehensive logging with Winston
- **Error Handling**: Centralized error handling with proper HTTP codes
- **CORS Support**: Configurable CORS for web/mobile clients
- **Compression**: Gzip compression for large model files

## 📁 Project Structure

```
server/
├── middleware/          # Express middleware
│   ├── auth.js         # Authentication middleware
│   ├── validation.js   # Request validation
│   └── errorHandler.js # Error handling
├── routes/             # API route definitions
│   ├── auth.js         # Authentication routes
│   ├── scan.js         # Avatar scanning routes
│   ├── products.js     # Product catalog routes
│   ├── cart.js         # Shopping cart routes
│   ├── orders.js       # Order management routes
│   ├── payments.js     # Payment processing routes
│   ├── users.js        # User management routes
│   ├── avatar.js       # Avatar management routes
│   ├── tryon.js        # Try-on rendering routes
│   └── closet.js       # Virtual closet routes
├── utils/              # Utility functions
│   ├── mockData.js     # Mock data generators
│   ├── database.js     # Database simulation
│   ├── logger.js       # Logging utilities
│   └── seedDatabase.js # Database seeding script
├── static/             # Static assets
│   ├── models/         # 3D model files (GLB/GLTF)
│   ├── images/         # Product and avatar images
│   └── data/           # Mock data files
├── config/             # Configuration files
├── logs/               # Application logs
├── data/               # Persistent data storage
├── backups/            # Database backups
├── server.js           # Main server file
├── package.json        # Dependencies and scripts
└── .env.example        # Environment variables template
```

## 🛠️ Installation & Setup

### Prerequisites
- Node.js 18.0.0 or higher
- npm or yarn

### Installation

1. **Install dependencies:**
   ```bash
   cd server
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the server:**
   ```bash
   # Development mode with auto-restart
   npm run dev
   
   # Production mode
   npm start
   ```

4. **Seed the database (optional):**
   ```bash
   npm run seed
   ```

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```env
# Server Configuration
NODE_ENV=development
PORT=3000
HOST=localhost

# JWT Configuration
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# Database Configuration
DATABASE_URL=mock://localhost/tryon_db

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# File Upload Configuration
MAX_FILE_SIZE=52428800
ALLOWED_FILE_TYPES=.jpg,.jpeg,.png,.glb,.gltf

# Mock Features
ENABLE_MOCK_AUTH=true
ENABLE_MOCK_PAYMENTS=true
ENABLE_MOCK_3D_PROCESSING=true
```

## 📊 API Documentation

### Base URLs
- **Development**: `http://localhost:3000/api`
- **Health Check**: `http://localhost:3000/health`

### Authentication Endpoints
```
POST   /api/auth/register        # User registration
POST   /api/auth/login           # User login
POST   /api/auth/refresh         # Token refresh
GET    /api/auth/profile         # Get user profile
POST   /api/auth/logout          # User logout
POST   /api/auth/mock-login      # Mock login (for testing)
```

### Scan & Avatar Endpoints
```
POST   /api/scan/start           # Start avatar scan
GET    /api/scan/status/:id      # Get scan status
GET    /api/scan/result/:id      # Get scan result
GET    /api/avatar/              # List user avatars
POST   /api/avatar/              # Create new avatar
GET    /api/avatar/:id           # Get avatar details
```

### Product Catalog Endpoints
```
GET    /api/products             # List products (with filtering)
GET    /api/products/:id         # Get product details
GET    /api/products/meta/categories  # Get categories
GET    /api/products/featured/list    # Get featured products
```

### Cart & Orders Endpoints
```
GET    /api/cart                 # Get user cart
POST   /api/cart                 # Add item to cart
PUT    /api/cart/items/:id       # Update cart item
DELETE /api/cart/items/:id       # Remove cart item
DELETE /api/cart                 # Clear cart
POST   /api/orders               # Create new order
GET    /api/orders               # List user orders
GET    /api/orders/:id           # Get order details
```

### Payment Endpoints
```
POST   /api/payments/create-intent  # Create payment intent
POST   /api/payments/confirm        # Confirm payment
GET    /api/payments/:id            # Get payment status
GET    /api/payments                # Payment history
```

### Try-On Endpoints
```
POST   /api/tryon/start             # Start try-on
GET    /api/tryon/status/:id        # Get try-on status
GET    /api/tryon/result/:id        # Get try-on result
GET    /api/tryon/history           # Try-on history
POST   /api/tryon/batch             # Batch try-on
```

## 🎯 Mock Data

### Generated Mock Data
- **120+ Fashion Products** across multiple categories
- **10+ User Profiles** with complete information
- **15+ Avatar Templates** with different body types
- **20+ Orders** with various statuses
- **Multiple Shopping Carts** with realistic items
- **Payment History** with different payment statuses

### Product Categories
- Tops (T-Shirts, Blouses, Shirts, etc.)
- Bottoms (Jeans, Trousers, Shorts, etc.)
- Dresses (Casual, Formal, Evening, etc.)
- Outerwear (Jackets, Coats, Blazers, etc.)
- Accessories (Bags, Jewelry, Scarves, etc.)
- Footwear (Sneakers, Heels, Boots, etc.)
- Activewear (Sports Bras, Yoga Pants, etc.)

## 🔒 Security Features

### Implemented Security Measures
- **JWT Authentication** with token validation
- **Rate Limiting** to prevent abuse
- **Input Validation** with express-validator
- **CORS Configuration** for cross-origin requests
- **Security Headers** with Helmet.js
- **Error Sanitization** to prevent information leakage
- **Request Logging** for security monitoring

### Mock Authentication
For development/testing, mock authentication allows any token format:
```javascript
// Mock login for testing
POST /api/auth/mock-login
{
  "userId": "test_user_123"
}
```

## 📱 Integration with Flutter App

The server is designed to work seamlessly with the existing Flutter app:

### API Compatibility
- All endpoints match the `api_contracts.json` specification
- Consistent response formats
- Proper error handling with Flutter-friendly error codes
- Authentication headers for secure requests

### Static Assets
- 3D models served with proper MIME types
- Image optimization and caching headers
- Avatar thumbnails and metadata
- Product images in multiple resolutions

## 🧪 Testing

### Manual Testing
```bash
# Health check
curl http://localhost:3000/health

# Test authentication
curl -X POST http://localhost:3000/api/auth/mock-login \
  -H "Content-Type: application/json" \
  -d '{"userId": "test_user_1"}'

# Get products
curl http://localhost:3000/api/products?limit=10&category=tops
```

### API Testing Tools
- Use Postman or Insomnia for API testing
- Import the `api_contracts.json` for endpoint documentation
- Test with the mock authentication system

## 🚀 Production Considerations

### Performance Optimization
- **Compression** enabled for large files
- **Caching** headers for static assets
- **Rate limiting** to prevent abuse
- **Request logging** for monitoring

### Scalability
- In-memory database for fast development
- Can be replaced with real database (MongoDB, PostgreSQL)
- Stateless architecture supports horizontal scaling
- Load balancer ready

### Monitoring
- Winston logging with multiple transports
- Health check endpoints
- Error tracking and reporting
- Performance monitoring capabilities

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details

## 🆘 Support

For issues and questions:
1. Check the health endpoint: `/health`
2. Review logs in `/logs` directory
3. Ensure environment variables are configured
4. Verify network connectivity and CORS settings

## 🔄 Development Workflow

1. **Start development server:**
   ```bash
   npm run dev
   ```

2. **Make changes to routes/middleware**

3. **Test changes with curl or API client**

4. **Check logs for any errors**

5. **Restart server to apply changes**

The server includes hot reloading with nodemon for development efficiency.