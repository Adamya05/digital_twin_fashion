# Server Configuration Guide

## Environment Variables

### Required Configuration
```env
# Server Configuration
NODE_ENV=development
PORT=3000
HOST=localhost

# JWT Configuration
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRES_IN=7d

# Database Configuration (Mock)
DATABASE_URL=mock://localhost/tryon_db
```

### Optional Configuration
```env
# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# File Upload
MAX_FILE_SIZE=52428800
ALLOWED_FILE_TYPES=.jpg,.jpeg,.png,.glb,.gltf

# Logging
LOG_LEVEL=info
LOG_FILE=logs/app.log

# Mock Features
ENABLE_MOCK_AUTH=true
ENABLE_MOCK_PAYMENTS=true
ENABLE_MOCK_3D_PROCESSING=true

# Cache
CACHE_TTL=3600
ENABLE_COMPRESSION=true
```

## Database Structure

The mock server uses in-memory storage with the following collections:

### Users Collection
```json
{
  "id": "user_123",
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1234567890",
  "role": "user",
  "preferences": {
    "theme": "light",
    "language": "en",
    "notifications": true,
    "size": "M"
  },
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### Products Collection
```json
{
  "id": "prod_123",
  "name": "Classic T-Shirt",
  "description": "High-quality cotton t-shirt",
  "price": 29.99,
  "brand": "Example Brand",
  "category": "tops",
  "colors": ["Black", "White"],
  "sizes": ["S", "M", "L", "XL"],
  "imageUrl": "https://example.com/image.jpg",
  "modelUrl": "/models/product_123.glb",
  "rating": 4.5,
  "reviewCount": 120,
  "stock": 50,
  "isAvailable": true,
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

### Orders Collection
```json
{
  "id": "order_123",
  "userId": "user_123",
  "items": [
    {
      "productId": "prod_123",
      "quantity": 1,
      "price": 29.99
    }
  ],
  "totalAmount": 29.99,
  "shippingCost": 9.99,
  "tax": 2.40,
  "finalAmount": 42.38,
  "status": "pending",
  "paymentStatus": "pending",
  "shippingAddress": {
    "street": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001"
  },
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

## Security Configuration

### CORS Settings
```javascript
const corsOptions = {
  origin: [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:19006'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
};
```

### Rate Limiting
```javascript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
```

### Security Headers
```javascript
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https:"]
    }
  }
}));
```

## Performance Optimization

### Compression
```javascript
app.use(compression({
  threshold: 1024,
  level: 6
}));
```

### Static File Caching
```javascript
app.use('/static', express.static(path.join(__dirname, 'static'), {
  maxAge: '1y',
  etag: true
}));
```

### 3D Model Serving
```javascript
app.use('/models', express.static(path.join(__dirname, 'models'), {
  setHeaders: (res, path) => {
    if (path.endsWith('.glb') || path.endsWith('.gltf')) {
      res.setHeader('Content-Type', 'model/gltf-binary');
    }
  }
}));
```

## Monitoring & Logging

### Log Levels
- `error`: Error messages
- `warn`: Warning messages  
- `info`: Information messages
- `debug`: Debug messages (development only)

### Log Formats
```json
{
  "timestamp": "2024-01-01 00:00:00",
  "level": "info",
  "message": "API request processed",
  "service": "virtual-tryon-mock-server",
  "request": {
    "method": "GET",
    "url": "/api/products",
    "ip": "127.0.0.1"
  }
}
```

### Health Checks
- `/health`: Basic server health
- `/api/health`: Detailed API health with services status
