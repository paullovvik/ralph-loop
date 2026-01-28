const User = require('../models/User');
const { runMigration } = require('../database/migrate');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

describe('User Model', () => {
  describe('User Class Validation', () => {
    test('should create a user with valid data', () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com',
        bio: 'Software developer'
      };
      const user = new User(userData);
      expect(user.name).toBe('John Doe');
      expect(user.email).toBe('john@example.com');
      expect(user.bio).toBe('Software developer');
    });

    test('should validate correct email format', () => {
      const user = new User({
        name: 'John Doe',
        email: 'john@example.com'
      });
      expect(user.validateEmail()).toBe(true);
    });

    test('should reject invalid email format - missing @', () => {
      const user = new User({
        name: 'John Doe',
        email: 'johnexample.com'
      });
      expect(user.validateEmail()).toBe(false);
    });

    test('should reject invalid email format - missing domain', () => {
      const user = new User({
        name: 'John Doe',
        email: 'john@'
      });
      expect(user.validateEmail()).toBe(false);
    });

    test('should reject invalid email format - missing local part', () => {
      const user = new User({
        name: 'John Doe',
        email: '@example.com'
      });
      expect(user.validateEmail()).toBe(false);
    });

    test('should accept bio with 500 characters', () => {
      const bio = 'a'.repeat(500);
      const user = new User({
        name: 'John Doe',
        email: 'john@example.com',
        bio: bio
      });
      expect(user.validateBio()).toBe(true);
    });

    test('should reject bio exceeding 500 characters', () => {
      const bio = 'a'.repeat(501);
      const user = new User({
        name: 'John Doe',
        email: 'john@example.com',
        bio: bio
      });
      expect(user.validateBio()).toBe(false);
    });

    test('should accept null or undefined bio', () => {
      const user1 = new User({
        name: 'John Doe',
        email: 'john@example.com',
        bio: null
      });
      const user2 = new User({
        name: 'Jane Doe',
        email: 'jane@example.com'
      });
      expect(user1.validateBio()).toBe(true);
      expect(user2.validateBio()).toBe(true);
    });

    test('should validate all fields correctly', () => {
      const user = new User({
        name: 'John Doe',
        email: 'john@example.com',
        bio: 'Valid bio'
      });
      const validation = user.validate();
      expect(validation.isValid).toBe(true);
      expect(validation.errors).toHaveLength(0);
    });

    test('should return errors for invalid data', () => {
      const user = new User({
        name: '',
        email: 'invalid-email',
        bio: 'a'.repeat(501)
      });
      const validation = user.validate();
      expect(validation.isValid).toBe(false);
      expect(validation.errors).toContain('Name is required');
      expect(validation.errors).toContain('Invalid email format');
      expect(validation.errors).toContain('Bio must not exceed 500 characters');
    });

    test('should set default timestamps', () => {
      const user = new User({
        name: 'John Doe',
        email: 'john@example.com'
      });
      expect(user.created_at).toBeDefined();
      expect(user.updated_at).toBeDefined();
    });

    test('should convert to JSON', () => {
      const user = new User({
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        bio: 'Developer'
      });
      const json = user.toJSON();
      expect(json).toHaveProperty('id');
      expect(json).toHaveProperty('name');
      expect(json).toHaveProperty('email');
      expect(json).toHaveProperty('bio');
      expect(json).toHaveProperty('created_at');
      expect(json).toHaveProperty('updated_at');
    });
  });

  describe('Database Migration', () => {
    let db;
    const testDbPath = ':memory:';

    afterEach((done) => {
      if (db) {
        db.close(done);
      } else {
        done();
      }
    });

    test('should create users table successfully', async () => {
      db = await runMigration(testDbPath);

      return new Promise((resolve, reject) => {
        db.get(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'",
          (err, row) => {
            if (err) {
              reject(err);
            } else {
              expect(row).toBeDefined();
              expect(row.name).toBe('users');
              resolve();
            }
          }
        );
      });
    });

    test('should have correct table schema', async () => {
      db = await runMigration(testDbPath);

      return new Promise((resolve, reject) => {
        db.all("PRAGMA table_info(users)", (err, columns) => {
          if (err) {
            reject(err);
          } else {
            const columnNames = columns.map(col => col.name);
            expect(columnNames).toContain('id');
            expect(columnNames).toContain('name');
            expect(columnNames).toContain('email');
            expect(columnNames).toContain('bio');
            expect(columnNames).toContain('avatar_url');
            expect(columnNames).toContain('created_at');
            expect(columnNames).toContain('updated_at');
            resolve();
          }
        });
      });
    });

    test('should enforce bio length constraint', async () => {
      db = await runMigration(testDbPath);

      const longBio = 'a'.repeat(501);

      return new Promise((resolve, reject) => {
        db.run(
          "INSERT INTO users (name, email, bio) VALUES (?, ?, ?)",
          ['John Doe', 'john@example.com', longBio],
          (err) => {
            if (err) {
              expect(err).toBeDefined();
              expect(err.message).toContain('CHECK constraint failed');
              resolve();
            } else {
              reject(new Error('Expected INSERT to fail with CHECK constraint, but it succeeded'));
            }
          }
        );
      });
    });
  });
});
