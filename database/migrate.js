const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

function runMigration(dbPath = ':memory:') {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        reject(err);
        return;
      }
    });

    const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');

    db.exec(schema, (err) => {
      if (err) {
        db.close();
        reject(err);
        return;
      }

      console.log('Database migration completed successfully');

      // For in-memory databases, return the db connection
      // For file-based databases, close the connection
      if (dbPath === ':memory:') {
        resolve(db);
      } else {
        db.close((closeErr) => {
          if (closeErr) {
            reject(closeErr);
          } else {
            resolve();
          }
        });
      }
    });
  });
}

module.exports = { runMigration };

// Run migration if called directly
if (require.main === module) {
  const dbPath = process.argv[2] || './database/users.db';
  runMigration(dbPath)
    .then(() => process.exit(0))
    .catch(err => {
      console.error('Migration failed:', err);
      process.exit(1);
    });
}
