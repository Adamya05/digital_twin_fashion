const express = require('express');
const router = express.Router();
const { query } = require('express-validator');

const { 
  validateProductQuery, 
  validateProductId, 
  handleValidationErrors 
} = require('../middleware/validation');
const { db } = require('../utils/database');
const { generateMockProduct } = require('../utils/mockData');
const logger = require('../utils/logger');

// Get all products with pagination and filtering
router.get('/', 
  validateProductQuery,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { 
        page = 1, 
        limit = 20, 
        category, 
        search, 
        minPrice, 
        maxPrice,
        sort = 'newest',
        brand,
        size,
        color,
        style,
        season,
        isOnSale,
        isNewArrival,
        isAvailable
      } = req.query;

      // Build search criteria
      const criteria = {};
      
      if (category) criteria.category = category;
      if (brand) criteria.brand = brand;
      if (size) criteria.sizes = { $in: [size] };
      if (color) criteria.colors = { $in: [color] };
      if (style) criteria.style = style;
      if (season) criteria.season = season;
      if (isOnSale !== undefined) criteria.isOnSale = isOnSale === 'true';
      if (isNewArrival !== undefined) criteria.isNewArrival = isNewArrival === 'true';
      if (isAvailable !== undefined) criteria.isAvailable = isAvailable === 'true';

      // Price range filtering
      const priceCriteria = {};
      if (minPrice) priceCriteria.$gte = parseFloat(minPrice);
      if (maxPrice) priceCriteria.$lte = parseFloat(maxPrice);
      if (Object.keys(priceCriteria).length > 0) {
        criteria.price = priceCriteria;
      }

      // Text search
      if (search) {
        criteria.$or = [
          { name: { $in: [search] } },
          { description: { $in: [search] } },
          { brand: { $in: [search] } },
          { tags: { $in: [search] } }
        ];
      }

      // Determine sort order
      let sortOptions = {};
      switch (sort) {
        case 'price_asc':
          sortOptions = { field: 'price', order: 'asc' };
          break;
        case 'price_desc':
          sortOptions = { field: 'price', order: 'desc' };
          break;
        case 'name_asc':
          sortOptions = { field: 'name', order: 'asc' };
          break;
        case 'name_desc':
          sortOptions = { field: 'name', order: 'desc' };
          break;
        case 'rating_desc':
          sortOptions = { field: 'rating', order: 'desc' };
          break;
        case 'newest':
        default:
          sortOptions = { field: 'createdAt', order: 'desc' };
          break;
      }

      const result = await db.findMany('products', criteria, {
        sort: sortOptions,
        pagination: { 
          page: parseInt(page), 
          limit: parseInt(limit) 
        }
      });

      // Transform products for response
      const products = result.data.map(product => ({
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        currency: product.currency,
        brand: product.brand,
        category: product.category,
        subcategory: product.subcategory,
        colors: product.colors,
        sizes: product.sizes,
        rating: product.rating,
        reviewCount: product.reviewCount,
        imageUrl: product.imageUrl,
        gallery: product.gallery,
        modelUrl: product.modelUrl,
        isAvailable: product.isAvailable,
        isOnSale: product.isOnSale,
        isNewArrival: product.isNewArrival,
        tags: product.tags,
        createdAt: product.createdAt
      }));

      logger.info('Products retrieved', { 
        count: products.length, 
        page: parseInt(page), 
        limit: parseInt(limit),
        filters: { category, search, minPrice, maxPrice, sort }
      });

      res.json({
        success: true,
        data: {
          products,
          pagination: {
            page: result.page,
            limit: result.limit,
            total: result.total,
            totalPages: result.totalPages,
            hasNextPage: result.page < result.totalPages,
            hasPrevPage: result.page > 1
          },
          filters: {
            category,
            search,
            minPrice,
            maxPrice,
            sort,
            brand,
            size,
            color,
            style,
            season,
            isOnSale,
            isNewArrival,
            isAvailable
          }
        },
        message: 'Products retrieved successfully'
      });
    } catch (error) {
      logger.error('Get products error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PRODUCTS_FETCH_FAILED',
          message: 'Failed to fetch products'
        }
      });
    }
  }
);

// Get single product by ID
router.get('/:id', 
  validateProductId,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { id } = req.params;

      const product = await db.findById('products', id);
      if (!product) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'PRODUCT_NOT_FOUND',
            message: 'Product not found'
          }
        });
      }

      // Get related products (same category, excluding current product)
      const relatedCriteria = { 
        category: product.category,
        isAvailable: true
      };
      
      const relatedResult = await db.findMany('products', relatedCriteria, {
        pagination: { page: 1, limit: 8 }
      });

      const relatedProducts = relatedResult.data
        .filter(p => p.id !== id)
        .slice(0, 4)
        .map(p => ({
          id: p.id,
          name: p.name,
          price: p.price,
          imageUrl: p.imageUrl,
          rating: p.rating,
          reviewCount: p.reviewCount
        }));

      logger.info('Product retrieved', { productId: id });

      res.json({
        success: true,
        data: {
          ...product,
          relatedProducts
        },
        message: 'Product retrieved successfully'
      });
    } catch (error) {
      logger.error('Get product error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PRODUCT_FETCH_FAILED',
          message: 'Failed to fetch product'
        }
      });
    }
  }
);

// Get product categories
router.get('/meta/categories', async (req, res) => {
  try {
    const result = await db.findMany('products', { isAvailable: true });
    
    // Extract unique categories with counts
    const categoryMap = new Map();
    result.data.forEach(product => {
      if (product.category) {
        const existing = categoryMap.get(product.category) || { count: 0, subcategories: new Set() };
        existing.count++;
        if (product.subcategory) {
          existing.subcategories.add(product.subcategory);
        }
        categoryMap.set(product.category, existing);
      }
    });

    const categories = Array.from(categoryMap.entries()).map(([category, data]) => ({
      name: category,
      displayName: category.charAt(0).toUpperCase() + category.slice(1),
      count: data.count,
      subcategories: Array.from(data.subcategories)
    }));

    res.json({
      success: true,
      data: { categories },
      message: 'Categories retrieved successfully'
    });
  } catch (error) {
    logger.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CATEGORIES_FETCH_FAILED',
        message: 'Failed to fetch categories'
      }
    });
  }
});

// Get product filters
router.get('/meta/filters', async (req, res) => {
  try {
    const { category } = req.query;
    
    const criteria = { isAvailable: true };
    if (category) criteria.category = category;

    const result = await db.findMany('products', criteria);

    // Extract unique values for filtering
    const brands = new Set();
    const colors = new Set();
    const sizes = new Set();
    const styles = new Set();
    const seasons = new Set();
    const materials = new Set();

    let minPrice = Infinity;
    let maxPrice = 0;

    result.data.forEach(product => {
      if (product.brand) brands.add(product.brand);
      if (product.colors) product.colors.forEach(color => colors.add(color));
      if (product.sizes) product.sizes.forEach(size => sizes.add(size));
      if (product.style) styles.add(product.style);
      if (product.season) seasons.add(product.season);
      if (product.material) materials.add(product.material);
      
      if (product.price) {
        minPrice = Math.min(minPrice, product.price);
        maxPrice = Math.max(maxPrice, product.price);
      }
    });

    res.json({
      success: true,
      data: {
        brands: Array.from(brands).sort(),
        colors: Array.from(colors).sort(),
        sizes: Array.from(sizes).sort(),
        styles: Array.from(styles).sort(),
        seasons: Array.from(seasons).sort(),
        materials: Array.from(materials).sort(),
        priceRange: {
          min: minPrice === Infinity ? 0 : Math.floor(minPrice),
          max: Math.ceil(maxPrice)
        }
      },
      message: 'Product filters retrieved successfully'
    });
  } catch (error) {
    logger.error('Get filters error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'FILTERS_FETCH_FAILED',
        message: 'Failed to fetch product filters'
      }
    });
  }
});

// Get featured products
router.get('/featured/list', async (req, res) => {
  try {
    const { type = 'all', limit = 10 } = req.query;
    
    let criteria = { isAvailable: true };
    
    switch (type) {
      case 'sale':
        criteria.isOnSale = true;
        break;
      case 'new':
        criteria.isNewArrival = true;
        break;
      case 'bestsellers':
        // Filter by high rating or review count
        criteria.rating = { $gte: 4.0 };
        break;
      case 'all':
      default:
        break;
    }

    const result = await db.findMany('products', criteria, {
      sort: { field: 'rating', order: 'desc' },
      pagination: { page: 1, limit: parseInt(limit) }
    });

    const products = result.data.map(product => ({
      id: product.id,
      name: product.name,
      price: product.price,
      originalPrice: product.originalPrice,
      imageUrl: product.imageUrl,
      rating: product.rating,
      reviewCount: product.reviewCount,
      isOnSale: product.isOnSale,
      isNewArrival: product.isNewArrival
    }));

    res.json({
      success: true,
      data: {
        products,
        type,
        count: products.length
      },
      message: 'Featured products retrieved successfully'
    });
  } catch (error) {
    logger.error('Get featured products error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'FEATURED_PRODUCTS_FETCH_FAILED',
        message: 'Failed to fetch featured products'
      }
    });
  }
});

// Search products with autocomplete
router.get('/search/suggestions', async (req, res) => {
  try {
    const { q, limit = 5 } = req.query;
    
    if (!q || q.length < 2) {
      return res.json({
        success: true,
        data: { suggestions: [] },
        message: 'Query too short for suggestions'
      });
    }

    const searchTerm = q.toLowerCase();
    
    const result = await db.findMany('products', { isAvailable: true }, {
      pagination: { page: 1, limit: 50 }
    });

    // Filter products that match the search term
    const matchingProducts = result.data.filter(product => 
      product.name.toLowerCase().includes(searchTerm) ||
      product.description.toLowerCase().includes(searchTerm) ||
      product.brand.toLowerCase().includes(searchTerm) ||
      product.category.toLowerCase().includes(searchTerm) ||
      (product.tags && product.tags.some(tag => tag.toLowerCase().includes(searchTerm)))
    );

    // Create suggestions
    const suggestions = [];
    
    // Add product names
    matchingProducts
      .slice(0, limit)
      .forEach(product => {
        suggestions.push({
          type: 'product',
          text: product.name,
          id: product.id,
          imageUrl: product.imageUrl,
          price: product.price
        });
      });

    // Add categories
    const categories = new Set(matchingProducts.map(p => p.category));
    Array.from(categories)
      .filter(cat => cat.toLowerCase().includes(searchTerm))
      .slice(0, 2)
      .forEach(category => {
        suggestions.push({
          type: 'category',
          text: category.charAt(0).toUpperCase() + category.slice(1),
          category
        });
      });

    res.json({
      success: true,
      data: {
        suggestions: suggestions.slice(0, limit),
        query: q
      },
      message: 'Search suggestions retrieved successfully'
    });
  } catch (error) {
    logger.error('Get search suggestions error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'SUGGESTIONS_FETCH_FAILED',
        message: 'Failed to fetch search suggestions'
      }
    });
  }
});

module.exports = router;