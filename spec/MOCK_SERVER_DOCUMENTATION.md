# Mock Server Documentation

Complete guide for setting up, configuring, and using the Virtual Try-On API Mock Server for development and testing.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Available Endpoints](#available-endpoints)
- [Mock Data](#mock-data)
- [Testing Procedures](#testing-procedures)
- [Performance Tuning](#performance-tuning)
- [Troubleshooting](#troubleshooting)
- [Docker Deployment](#docker-deployment)
- [Production Considerations](#production-considerations)

## Overview

The Virtual Try-On API Mock Server is a Node.js/Express.js application that provides a complete mock implementation of the production API. It's designed for:

- **Development**: Frontend development without backend dependencies
- **Testing**: Automated testing with predictable responses
- **Integration**: Third-party integration testing
- **Training**: API usage training and documentation
- **Demonstration**: Product demos and presentations

### Features

- ✅ **57+ API Endpoints** - Complete endpoint coverage
- ✅ **Realistic Data** - Authentic-looking mock data
- ✅ **Async Processing** - Simulates real async operations
- ✅ **Error Scenarios** - Configurable error responses
- ✅ **Rate Limiting** - Simulates production rate limits
- ✅ **File Uploads** - Mock file upload handling
- ✅ **Authentication** - JWT-based auth simulation
- ✅ **WebSocket Support** - Real-time status updates
- ✅ **Database Integration** - Persistent mock data storage

## Installation

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Git

### Basic Installation

```bash
# Clone the repository
git clone https://github.com/your-org/virtual-tryon-api.git
cd virtual-tryon-api/api-server

# Install dependencies
npm install

# Start the server
npm start
```

### Development Installation

```bash
# Install with development dependencies
npm install --include=dev

# Run in development mode with auto-reload
npm run dev

# Run tests
npm test

# Run linting
npm run lint
```

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Configure environment variables
nano .env
```

## Quick Start

### Start the Server

```bash
# Production mode
npm start

# Development mode with auto-reload
npm run dev

# With custom port
PORT=8080 npm start
```

### Verify Installation

```bash
# Test server health
curl http://localhost:3000/health

# Test API info
curl http://localhost:3000/api/info

# Get API documentation
curl http://localhost:3000/docs
```

### Test Authentication

```bash
# Register a test user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "firstName": "Test",
    "lastName": "User",
    "agreeToTerms": true
  }'

# Login with test user
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'
```

## Configuration

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Server Configuration
PORT=3000
NODE_ENV=development
HOST=localhost

# Database Configuration
DB_TYPE=sqlite
DB_PATH=./data/mock_server.db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=30m
REFRESH_TOKEN_EXPIRES_IN=7d

# Mock Data Configuration
MOCK_DATA_SIZE=large  # small, medium, large, xlarge
ENABLE_REALISTIC_DELAY=true
MIN_RESPONSE_TIME=100
MAX_RESPONSE_TIME=5000

# Rate Limiting
ENABLE_RATE_LIMITING=true
RATE_LIMIT_WINDOW=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=100

# File Upload Configuration
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760  # 10MB
ALLOWED_FILE_TYPES=jpg,jpeg,png,gif,mp4,webm,glb,gltf

# Error Simulation
ENABLE_ERROR_SIMULATION=false
ERROR_RATE=0.1  # 10% error rate
ERROR_CODES=400,401,403,404,429,500,502,503

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=combined
LOG_FILE=./logs/server.log

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
CORS_CREDENTIALS=true

# WebSocket Configuration
WS_ENABLED=true
WS_PORT=3001

# Performance Configuration
ENABLE_COMPRESSION=true
ENABLE_CACHING=true
CACHE_TTL=300  # 5 minutes
```

### Configuration Profiles

#### Development Profile

```bash
# .env.development
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug
ENABLE_ERROR_SIMULATION=true
ERROR_RATE=0.05
ENABLE_REALISTIC_DELAY=false
MOCK_DATA_SIZE=medium
```

#### Testing Profile

```bash
# .env.test
NODE_ENV=test
PORT=3001
LOG_LEVEL=error
ENABLE_ERROR_SIMULATION=false
ENABLE_REALISTIC_DELAY=false
MOCK_DATA_SIZE=small
ENABLE_RATE_LIMITING=false
```

#### Staging Profile

```bash
# .env.staging
NODE_ENV=staging
PORT=3000
LOG_LEVEL=info
ENABLE_ERROR_SIMULATION=true
ERROR_RATE=0.02
ENABLE_REALISTIC_DELAY=true
MOCK_DATA_SIZE=large
```

## Available Endpoints

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | User registration | No |
| POST | `/api/auth/login` | User login | No |
| POST | `/api/auth/refresh` | Token refresh | No |
| POST | `/api/auth/logout` | User logout | Yes |
| GET | `/api/auth/profile` | Get user profile | Yes |
| PUT | `/api/auth/profile` | Update user profile | Yes |
| POST | `/api/auth/forgot-password` | Forgot password | No |
| POST | `/api/auth/reset-password` | Reset password | No |

### Avatar & Scanning Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/scan` | Start avatar scan | Yes |
| GET | `/api/scan/{id}/status` | Get scan status | Yes |
| GET | `/api/scan/{id}/result` | Get scan result | Yes |
| POST | `/api/scan/{id}/frames` | Upload scan frames | Yes |
| GET | `/api/avatar/{id}` | Get avatar data | Yes |
| PUT | `/api/avatar/{id}` | Update avatar | Yes |
| DELETE | `/api/avatar/{id}` | Delete avatar | Yes |
| GET | `/api/avatars` | List user avatars | Yes |

### Product Catalog Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/products` | List products | Yes |
| GET | `/api/products/{id}` | Get product details | Yes |
| GET | `/api/products/search` | Search products | Yes |
| GET | `/api/products/categories` | Get categories | Yes |
| GET | `/api/products/brands` | Get brands | Yes |
| GET | `/api/products/recommendations` | Get recommendations | Yes |
| GET | `/api/products/trending` | Get trending products | Yes |
| POST | `/api/products/{id}/review` | Add product review | Yes |
| GET | `/api/products/{id}/reviews` | Get product reviews | Yes |

### Try-On Rendering Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/render/tryon` | Create try-on render | Yes |
| GET | `/api/render/{id}/status` | Get render status | Yes |
| GET | `/api/render/{id}/result` | Get render result | Yes |
| GET | `/api/renders` | List user renders | Yes |
| DELETE | `/api/render/{id}` | Delete render | Yes |

### Shopping Cart Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/cart` | Get cart | Yes |
| POST | `/api/cart/add` | Add item to cart | Yes |
| PUT | `/api/cart/{id}` | Update cart item | Yes |
| DELETE | `/api/cart/{id}` | Remove cart item | Yes |
| DELETE | `/api/cart` | Clear cart | Yes |

### Order Management Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/order/create` | Create order | Yes |
| GET | `/api/order/{id}` | Get order details | Yes |
| GET | `/api/orders` | List user orders | Yes |
| PUT | `/api/order/{id}/cancel` | Cancel order | Yes |
| PUT | `/api/order/{id}/status` | Update order status | Yes |

### Virtual Closet Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/closet` | Get closet items | Yes |
| POST | `/api/closet/add` | Add item to closet | Yes |
| DELETE | `/api/closet/{id}` | Remove closet item | Yes |
| PUT | `/api/closet/{id}` | Update closet item | Yes |

### Payment Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/payment/create-order` | Create payment order | Yes |
| POST | `/api/payment/verify` | Verify payment | Yes |
| POST | `/api/payment/webhook` | Payment webhook | No |
| GET | `/api/payment/methods` | Get saved payment methods | Yes |

### System Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/health` | Health check | No |
| GET | `/api/info` | API information | No |
| GET | `/api/stats` | API statistics | No |
| GET | `/docs` | API documentation | No |

## Mock Data

### Data Characteristics

The mock server generates realistic data with the following characteristics:

#### User Data
- 100+ realistic user profiles
- Varied demographics and preferences
- Authentic-looking names and emails
- Profile pictures and avatars

#### Product Catalog
- 500+ fashion products
- Multiple categories (tops, bottoms, dresses, shoes, accessories)
- Realistic pricing and descriptions
- High-quality product images
- 3D model references

#### Avatar Data
- 50+ pre-generated avatars
- Various body types and characteristics
- Realistic measurements and proportions
- Quality scores and processing metadata

#### Order History
- 200+ sample orders
- Various order statuses and timelines
- Realistic shipping and billing addresses
- Payment method information

### Data Generation

#### Generate Custom Data

```javascript
// Generate 100 new users
node scripts/generate-users.js --count=100 --output=./data/users.json

// Generate 500 new products
node scripts/generate-products.js --count=500 --category=all --output=./data/products.json

// Generate 50 new avatars
node scripts/generate-avatars.js --count=50 --quality=high --output=./data/avatars.json

// Reset database with fresh data
node scripts/reset-database.js --confirm
```

#### Custom Data Configuration

```javascript
// config/data-config.js
module.exports = {
  users: {
    count: 100,
    includeEmailVerification: true,
    includePhoneVerification: false,
    includeSocialLogin: true
  },
  products: {
    count: 500,
    categories: ['tops', 'bottoms', 'dresses', 'outerwear', 'shoes', 'accessories'],
    priceRange: { min: 15, max: 500 },
    includeOutOfStock: true,
    stockVariance: 0.8
  },
  avatars: {
    count: 50,
    qualityDistribution: {
      high: 0.3,
      medium: 0.5,
      low: 0.2
    },
    processingTimes: {
      min: 120,
      max: 600
    }
  },
  orders: {
    count: 200,
    statusDistribution: {
      pending: 0.1,
      processing: 0.2,
      shipped: 0.3,
      delivered: 0.3,
      cancelled: 0.1
    }
  }
};
```

## Testing Procedures

### Automated Testing

#### Run All Tests

```bash
# Run complete test suite
npm test

# Run specific test categories
npm run test:unit
npm run test:integration
npm run test:e2e
npm run test:performance

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

#### Unit Tests

```javascript
// test/auth.test.js
const request = require('supertest');
const app = require('../server');

describe('Authentication API', () => {
  test('POST /api/auth/register should register user', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'TestPassword123!',
        firstName: 'Test',
        lastName: 'User',
        agreeToTerms: true
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.user.email).toBe('test@example.com');
  });

  test('POST /api/auth/login should authenticate user', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'TestPassword123!'
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.tokens.accessToken).toBeDefined();
  });
});
```

#### Integration Tests

```javascript
// test/integration/avatar-workflow.test.js
const request = require('supertest');
const app = require('../server');

describe('Avatar Workflow Integration', () => {
  let accessToken;

  beforeAll(async () => {
    // Login to get access token
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'TestPassword123!'
      });
    
    accessToken = loginResponse.body.data.tokens.accessToken;
  });

  test('Complete avatar scanning workflow', async () => {
    // Start scan
    const scanResponse = await request(app)
      .post('/api/scan')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        scanType: 'photo_based',
        images: [
          { url: 'mock_front.jpg', pose: 'front', quality: 0.95 },
          { url: 'mock_side.jpg', pose: 'side', quality: 0.92 }
        ]
      });

    expect(scanResponse.status).toBe(202);
    const scanId = scanResponse.body.data.scanId;

    // Check scan status
    const statusResponse = await request(app)
      .get(`/api/scan/${scanId}/status`)
      .set('Authorization', `Bearer ${accessToken}`);

    expect(statusResponse.status).toBe(200);
    expect(['queued', 'processing', 'completed']).toContain(
      statusResponse.body.data.status
    );
  });
});
```

### Load Testing

#### Basic Load Test

```bash
# Install artillery for load testing
npm install -g artillery

# Run load test
artillery run load-test.yml
```

#### Load Test Configuration

```yaml
# load-test.yml
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 10
  defaults:
    headers:
      Content-Type: 'application/json'

scenarios:
  - name: "API Health Check"
    requests:
      - get:
          url: "/health"
  
  - name: "User Registration Flow"
    requests:
      - post:
          url: "/api/auth/register"
          json:
            email: "loadtest{{ $randomString() }}@example.com"
            password: "TestPassword123!"
            firstName: "Load"
            lastName: "Test"
            agreeToTerms: true
  
  - name: "Product Browsing"
    requests:
      - get:
          url: "/api/products"
          qs:
            page: 1
            limit: 20
```

### Manual Testing

#### Using cURL

```bash
# Test complete user journey
#!/bin/bash

BASE_URL="http://localhost:3000"

echo "=== Testing Virtual Try-On API ==="

# 1. Health check
echo "1. Health Check"
curl -s $BASE_URL/health | jq

# 2. Register user
echo "2. Register User"
REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "TestPassword123!",
    "firstName": "Test",
    "lastName": "User",
    "agreeToTerms": true
  }')
echo $REGISTER_RESPONSE | jq

# 3. Login
echo "3. Login"
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "TestPassword123!"
  }')
echo $LOGIN_RESPONSE | jq

# Extract access token
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.tokens.accessToken')

# 4. Get profile
echo "4. Get Profile"
curl -s $BASE_URL/api/profile \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq

# 5. Get products
echo "5. Get Products"
curl -s "$BASE_URL/api/products?page=1&limit=10" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.data.products | length'

echo "=== Test Complete ==="
```

#### Using Postman

Import the provided Postman collection:

```json
{
  "info": {
    "name": "Virtual Try-On Mock Server",
    "description": "Complete API testing collection"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": "{{baseUrl}}/health"
      }
    },
    {
      "name": "User Registration",
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
          "raw": "{\n  \"email\": \"{{$timestamp}}@example.com\",\n  \"password\": \"TestPassword123!\",\n  \"firstName\": \"Test\",\n  \"lastName\": \"User\",\n  \"agreeToTerms\": true\n}"
        },
        "url": "{{baseUrl}}/api/auth/register"
      }
    }
  ]
}
```

## Performance Tuning

### Optimization Settings

#### Response Time Configuration

```javascript
// config/performance.js
module.exports = {
  // Response delay configuration
  delays: {
    // Minimum response time (ms)
    min: 100,
    // Maximum response time (ms)  
    max: 2000,
    // Enable realistic delays based on endpoint complexity
    realistic: true,
    // Endpoint-specific delays
    endpoints: {
      '/api/auth/login': { min: 200, max: 800 },
      '/api/scan': { min: 500, max: 1000 },
      '/api/render/tryon': { min: 1000, max: 5000 },
      '/api/products': { min: 150, max: 600 }
    }
  },

  // Concurrency limits
  concurrency: {
    // Maximum concurrent requests
    maxRequests: 1000,
    // Request queue size
    queueSize: 10000,
    // Timeout for queued requests (ms)
    queueTimeout: 30000
  },

  // Memory management
  memory: {
    // Enable memory monitoring
    monitoring: true,
    // Memory threshold for warnings (MB)
    warningThreshold: 512,
    // Garbage collection frequency (ms)
    gcInterval: 300000
  }
};
```

#### Database Optimization

```javascript
// config/database.js
module.exports = {
  sqlite: {
    // Database file path
    filename: './data/mock_server.db',
    // Connection pool settings
    pool: {
      min: 2,
      max: 10,
      acquireTimeoutMillis: 30000,
      createTimeoutMillis: 30000,
      destroyTimeoutMillis: 5000,
      idleTimeoutMillis: 30000,
      reapIntervalMillis: 1000,
      createRetryIntervalMillis: 200
    },
    // Query optimization
    pragmas: {
      'journal_mode': 'WAL',
      'synchronous': 'NORMAL',
      'cache_size': -64000,
      'temp_store': 'memory',
      'mmap_size': 268435456
    }
  }
};
```

### Performance Monitoring

#### Metrics Collection

```javascript
// middleware/performance.js
const prometheus = require('prom-client');

// Create metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new prometheus.Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});

// Performance middleware
const performanceMiddleware = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);
      
    httpRequestsTotal
      .labels(req.method, route, res.statusCode)
      .inc();
  });
  
  next();
};

module.exports = {
  performanceMiddleware,
  metrics: {
    httpRequestDuration,
    httpRequestsTotal,
    activeConnections
  }
};
```

#### Performance Testing

```bash
# Run performance benchmarks
node scripts/performance-benchmark.js

# Generate performance report
node scripts/generate-performance-report.js

# Memory leak detection
node --inspect scripts/memory-test.js
```

## Troubleshooting

### Common Issues

#### Server Won't Start

```bash
# Check if port is already in use
lsof -i :3000
# or
netstat -tlnp | grep 3000

# Kill process using port
kill -9 <PID>

# Check for syntax errors
node -c server.js

# Check dependencies
npm install

# Check environment variables
node -e "console.log(process.env.PORT)"
```

#### Database Connection Issues

```bash
# Reset database
rm -f data/mock_server.db
npm run db:migrate

# Check database permissions
ls -la data/
chmod 664 data/mock_server.db

# Check SQLite installation
sqlite3 --version
```

#### Memory Issues

```javascript
// Enable memory monitoring
process.on('SIGUSR2', () => {
  const used = process.memoryUsage();
  console.log('Memory usage:', {
    rss: Math.round(used.rss / 1024 / 1024) + 'MB',
    heapTotal: Math.round(used.heapTotal / 1024 / 1024) + 'MB',
    heapUsed: Math.round(used.heapUsed / 1024 / 1024) + 'MB',
    external: Math.round(used.external / 1024 / 1024) + 'MB'
  });
});

// Garbage collection
if (global.gc) {
  global.gc();
}
```

#### Authentication Issues

```javascript
// Test JWT token generation
const jwt = require('jsonwebtoken');

const testToken = jwt.sign(
  { sub: 'test_user', email: 'test@example.com' },
  process.env.JWT_SECRET || 'development-secret',
  { expiresIn: '1h' }
);

console.log('Test token:', testToken);

// Verify token
const decoded = jwt.verify(testToken, process.env.JWT_SECRET || 'development-secret');
console.log('Decoded:', decoded);
```

### Debug Mode

#### Enable Debug Logging

```bash
# Enable all debug logs
DEBUG=* npm run dev

# Enable specific debug categories
DEBUG=api,auth,database npm run dev

# Save logs to file
DEBUG=* npm run dev > debug.log 2>&1
```

#### Debug Configuration

```javascript
// config/debug.js
module.exports = {
  // Enable debug mode
  enabled: process.env.NODE_ENV === 'development',
  
  // Debug categories
  categories: {
    api: {
      enabled: true,
      level: 'debug'
    },
    auth: {
      enabled: true,
      level: 'info'
    },
    database: {
      enabled: false,
      level: 'error'
    },
    performance: {
      enabled: true,
      level: 'info'
    }
  },
  
  // Log format
  format: {
    timestamp: true,
    level: true,
    category: true,
    message: true,
    stack: true
  }
};
```

### Health Checks

#### System Health Check

```bash
# Comprehensive health check
curl -s http://localhost:3000/health | jq

# Detailed system info
curl -s http://localhost:3000/api/stats | jq

# Database connectivity test
curl -s http://localhost:3000/api/stats/database | jq

# Memory usage check
curl -s http://localhost:3000/api/stats/memory | jq
```

#### Health Check Script

```bash
#!/bin/bash
# scripts/health-check.sh

BASE_URL="http://localhost:3000"
HEALTH_FILE="/tmp/mock-server-health.json"

echo "Running health checks..."

# Basic health check
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" $BASE_URL/health -o /tmp/health-response.json)
if [ $HEALTH_RESPONSE -eq 200 ]; then
  echo "✓ Basic health check passed"
else
  echo "✗ Basic health check failed (HTTP $HEALTH_RESPONSE)"
fi

# API info check  
API_RESPONSE=$(curl -s -w "%{http_code}" $BASE_URL/api/info -o /tmp/api-response.json)
if [ $API_RESPONSE -eq 200 ]; then
  echo "✓ API info check passed"
else
  echo "✗ API info check failed (HTTP $API_RESPONSE)"
fi

# Database check
DB_RESPONSE=$(curl -s -w "%{http_code}" $BASE_URL/api/stats/database -o /tmp/db-response.json)
if [ $DB_RESPONSE -eq 200 ]; then
  echo "✓ Database check passed"
else
  echo "✗ Database check failed (HTTP $DB_RESPONSE)"
fi

# Generate report
cat > $HEALTH_FILE << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "basic_health": $HEALTH_RESPONSE,
  "api_info": $API_RESPONSE,
  "database": $DB_RESPONSE,
  "response_times": {
    "health": $(curl -s -o /dev/null -w "%{time_total}" $BASE_URL/health),
    "api_info": $(curl -s -o /dev/null -w "%{time_total}" $BASE_URL/api/info),
    "database": $(curl -s -o /dev/null -w "%{time_total}" $BASE_URL/api/stats/database)
  }
}
EOF

echo "Health check report saved to $HEALTH_FILE"
cat $HEALTH_FILE
```

## Docker Deployment

### Dockerfile

```dockerfile
# Dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Create data and logs directories
RUN mkdir -p data logs uploads

# Set permissions
RUN chmod +x start.sh

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start command
CMD ["./start.sh"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  mock-server:
    build: .
    ports:
      - "3000:3000"
      - "3001:3001"  # WebSocket port
    environment:
      - NODE_ENV=production
      - PORT=3000
      - DB_PATH=/app/data/mock_server.db
      - JWT_SECRET=${JWT_SECRET}
      - LOG_LEVEL=info
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
      - ./uploads:/app/uploads
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - mock-server
    restart: unless-stopped

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    restart: unless-stopped

volumes:
  redis-data:
```

### Docker Commands

```bash
# Build the image
docker build -t virtual-tryon-mock-server .

# Run the container
docker run -d \
  --name mock-server \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e JWT_SECRET=your-secret \
  virtual-tryon-mock-server

# Run with Docker Compose
docker-compose up -d

# View logs
docker logs mock-server

# Execute commands in container
docker exec -it mock-server sh

# Update and restart
docker-compose pull
docker-compose up -d

# Backup data volume
docker run --rm -v virtual-tryon_data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data

# Restore data volume
docker run --rm -v virtual-tryon_data:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /
```

### Production Docker Configuration

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  mock-server:
    image: virtual-tryon-mock-server:latest
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        order: start-first
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/logs:/var/log/nginx
    depends_on:
      - mock-server
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  app-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  mock-data:
    driver: local
```

## Production Considerations

### Security

#### Security Headers

```javascript
// middleware/security.js
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');

const securityMiddleware = [
  // Security headers
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'", "wss:"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    crossOriginEmbedderPolicy: false
  }),
  
  // Rate limiting
  rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP',
    standardHeaders: true,
    legacyHeaders: false,
  }),
  
  // Slow down repeated requests
  slowDown({
    windowMs: 15 * 60 * 1000, // 15 minutes
    delayAfter: 50, // allow 50 requests per windowMs without delay
    delayMs: 500 // add 500ms delay per request after delayAfter
  })
];

module.exports = securityMiddleware;
```

#### Environment Security

```bash
# .env.production
NODE_ENV=production

# Strong JWT secret
JWT_SECRET=your-very-secure-jwt-secret-key-256-bits-minimum

# Secure database path
DB_PATH=/var/lib/virtual-tryon/mock_server.db

# Restrict CORS
CORS_ORIGIN=https://yourdomain.com

# Enable all security features
ENABLE_RATE_LIMITING=true
ENABLE_CORS=true
ENABLE_SECURITY_HEADERS=true
ENABLE_INPUT_VALIDATION=true
ENABLE_ERROR_SIMULATION=false

# Logging
LOG_LEVEL=warn
LOG_FILE=/var/log/virtual-tryon/app.log

# Performance
ENABLE_COMPRESSION=true
ENABLE_CACHING=true
MAX_REQUEST_SIZE=10485760
```

### Monitoring

#### Application Monitoring

```javascript
// middleware/monitoring.js
const promClient = require('prom-client');

// Create metrics registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const activeUsers = new promClient.Gauge({
  name: 'active_users_total',
  help: 'Total number of active users'
});

const apiRequestsTotal = new promClient.Counter({
  name: 'api_requests_total',
  help: 'Total number of API requests',
  labelNames: ['endpoint', 'method', 'status']
});

// Register metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(activeUsers);
register.registerMetric(apiRequestsTotal);

// Monitoring middleware
const monitoringMiddleware = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);
      
    apiRequestsTotal
      .labels(route, req.method, res.statusCode)
      .inc();
  });
  
  next();
};

module.exports = {
  monitoringMiddleware,
  register,
  metrics: {
    httpRequestDuration,
    activeUsers,
    apiRequestsTotal
  }
};
```

#### Log Management

```javascript
// utils/logger.js
const winston = require('winston');
const path = require('path');

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'virtual-tryon-mock-server' },
  transports: [
    // Write all logs to file
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/error.log'),
      level: 'error'
    }),
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/combined.log')
    })
  ]
});

// In production, also log to console
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}

module.exports = logger;
```

### Backup and Recovery

#### Database Backup Script

```bash
#!/bin/bash
# scripts/backup-database.sh

BACKUP_DIR="/backups/mock-server"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_PATH="./data/mock_server.db"
BACKUP_FILE="$BACKUP_DIR/mock_server_$TIMESTAMP.db"

# Create backup directory
mkdir -p $BACKUP_DIR

# Create database backup
sqlite3 $DB_PATH ".backup $BACKUP_FILE"

# Compress backup
gzip $BACKUP_FILE

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.db.gz" -mtime +30 -delete

echo "Database backup completed: ${BACKUP_FILE}.gz"
```

#### Recovery Script

```bash
#!/bin/bash
# scripts/restore-database.sh

BACKUP_DIR="/backups/mock-server"
DB_PATH="./data/mock_server.db"

if [ -z "$1" ]; then
  echo "Usage: $0 <backup_file>"
  echo "Available backups:"
  ls -la $BACKUP_DIR/*.db.gz 2>/dev/null || echo "No backups found"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

# Stop server
docker-compose stop mock-server

# Backup current database
cp $DB_PATH "${DB_PATH}.backup.$(date +%Y%m%d_%H%M%S)"

# Restore from backup
gunzip -c $BACKUP_FILE > $DB_PATH

# Restart server
docker-compose start mock-server

echo "Database restored from: $BACKUP_FILE"
```

### Scaling

#### Load Balancer Configuration

```nginx
# nginx.conf
upstream mock_server {
    least_conn;
    server mock-server-1:3000 max_fails=3 fail_timeout=30s;
    server mock-server-2:3000 max_fails=3 fail_timeout=30s;
    server mock-server-3:3000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name api.tryon.com;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    location / {
        # Apply rate limiting
        limit_req zone=api burst=20 nodelay;
        
        # Proxy to upstream
        proxy_pass http://mock_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket upgrade for real-time features
    location /ws {
        proxy_pass http://mock_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://mock_server/health;
        access_log off;
    }
}
```

#### Auto-scaling Configuration

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: virtual-tryon-mock-server
  namespace: virtual-tryon
spec:
  replicas: 3
  selector:
    matchLabels:
      app: virtual-tryon-mock-server
  template:
    metadata:
      labels:
        app: virtual-tryon-mock-server
    spec:
      containers:
      - name: mock-server
        image: virtual-tryon-mock-server:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        - name: DB_PATH
          value: "/app/data/mock_server.db"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: data-volume
          mountPath: /app/data
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: mock-server-data-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: virtual-tryon-mock-server-service
  namespace: virtual-tryon
spec:
  selector:
    app: virtual-tryon-mock-server
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: ClusterIP

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: virtual-tryon-mock-server-hpa
  namespace: virtual-tryon
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: virtual-tryon-mock-server
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

This comprehensive mock server documentation provides everything needed to set up, configure, and manage the Virtual Try-On API mock server for development and testing purposes. It covers installation, configuration, testing procedures, performance optimization, troubleshooting, and production deploymemt considerations.
