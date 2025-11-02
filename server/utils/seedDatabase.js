const { db, generateInitialData } = require('./database');
const logger = require('./logger');

/**
 * Database seeding script
 * Populates the mock database with initial data for development/testing
 */

async function seedDatabase() {
  try {
    logger.info('Starting database seeding...');

    // Initialize database
    await db.initialize();

    // Generate initial data
    await generateInitialData();

    // Additional seeding operations can be added here
    logger.info('Database seeding completed successfully');
    
    // Display statistics
    const stats = await db.getStats();
    logger.info('Database statistics:', stats);

    process.exit(0);
  } catch (error) {
    logger.error('Database seeding failed:', error);
    process.exit(1);
  }
}

// Run seeding if this file is executed directly
if (require.main === module) {
  seedDatabase();
}

module.exports = {
  seedDatabase
};