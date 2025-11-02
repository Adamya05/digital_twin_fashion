const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');

// Mock data generators
const generateMockUser = (id = null) => ({
  id: id || uuidv4(),
  email: `user${Math.floor(Math.random() * 10000)}@example.com`,
  name: `User ${Math.floor(Math.random() * 1000)}`,
  phone: `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`,
  avatar: `https://randomuser.me/api/portraits/${Math.random() > 0.5 ? 'men' : 'women'}/${Math.floor(Math.random() * 100)}.jpg`,
  preferences: {
    theme: ['light', 'dark', 'auto'][Math.floor(Math.random() * 3)],
    language: ['en', 'es', 'fr'][Math.floor(Math.random() * 3)],
    notifications: Math.random() > 0.5,
    size: ['XS', 'S', 'M', 'L', 'XL'][Math.floor(Math.random() * 5)]
  },
  createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
  updatedAt: new Date().toISOString()
});

const generateMockAvatar = (id = null, userId = null) => ({
  id: id || uuidv4(),
  userId: userId || uuidv4(),
  name: `Avatar ${Math.floor(Math.random() * 1000)}`,
  type: ['basic', 'detailed', 'custom'][Math.floor(Math.random() * 3)],
  imageUrl: `https://randomuser.me/api/portraits/${Math.random() > 0.5 ? 'men' : 'women'}/${Math.floor(Math.random() * 100)}.jpg`,
  modelUrl: `/models/avatar_${Math.floor(Math.random() * 20)}.glb`,
  measurements: {
    height: 150 + Math.floor(Math.random() * 50),
    weight: 45 + Math.floor(Math.random() * 40),
    chest: 75 + Math.floor(Math.random() * 30),
    waist: 60 + Math.floor(Math.random() * 30),
    hips: 80 + Math.floor(Math.random() * 30)
  },
  bodyType: ['slim', 'regular', 'athletic', 'plussize'][Math.floor(Math.random() * 4)],
  skinTone: ['fair', 'light', 'medium', 'tan', 'dark'][Math.floor(Math.random() * 5)],
  hairColor: ['black', 'brown', 'blonde', 'red', 'gray'][Math.floor(Math.random() * 5)],
  status: ['pending', 'processing', 'completed', 'error'][Math.floor(Math.random() * 4)],
  progress: Math.floor(Math.random() * 100),
  createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
  updatedAt: new Date().toISOString()
});

const generateMockProduct = (id = null, category = null) => {
  const categories = ['tops', 'bottoms', 'dresses', 'outerwear', 'accessories', 'footwear', 'activewear'];
  const brands = ['Zara', 'H&M', 'Uniqlo', 'Mango', 'Bershka', 'Nike', 'Adidas', 'Gap'];
  const colors = ['Black', 'White', 'Navy', 'Gray', 'Beige', 'Red', 'Blue', 'Green'];
  const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  
  const selectedCategory = category || categories[Math.floor(Math.random() * categories.length)];
  
  return {
    id: id || `prod_${Math.floor(Math.random() * 10000)}`,
    name: `${selectedCategory.charAt(0).toUpperCase() + selectedCategory.slice(1)} Item ${Math.floor(Math.random() * 1000)}`,
    description: `High-quality ${selectedCategory} with modern design and comfortable fit. Perfect for everyday wear.`,
    price: Math.round((Math.random() * 200 + 10) * 100) / 100,
    originalPrice: Math.round((Math.random() * 300 + 20) * 100) / 100,
    currency: 'USD',
    brand: brands[Math.floor(Math.random() * brands.length)],
    category: selectedCategory,
    subcategory: `${selectedCategory}_sub_${Math.floor(Math.random() * 10)}`,
    colors: [colors[Math.floor(Math.random() * colors.length)]],
    sizes: sizes,
    material: ['Cotton', 'Polyester', 'Linen', 'Silk', 'Denim', 'Wool'][Math.floor(Math.random() * 6)],
    style: ['Casual', 'Formal', 'Business', 'Party', 'Sport'][Math.floor(Math.random() * 5)],
    season: ['Spring', 'Summer', 'Fall', 'Winter', 'All Season'][Math.floor(Math.random() * 5)],
    stock: Math.floor(Math.random() * 100) + 1,
    rating: Math.round((Math.random() * 2 + 3) * 10) / 10,
    reviewCount: Math.floor(Math.random() * 500),
    isAvailable: Math.random() > 0.1,
    isNewArrival: Math.random() > 0.8,
    isOnSale: Math.random() > 0.7,
    imageUrl: `https://picsum.photos/400/600?random=${Math.floor(Math.random() * 1000)}`,
    gallery: Array.from({ length: 3 }, (_, i) => 
      `https://picsum.photos/400/600?random=${Math.floor(Math.random() * 1000) + i}`
    ),
    modelUrl: selectedCategory !== 'accessories' && selectedCategory !== 'footwear' 
      ? `/models/product_${Math.floor(Math.random() * 50)}.glb` 
      : null,
    metadata: {
      weight: Math.round((Math.random() * 2 + 0.1) * 100) / 100,
      dimensions: {
        length: Math.round((Math.random() * 100 + 20) * 10) / 10,
        width: Math.round((Math.random() * 50 + 10) * 10) / 10,
        height: Math.round((Math.random() * 20 + 5) * 10) / 10
      },
      care: ['Machine wash', 'Hand wash', 'Dry clean only'][Math.floor(Math.random() * 3)]
    },
    tags: Array.from({ length: 3 }, () => 
      ['trending', 'sale', 'new', 'bestseller', 'eco-friendly'][Math.floor(Math.random() * 5)]
    ),
    createdAt: new Date(Date.now() - Math.random() * 180 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date().toISOString()
  };
};

const generateMockCart = (userId = null, items = null) => {
  const mockItems = items || Array.from({ length: Math.floor(Math.random() * 5) + 1 }, () => {
    const product = generateMockProduct();
    return {
      id: uuidv4(),
      productId: product.id,
      product,
      quantity: Math.floor(Math.random() * 3) + 1,
      size: product.sizes[Math.floor(Math.random() * product.sizes.length)],
      color: product.colors[0],
      addedAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString()
    };
  });

  const total = mockItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);

  return {
    id: uuidv4(),
    userId: userId || uuidv4(),
    items: mockItems,
    total: Math.round(total * 100) / 100,
    itemCount: mockItems.reduce((sum, item) => sum + item.quantity, 0),
    createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date().toISOString()
  };
};

const generateMockOrder = (userId = null, cart = null) => {
  const mockCart = cart || generateMockCart(userId);
  const status = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'][Math.floor(Math.random() * 5)];
  
  return {
    id: uuidv4(),
    userId: mockCart.userId,
    items: mockCart.items,
    totalAmount: mockCart.total,
    shippingCost: Math.round((Math.random() * 20 + 5) * 100) / 100,
    tax: Math.round(mockCart.total * 0.08 * 100) / 100,
    finalAmount: Math.round((mockCart.total + (Math.random() * 20 + 5)) * 100) / 100,
    status,
    paymentStatus: ['pending', 'paid', 'failed', 'refunded'][Math.floor(Math.random() * 4)],
    shippingAddress: {
      street: `${Math.floor(Math.random() * 9999) + 1} Main St`,
      city: ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'][Math.floor(Math.random() * 5)],
      state: ['NY', 'CA', 'IL', 'TX', 'AZ'][Math.floor(Math.random() * 5)],
      zipCode: `${Math.floor(Math.random() * 90000) + 10000}`,
      country: 'United States'
    },
    paymentMethod: {
      type: ['credit_card', 'debit_card', 'paypal', 'apple_pay'][Math.floor(Math.random() * 4)],
      last4: String(Math.floor(Math.random() * 10000)).padStart(4, '0'),
      brand: ['Visa', 'Mastercard', 'American Express'][Math.floor(Math.random() * 3)]
    },
    trackingNumber: Math.random() > 0.5 ? `TRK${Math.floor(Math.random() * 1000000)}` : null,
    estimatedDelivery: status === 'shipped' || status === 'delivered' 
      ? new Date(Date.now() + Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString() 
      : null,
    notes: Math.random() > 0.8 ? 'Please leave at door if not home' : null,
    createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date().toISOString()
  };
};

const generateMockPayment = (amount = null, orderId = null) => ({
  id: uuidv4(),
  orderId: orderId || uuidv4(),
  amount: amount || Math.round((Math.random() * 500 + 10) * 100) / 100,
  currency: 'USD',
  status: ['pending', 'processing', 'succeeded', 'failed', 'cancelled'][Math.floor(Math.random() * 5)],
  paymentMethod: {
    type: ['card', 'paypal', 'apple_pay', 'google_pay'][Math.floor(Math.random() * 4)],
    id: uuidv4()
  },
  transactionId: `txn_${Math.floor(Math.random() * 1000000)}`,
  gateway: 'razorpay',
  gatewayResponse: {
    razorpay_order_id: `order_${Math.floor(Math.random() * 1000000)}`,
    razorpay_payment_id: `pay_${Math.floor(Math.random() * 1000000)}`,
    razorpay_signature: `sig_${Math.floor(Math.random() * 1000000)}`
  },
  fees: Math.round(amount * 0.029 * 100) / 100,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString()
});

const generateMockScanSession = (userId = null) => {
  const status = ['pending', 'processing', 'completed', 'error'][Math.floor(Math.random() * 4)];
  const progress = status === 'completed' ? 100 : Math.floor(Math.random() * 90);
  
  return {
    id: uuidv4(),
    userId: userId || uuidv4(),
    status,
    progress,
    message: status === 'processing' ? 'Processing your avatar...' 
      : status === 'completed' ? 'Avatar generation completed successfully'
      : status === 'error' ? 'An error occurred during avatar generation'
      : 'Preparing avatar generation...',
    method: ['camera', 'upload', 'manual'][Math.floor(Math.random() * 3)],
    startTime: new Date(Date.now() - Math.random() * 30 * 60 * 1000).toISOString(),
    endTime: status === 'completed' || status === 'error' 
      ? new Date(Date.now() - Math.random() * 10 * 60 * 1000).toISOString() 
      : null,
    result: status === 'completed' ? generateMockAvatar(null, userId) : null,
    error: status === 'error' ? 'Image quality too low. Please retake photo.' : null
  };
};

const generateMockTryOnResult = (avatarId = null, productId = null) => ({
  id: uuidv4(),
  avatarId: avatarId || uuidv4(),
  productId: productId || `prod_${Math.floor(Math.random() * 10000)}`,
  imageUrl: `https://picsum.photos/400/600?random=${Math.floor(Math.random() * 1000)}`,
  modelUrl: `/models/tryon_${Math.floor(Math.random() * 50)}.glb`,
  fitScore: Math.round((Math.random() * 2 + 7) * 10) / 10, // 7.0 - 9.0
  confidence: Math.round((Math.random() * 30 + 70)), // 70 - 100
  processingTime: Math.floor(Math.random() * 30) + 10, // 10-40 seconds
  quality: ['low', 'medium', 'high', 'ultra'][Math.floor(Math.random() * 4)],
  status: 'completed',
  createdAt: new Date().toISOString()
});

const generateMockCloset = (userId = null) => ({
  id: uuidv4(),
  userId: userId || uuidv4(),
  name: `Closet ${Math.floor(Math.random() * 1000)}`,
  items: Array.from({ length: Math.floor(Math.random() * 20) + 5 }, () => generateMockProduct()),
  totalItems: Math.floor(Math.random() * 20) + 5,
  isPublic: Math.random() > 0.8,
  tags: Array.from({ length: 3 }, () => 
    ['casual', 'formal', 'sport', 'party', 'work'][Math.floor(Math.random() * 5)]
  ),
  createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000).toISOString(),
  updatedAt: new Date().toISOString()
});

// Utility functions
const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
};

const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

const generateJWTPayload = (user) => ({
  id: user.id,
  email: user.email,
  name: user.name,
  role: user.role || 'user'
});

const generateRefreshToken = (user) => {
  return uuidv4() + '.' + uuidv4();
};

// Export all generators and utilities
module.exports = {
  generateMockUser,
  generateMockAvatar,
  generateMockProduct,
  generateMockCart,
  generateMockOrder,
  generateMockPayment,
  generateMockScanSession,
  generateMockTryOnResult,
  generateMockCloset,
  hashPassword,
  comparePassword,
  generateJWTPayload,
  generateRefreshToken
};