# Interactive API Documentation

This document provides interactive examples and live testing capabilities for the Virtual Try-On API.

## Quick Start

### Base URL
- **Production**: `https://api.tryon.com/v1`
- **Staging**: `https://staging-api.tryon.com/v1`
- **Development**: `https://dev-api.tryon.com/v1`

### Quick Test cURL

```bash
# Test server health
curl -X GET https://api.tryon.com/v1/health

# Register a test user
curl -X POST https://api.tryon.com/v1/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "firstName": "Test",
    "lastName": "User",
    "agreeToTerms": true
  }'

# Login and get token
curl -X POST https://api.tryon.com/v1/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'
```

## Interactive Examples by Category

### 1. Authentication Flow

#### Complete Authentication Example

```javascript
// Login and get access token
const login = async (email, password) => {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  const data = await response.json();
  return data;
};

// Use the access token for API calls
const accessToken = data.data.tokens.accessToken;

// Make authenticated request
const getProfile = async () => {
  const response = await fetch('/api/profile', {
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });
  return await response.json();
};
```

#### Social Login Example (Google)

```bash
curl -X POST https://api.tryon.com/v1/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "google",
    "providerToken": "ya29.a0AfH6SMB..."
  }'
```

### 2. Avatar Scanning

#### Start Scan with Real Images

```bash
curl -X POST https://api.tryon.com/v1/api/scan \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "scanType": "photo_based",
    "images": [
      {
        "url": "https://storage.tryon.com/scans/user_front_001.jpg",
        "pose": "front",
        "quality": 0.95
      },
      {
        "url": "https://storage.tryon.com/scans/user_side_001.jpg", 
        "pose": "side",
        "quality": 0.92
      },
      {
        "url": "https://storage.tryon.com/scans/user_back_001.jpg",
        "pose": "back", 
        "quality": 0.88
      }
    ],
    "userPreferences": {
      "bodyType": "athletic",
      "height": 175,
      "weight": 70,
      "preferences": ["casual", "business", "athletic"]
    }
  }'
```

#### Track Scan Progress

```javascript
const trackScanProgress = async (scanId) => {
  let attempts = 0;
  const maxAttempts = 60; // 10 minutes maximum
  
  while (attempts < maxAttempts) {
    const response = await fetch(`/api/scan/${scanId}/status`, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    const data = await response.json();
    
    if (data.data.status === 'completed') {
      console.log('Scan completed! Avatar ID:', data.data.avatarId);
      return data.data.avatarId;
    }
    
    console.log(`Progress: ${data.data.progress}% - ${data.data.stage}`);
    await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
    attempts++;
  }
  
  throw new Error('Scan timed out');
};
```

### 3. Product Catalog

#### Advanced Product Search

```bash
# Search with multiple filters
curl -X GET "https://api.tryon.com/v1/api/products?page=1&limit=20&category=tops&brand=Nike&priceMin=25&priceMax=100&size=M,L&color=blue,black&sortBy=popularity&tryonAvailable=true" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Product Search with Suggestions

```bash
curl -X GET "https://api.tryon.com/v1/api/products/search?q=blue denim jacket&suggest=true&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Dynamic Product Filtering

```javascript
const filterProducts = async (filters) => {
  const queryParams = new URLSearchParams();
  
  // Add filters to query
  Object.entries(filters).forEach(([key, value]) => {
    if (Array.isArray(value)) {
      value.forEach(v => queryParams.append(key, v));
    } else if (value !== null && value !== undefined) {
      queryParams.append(key, value);
    }
  });
  
  const response = await fetch(`/api/products?${queryParams}`, {
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });
  
  return await response.json();
};

// Example usage
const products = await filterProducts({
  category: 'tops',
  brand: ['Nike', 'Adidas'],
  priceMin: 20,
  priceMax: 100,
  size: ['M', 'L'],
  color: ['blue', 'black'],
  tryonAvailable: true,
  sortBy: 'price_asc'
});
```

### 4. 3D Try-On Rendering

#### Create Try-On Render

```bash
curl -X POST https://api.tryon.com/v1/api/render/tryon \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

#### Monitor Render Progress

```javascript
const monitorRender = async (renderId) => {
  let attempts = 0;
  const maxAttempts = 30; // 5 minutes maximum
  
  while (attempts < maxAttempts) {
    const response = await fetch(`/api/render/${renderId}/status`, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    const data = await response.json();
    
    if (data.data.status === 'completed') {
      console.log('Render completed!');
      return {
        renderId: data.data.renderId,
        previewUrl: data.data.previewUrl,
        finalUrl: data.data.finalUrl
      };
    }
    
    console.log(`Render progress: ${data.data.progress}% - ${data.data.stage}`);
    
    if (data.data.previewUrl) {
      console.log('Preview available at:', data.data.previewUrl);
    }
    
    await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
    attempts++;
  }
  
  throw new Error('Render timed out');
};
```

### 5. Shopping Cart

#### Add Item with Try-On Reference

```bash
curl -X POST https://api.tryon.com/v1/api/cart/add \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "prod_123abc456",
    "variantId": "var_123_001",
    "quantity": 1,
    "metadata": {
      "tryonRenderId": "render_xyz789abc",
      "size_confirmed": true,
      "color_confirmed": true,
      "preferred_fit": "regular"
    }
  }'
```

#### Update Cart Item Quantity

```bash
curl -X PUT https://api.tryon.com/v1/api/cart/item/cart_item_001/quantity \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 2,
    "operation": "set"
  }'
```

### 6. Order Management

#### Create Order with Shipping Details

```bash
curl -X POST https://api.tryon.com/v1/api/order/create \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "cartId": "cart_abc123def456",
    "shippingAddress": {
      "firstName": "John",
      "lastName": "Doe",
      "street": "123 Main Street",
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
    "notes": "Please leave at front door",
    "couponCode": "WELCOME10"
  }'
```

### 7. User Profile & Closet

#### Update User Preferences

```bash
curl -X PUT https://api.tryon.com/v1/api/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Smith",
    "phoneNumber": "+1-555-0123",
    "preferences": {
      "notifications": {
        "email": true,
        "push": true,
        "marketing": false
      },
      "privacy": {
        "profileVisibility": "friends",
        "dataSharing": true
      },
      "units": {
        "height": "cm",
        "weight": "kg"
      }
    }
  }'
```

#### Add to Virtual Closet

```bash
curl -X POST https://api.tryon.com/v1/api/closet/add \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "prod_789def123",
    "variantId": "var_789_002",
    "type": "owned",
    "purchaseInfo": {
      "orderId": "order_xyz789abc",
      "purchaseDate": "2025-01-15",
      "price": 49.99
    },
    "notes": "Favorite casual shirt"
  }'
```

### 8. Payment Processing

#### Create Payment Order

```bash
curl -X POST https://api.tryon.com/v1/api/payment/create-order \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

#### Verify Payment

```bash
curl -X POST https://api.tryon.com/v1/api/payment/verify \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "paymentOrderId": "pay_abc123def456",
    "transactionId": "txn_789xyz123",
    "verificationCode": "123456"
  }'
```

## Interactive Testing Tools

### Postman Collection

Import this collection for complete API testing:

```json
{
  "info": {
    "name": "Virtual Try-On API - Interactive",
    "description": "Interactive API collection with examples and tests"
  },
  "variable": [
    {
      "key": "baseUrl",
      "value": "https://api.tryon.com/v1"
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
        "value": "{{accessToken}}"
      }
    ]
  }
}
```

### JavaScript SDK Example

```javascript
class TryOnAPI {
  constructor(baseUrl, accessToken = null) {
    this.baseUrl = baseUrl;
    this.accessToken = accessToken;
  }

  setAccessToken(token) {
    this.accessToken = token;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...(this.accessToken && { Authorization: `Bearer ${this.accessToken}` }),
        ...options.headers
      },
      ...options
    };

    const response = await fetch(url, config);
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error?.message || 'API request failed');
    }

    return await response.json();
  }

  // Authentication methods
  async login(email, password) {
    const response = await this.request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });
    
    this.setAccessToken(response.data.tokens.accessToken);
    return response;
  }

  async register(userData) {
    return await this.request('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData)
    });
  }

  // Avatar methods
  async startScan(scanData) {
    return await this.request('/api/scan', {
      method: 'POST',
      body: JSON.stringify(scanData)
    });
  }

  async getScanStatus(scanId) {
    return await this.request(`/api/scan/${scanId}/status`);
  }

  // Product methods
  async getProducts(filters = {}) {
    const query = new URLSearchParams(filters).toString();
    return await this.request(`/api/products?${query}`);
  }

  async searchProducts(query, suggestions = false) {
    return await this.request(`/api/products/search?q=${query}&suggest=${suggestions}`);
  }

  // Try-on methods
  async createTryOnRender(renderData) {
    return await this.request('/api/render/tryon', {
      method: 'POST',
      body: JSON.stringify(renderData)
    });
  }

  async getRenderStatus(renderId) {
    return await this.request(`/api/render/${renderId}/status`);
  }

  // Cart methods
  async addToCart(itemData) {
    return await this.request('/api/cart/add', {
      method: 'POST',
      body: JSON.stringify(itemData)
    });
  }

  async getCart() {
    return await this.request('/api/cart');
  }

  // Order methods
  async createOrder(orderData) {
    return await this.request('/api/order/create', {
      method: 'POST',
      body: JSON.stringify(orderData)
    });
  }

  async getOrder(orderId) {
    return await this.request(`/api/order/${orderId}`);
  }
}

// Usage example
const api = new TryOnAPI('https://api.tryon.com/v1');

// Login and use API
async function example() {
  try {
    const loginResult = await api.login('user@example.com', 'password');
    console.log('Logged in:', loginResult.data.user.email);
    
    const products = await api.getProducts({ category: 'tops', limit: 10 });
    console.log('Products:', products.data.products.length);
    
    const scanResult = await api.startScan({
      scanType: 'photo_based',
      images: [...],
      userPreferences: {...}
    });
    
    const scanStatus = await api.getScanStatus(scanResult.data.scanId);
    console.log('Scan status:', scanStatus.data.status);
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}
```

## Error Handling Examples

### Global Error Handler

```javascript
const handleAPIError = (error, response) => {
  console.error('API Error:', error.message);
  
  switch (error.code) {
    case 'INVALID_CREDENTIALS':
      // Redirect to login
      window.location.href = '/login';
      break;
    case 'RATE_LIMIT_EXCEEDED':
      // Show rate limit message
      showNotification('Too many requests. Please wait.', 'warning');
      break;
    case 'AVATAR_NOT_READY':
      // Show avatar processing message
      showNotification('Avatar is still processing. Please wait.', 'info');
      break;
    default:
      // Show generic error
      showNotification('An error occurred. Please try again.', 'error');
  }
};

const api = new TryOnAPI('https://api.tryon.com/v1');

// Wrap API calls with error handling
const safeApiCall = async (apiFunction, ...args) => {
  try {
    return await apiFunction(...args);
  } catch (error) {
    handleAPIError(error);
    throw error;
  }
};

// Usage
const scanStatus = await safeApiCall(api.getScanStatus, 'scan_123');
```

## Rate Limiting Handling

```javascript
const withRateLimitHandling = async (apiCall, ...args) => {
  try {
    return await apiCall(...args);
  } catch (error) {
    if (error.code === 'RATE_LIMIT_EXCEEDED') {
      const retryAfter = error.details.resetTime - Date.now();
      
      // Wait and retry
      await new Promise(resolve => setTimeout(resolve, retryAfter));
      return await apiCall(...args);
    }
    throw error;
  }
};

// Auto-retry on rate limit
const retryWithBackoff = async (fn, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.code === 'RATE_LIMIT_EXCEEDED' && i < maxRetries - 1) {
        const delay = Math.pow(2, i) * 1000; // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw error;
    }
  }
};
```

## WebSocket Integration

```javascript
class TryOnWebSocket {
  constructor(accessToken) {
    this.accessToken = accessToken;
    this.ws = null;
    this.listeners = new Map();
  }

  connect() {
    this.ws = new WebSocket(`wss://api.tryon.com/v1/ws?token=${this.accessToken}`);
    
    this.ws.onopen = () => {
      console.log('WebSocket connected');
      this.subscribe('scan_status');
      this.subscribe('render_status');
    };

    this.ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      this.notifyListeners(data.type, data);
    };

    this.ws.onclose = () => {
      console.log('WebSocket disconnected, reconnecting...');
      setTimeout(() => this.connect(), 5000);
    };
  }

  subscribe(eventType) {
    this.ws.send(JSON.stringify({
      action: 'subscribe',
      event: eventType
    }));
  }

  addListener(eventType, callback) {
    if (!this.listeners.has(eventType)) {
      this.listeners.set(eventType, []);
    }
    this.listeners.get(eventType).push(callback);
  }

  notifyListeners(eventType, data) {
    if (this.listeners.has(eventType)) {
      this.listeners.get(eventType).forEach(callback => callback(data));
    }
  }
}

// Usage
const ws = new TryOnWebSocket(accessToken);
ws.connect();

// Listen for scan updates
ws.addListener('scan_status', (data) => {
  console.log('Scan update:', data.progress, data.stage);
  updateScanProgress(data.scanId, data.progress);
});

// Listen for render updates  
ws.addListener('render_status', (data) => {
  console.log('Render update:', data.progress, data.stage);
  updateRenderProgress(data.renderId, data.progress);
});
```