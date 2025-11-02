const fs = require('fs').promises;
const path = require('path');
const {
  generateMockUser,
  generateMockProduct,
  generateMockAvatar,
  generateMockCart,
  generateMockOrder,
  generateMockPayment,
  generateMockScanSession,
  generateMockCloset
} = require('./mockData');
const logger = require('./logger');

// In-memory database structure
const database = {
  users: new Map(),
  products: new Map(),
  avatars: new Map(),
  carts: new Map(),
  orders: new Map(),
  payments: new Map(),
  scanSessions: new Map(),
  closetItems: new Map(),
  sessions: new Map()
};

// Database utilities
class MockDatabase {
  constructor() {
    this.dataPath = path.join(__dirname, '../data');
    this.backupPath = path.join(__dirname, '../backups');
    this.autoSave = process.env.AUTO_SAVE === 'true';
    this.saveInterval = 60000; // 1 minute
  }

  async initialize() {
    try {
      // Ensure directories exist
      await fs.mkdir(this.dataPath, { recursive: true });
      await fs.mkdir(this.backupPath, { recursive: true });

      // Load existing data
      await this.loadData();

      // Set up auto-save
      if (this.autoSave) {
        setInterval(() => this.saveData(), this.saveInterval);
      }

      logger.info('Mock database initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize mock database:', error);
      throw error;
    }
  }

  async loadData() {
    try {
      const files = ['users.json', 'products.json', 'avatars.json', 'carts.json', 'orders.json'];
      
      for (const file of files) {
        const filePath = path.join(this.dataPath, file);
        
        try {
          const data = await fs.readFile(filePath, 'utf8');
          const parsed = JSON.parse(data);
          
          // Convert arrays back to Maps for each table
          Object.keys(parsed).forEach(table => {
            if (database[table]) {
              database[table] = new Map(parsed[table]);
            }
          });
        } catch (err) {
          // File doesn't exist or is empty, skip
          logger.info(`No existing data found for ${file}`);
        }
      }
    } catch (error) {
      logger.error('Error loading database data:', error);
    }
  }

  async saveData() {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupFile = path.join(this.backupPath, `backup-${timestamp}.json`);
      
      // Convert Maps to objects for JSON serialization
      const dataToSave = {};
      Object.keys(database).forEach(table => {
        if (database[table] instanceof Map) {
          dataToSave[table] = Array.from(database[table].entries());
        }
      });

      // Save to data directory
      for (const [table, data] of Object.entries(dataToSave)) {
        const filePath = path.join(this.dataPath, `${table}.json`);
        await fs.writeFile(filePath, JSON.stringify(data, null, 2));
      }

      // Create backup
      await fs.writeFile(backupFile, JSON.stringify(dataToSave, null, 2));

      logger.debug('Database data saved successfully');
    } catch (error) {
      logger.error('Error saving database data:', error);
    }
  }

  async backup() {
    return this.saveData();
  }

  async restore(backupFile) {
    try {
      const data = await fs.readFile(backupFile, 'utf8');
      const parsed = JSON.parse(data);

      // Restore data to Maps
      Object.keys(parsed).forEach(table => {
        if (database[table]) {
          database[table] = new Map(parsed[table]);
        }
      });

      logger.info(`Database restored from ${backupFile}`);
    } catch (error) {
      logger.error('Error restoring database:', error);
      throw error;
    }
  }

  // Generic CRUD operations
  async create(table, data) {
    if (!database[table]) {
      throw new Error(`Table ${table} does not exist`);
    }

    const id = data.id || `mock_${table}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const record = {
      ...data,
      id,
      createdAt: data.createdAt || new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    database[table].set(id, record);
    
    if (this.autoSave) {
      this.saveData().catch(err => logger.error('Auto-save failed:', err));
    }

    return record;
  }

  async findById(table, id) {
    if (!database[table]) {
      throw new Error(`Table ${table} does not exist`);
    }

    return database[table].get(id);
  }

  async findOne(table, criteria) {
    if (!database[table]) {
      throw new Error(`Table ${table} does not exist`);
    }

    for (const [id, record] of database[table]) {
      if (this.matchesCriteria(record, criteria)) {
        return record;
      }
    }

    return null;
  }

  async findMany(table, criteria = {}, options = {}) {
    if (!database[table]) {
      throw new Error(`Table ${table} does not exist`);
    }

    const results = [];
    
    for (const [id, record] of database[table]) {
      if (this.matchesCriteria(record, criteria)) {
        results.push(record);
      }
    }

    // Apply sorting
    if (options.sort) {
      results.sort((a, b) => {
        const aVal = a[options.sort.field];
        const bVal = b[options.sort.field];
        
        if (options.sort.order === 'desc') {
          return bVal > aVal ? 1 : -1;
        }
        return aVal > bVal ? 1 : -1;
      });
    }

    // Apply pagination
    const total = results.length;
    let paginatedResults = results;

    if (options.pagination) {
      const { page = 1, limit = 20 } = options.pagination;
      const start = (page - 1) * limit;
      const end = start + limit;
      paginatedResults = results.slice(start, end);
    }

    return {
      data: paginatedResults,
      total,
      page: options.pagination?.page || 1,
      limit: options.pagination?.limit || 20,
      totalPages: Math.ceil(total / (options.pagination?.limit || 20))
    };
  }

  async update(table, id, updates) {
    if (!database[table]) {
      throw new Error(`Table ${table} does not exist`);
    }

    const existing = database[table].get(id);
    if (!existing) {
      return null;
    }

    const updated = {
      ...existing,
      ...updates,
      id,
      updatedAt: new Date().toISOString()
    };

    database[table].set(id, updated);

    if (this.autoSave) {
      this.saveData().catch(err => logger.error('Auto-save failed:', err));
    }

    return updated;
  }

  async delete(table, id) {
    if (!database[table]) {
      throw new Error(`Table ${table} does not exist`);
    }

    const deleted = database[table].delete(id);

    if (this.autoSave && deleted) {
      this.saveData().catch(err => logger.error('Auto-save failed:', err));
    }

    return deleted;
  }

  async count(table, criteria = {}) {
    if (!database[table]) {
      throw new Error(`Table ${table} does not exist`);
    }

    let count = 0;
    for (const [id, record] of database[table]) {
      if (this.matchesCriteria(record, criteria)) {
        count++;
      }
    }

    return count;
  }

  matchesCriteria(record, criteria) {
    return Object.entries(criteria).every(([key, value]) => {
      if (Array.isArray(value)) {
        return value.includes(record[key]);
      }
      if (typeof value === 'object' && value !== null) {
        if (value.$gte !== undefined && record[key] < value.$gte) return false;
        if (value.$lte !== undefined && record[key] > value.$lte) return false;
        if (value.$ne !== undefined && record[key] === value.$ne) return false;
        if (value.$in !== undefined && !value.$in.includes(record[key])) return false;
        return true;
      }
      return record[key] === value;
    });
  }

  // Clear all data
  async clear() {
    Object.keys(database).forEach(table => {
      database[table].clear();
    });
    
    logger.info('Database cleared');
  }

  // Get database statistics
  async getStats() {
    const stats = {};
    Object.keys(database).forEach(table => {
      stats[table] = database[table].size;
    });
    return stats;
  }
}

// Initialize database instance
const db = new MockDatabase();

// Generate initial mock data
async function generateInitialData() {
  try {
    // Check if data already exists
    const userCount = await db.count('users');
    
    if (userCount === 0) {
      logger.info('Generating initial mock data...');

      // Create sample users
      for (let i = 0; i < 10; i++) {
        const user = generateMockUser();
        await db.create('users', user);
      }

      // Create sample products (120+ items)
      const categories = ['tops', 'bottoms', 'dresses', 'outerwear', 'accessories', 'footwear', 'activewear'];
      for (let i = 0; i < 120; i++) {
        const category = categories[i % categories.length];
        const product = generateMockProduct(null, category);
        await db.create('products', product);
      }

      // Create sample carts
      const users = Array.from(db.users.values());
      for (const user of users) {
        const cart = generateMockCart(user.id);
        await db.create('carts', cart);
      }

      // Create sample orders
      const carts = Array.from(db.carts.values());
      for (let i = 0; i < 20; i++) {
        const cart = carts[i % carts.length];
        const order = generateMockOrder(cart.userId, cart);
        await db.create('orders', order);
      }

      // Create sample scan sessions
      for (const user of users) {
        const session = generateMockScanSession(user.id);
        await db.create('scanSessions', session);
      }

      // Create sample closet items
      for (const user of users) {
        const closet = generateMockCloset(user.id);
        await db.create('closetItems', closet);
      }

      logger.info('Initial mock data generated successfully');
    }
  } catch (error) {
    logger.error('Error generating initial data:', error);
  }
}

module.exports = {
  database,
  db,
  generateInitialData
};