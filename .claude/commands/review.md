The `/review` command provides comprehensive code analysis including security vulnerabilities, performance optimizations, code quality improvements, and adherence to best practices.

## Usage

```
/review [options] <file_or_directory>
```

## Options

### Review Types
- `--security` - Focus on security vulnerabilities and threats
- `--performance` - Analyze performance bottlenecks and optimizations
- `--style` - Check coding style and formatting
- `--architecture` - Review architectural patterns and design
- `--all` - Comprehensive review (default)

### Output Formats
- `--format=markdown` - Markdown report (default)
- `--format=json` - Machine-readable JSON output
- `--format=html` - Rich HTML report
- `--format=sarif` - SARIF format for CI/CD integration

### Severity Filtering
- `--severity=critical` - Only critical issues
- `--severity=high` - High and critical issues
- `--severity=medium` - Medium, high, and critical issues
- `--severity=all` - All issues including low severity

### Language-Specific Options
- `--eslint` - Use ESLint rules for JavaScript/TypeScript
- `--pylint` - Use Pylint for Python code
- `--rustfmt` - Use Rust formatting and clippy
- `--gofmt` - Use Go formatting and vet
- `--rubocop` - Use RuboCop for Ruby

## Examples

### Basic Code Review

```javascript
// Example file: user-service.js
class UserService {
  constructor() {
    this.users = [];
    this.database = new Database(process.env.DB_PASSWORD); // 🚨 Security Issue
  }
  
  async createUser(userData) {
    // 🚨 No input validation
    const user = {
      id: Math.random(), // 🚨 Poor ID generation
      ...userData,
      createdAt: new Date()
    };
    
    // 🚨 SQL injection vulnerability
    const query = `INSERT INTO users (name, email) VALUES ('${user.name}', '${user.email}')`;
    await this.database.query(query);
    
    this.users.push(user);
    return user;
  }
  
  // 🚨 No access control
  async deleteUser(userId) {
    const index = this.users.findIndex(u => u.id == userId); // 🚨 Type coercion
    if (index > -1) {
      this.users.splice(index, 1);
      return true;
    }
    return false;
  }
  
  // 🚨 Inefficient search
  async searchUsers(query) {
    return this.users.filter(user => 
      user.name.toLowerCase().includes(query.toLowerCase()) ||
      user.email.toLowerCase().includes(query.toLowerCase())
    );
  }
}
```

**Generated Review Report:**

```markdown
# Code Review Report: user-service.js

## 🚨 Critical Issues (4)

### 1. SQL Injection Vulnerability
**Location:** Line 15  
**Severity:** Critical  
**Category:** Security  

**Issue:** Direct string concatenation in SQL query allows SQL injection attacks.

```javascript
// ❌ Vulnerable code
const query = `INSERT INTO users (name, email) VALUES ('${user.name}', '${user.email}')`;

// ✅ Recommended fix
const query = 'INSERT INTO users (name, email) VALUES (?, ?)';
await this.database.query(query, [user.name, user.email]);
```

**Impact:** Attackers could execute arbitrary SQL commands, potentially accessing or deleting sensitive data.

### 2. Exposed Database Credentials
**Location:** Line 4  
**Severity:** Critical  
**Category:** Security  

**Issue:** Database password exposed in environment variable without proper encryption.

```javascript
// ❌ Vulnerable code
this.database = new Database(process.env.DB_PASSWORD);

// ✅ Recommended fix
const dbConfig = {
  host: process.env.DB_HOST,
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  ssl: true,
  connectionLimit: 10
};
this.database = new Database(dbConfig);
```

### 3. Missing Input Validation
**Location:** Line 7  
**Severity:** Critical  
**Category:** Security  

**Issue:** No validation of user input allows injection of malicious data.

```javascript
// ✅ Recommended implementation
const Joi = require('joi');

const userSchema = Joi.object({
  name: Joi.string().alphanum().min(2).max(50).required(),
  email: Joi.string().email().required(),
  age: Joi.number().integer().min(13).max(120)
});

async createUser(userData) {
  const { error, value } = userSchema.validate(userData);
  if (error) {
    throw new ValidationError('Invalid user data', error.details);
  }
  // Continue with validated data...
}
```

### 4. Weak ID Generation
**Location:** Line 9  
**Severity:** High  
**Category:** Security  

**Issue:** Math.random() is predictable and not suitable for ID generation.

```javascript
// ❌ Vulnerable code
id: Math.random()

// ✅ Recommended fix
const { v4: uuidv4 } = require('uuid');
id: uuidv4()

// Or for numeric IDs:
const crypto = require('crypto');
id: crypto.randomBytes(16).toString('hex')
```

## ⚠️ High Priority Issues (2)

### 5. Missing Access Control
**Location:** Line 25  
**Severity:** High  
**Category:** Security  

**Issue:** No authorization checks allow any user to delete any other user.

```javascript
// ✅ Recommended implementation
async deleteUser(userId, requestingUserId, userRole) {
  // Check if user can delete (self or admin)
  if (userId !== requestingUserId && userRole !== 'admin') {
    throw new AuthorizationError('Insufficient permissions');
  }
  
  // Additional checks...
}
```

### 6. Type Safety Issue
**Location:** Line 26  
**Severity:** High  
**Category:** Quality  

**Issue:** Using loose equality (==) instead of strict equality (===).

```javascript
// ❌ Problematic code
const index = this.users.findIndex(u => u.id == userId);

// ✅ Recommended fix
const index = this.users.findIndex(u => u.id === userId);
```

## 📊 Performance Issues (1)

### 7. Inefficient Search Algorithm
**Location:** Line 33  
**Severity:** Medium  
**Category:** Performance  

**Issue:** O(n) search operation doesn't scale with large user datasets.

```javascript
// ✅ Optimized implementation
class UserService {
  constructor() {
    this.users = [];
    this.userIndex = new Map(); // For fast lookups
    this.searchIndex = {}; // For text search
  }
  
  async searchUsers(query, limit = 20, offset = 0) {
    // Use database query for large datasets
    const sql = `
      SELECT * FROM users 
      WHERE MATCH(name, email) AGAINST (? IN NATURAL LANGUAGE MODE)
      LIMIT ? OFFSET ?
    `;
    return await this.database.query(sql, [query, limit, offset]);
  }
}
```

## 🏗️ Architecture Recommendations

### 1. Separation of Concerns
```javascript
// ✅ Improved architecture
class UserService {
  constructor(userRepository, validator, logger) {
    this.userRepository = userRepository;
    this.validator = validator;
    this.logger = logger;
  }
}

class UserRepository {
  constructor(database) {
    this.database = database;
  }
  
  async create(userData) {
    const query = 'INSERT INTO users (id, name, email, created_at) VALUES (?, ?, ?, ?)';
    return await this.database.query(query, [
      userData.id,
      userData.name,
      userData.email,
      userData.createdAt
    ]);
  }
}
```

### 2. Error Handling
```javascript
// ✅ Proper error handling
class UserService {
  async createUser(userData) {
    try {
      await this.validator.validate(userData);
      const user = await this.userRepository.create(userData);
      this.logger.info('User created successfully', { userId: user.id });
      return user;
    } catch (error) {
      this.logger.error('Failed to create user', { error: error.message, userData });
      
      if (error instanceof ValidationError) {
        throw new BadRequestError('Invalid user data', error.details);
      }
      
      throw new InternalServerError('Failed to create user');
    }
  }
}
```

## 🧪 Testing Recommendations

```javascript
// ✅ Comprehensive test suite
describe('UserService', () => {
  let userService, mockRepository, mockValidator;
  
  beforeEach(() => {
    mockRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      delete: jest.fn()
    };
    mockValidator = {
      validate: jest.fn()
    };
    userService = new UserService(mockRepository, mockValidator);
  });
  
  describe('createUser', () => {
    it('should create user with valid data', async () => {
      const userData = { name: 'John Doe', email: 'john@example.com' };
      mockValidator.validate.mockResolvedValue(userData);
      mockRepository.create.mockResolvedValue({ id: '123', ...userData });
      
      const result = await userService.createUser(userData);
      
      expect(result.id).toBe('123');
      expect(mockRepository.create).toHaveBeenCalledWith(userData);
    });
    
    it('should throw error for invalid data', async () => {
      mockValidator.validate.mockRejectedValue(new ValidationError('Invalid email'));
      
      await expect(userService.createUser({ email: 'invalid' }))
        .rejects.toThrow(BadRequestError);
    });
    
    it('should handle SQL injection attempts', async () => {
      const maliciousData = {
        name: "'; DROP TABLE users; --",
        email: 'test@example.com'
      };
      
      // Should be caught by validation
      mockValidator.validate.mockRejectedValue(new ValidationError('Invalid characters'));
      
      await expect(userService.createUser(maliciousData))
        .rejects.toThrow(BadRequestError);
    });
  });
});
```

## 📋 Security Checklist

- [ ] **Input Validation**: Implement comprehensive input validation
- [ ] **SQL Injection**: Use parameterized queries
- [ ] **Authentication**: Add proper user authentication
- [ ] **Authorization**: Implement role-based access control
- [ ] **Encryption**: Encrypt sensitive data at rest and in transit
- [ ] **Logging**: Add security event logging
- [ ] **Rate Limiting**: Implement API rate limiting
- [ ] **CORS**: Configure CORS policies appropriately
- [ ] **Headers**: Set security headers (HSTS, CSP, etc.)
- [ ] **Dependencies**: Audit and update dependencies regularly

## 📈 Performance Optimizations

1. **Database Indexing**
   ```sql
   CREATE INDEX idx_users_email ON users(email);
   CREATE INDEX idx_users_name ON users(name);
   CREATE FULLTEXT INDEX idx_users_search ON users(name, email);
   ```

2. **Caching Strategy**
   ```javascript
   const cache = new Redis();
   
   async getUser(id) {
     const cached = await cache.get(`user:${id}`);
     if (cached) return JSON.parse(cached);
     
     const user = await this.userRepository.findById(id);
     await cache.setex(`user:${id}`, 3600, JSON.stringify(user));
     return user;
   }
   ```

3. **Connection Pooling**
   ```javascript
   const pool = new Pool({
     host: 'localhost',
     user: 'user',
     password: 'password',
     database: 'myapp',
     connectionLimit: 10,
     acquireTimeout: 60000,
     timeout: 60000
   });
   ```

## 🔧 Configuration

```javascript
// ✅ Environment-based configuration
const config = {
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.NODE_ENV === 'production',
    pool: {
      min: 2,
      max: 10,
      acquire: 30000,
      idle: 10000
    }
  },
  security: {
    jwtSecret: process.env.JWT_SECRET,
    bcryptRounds: 12,
    rateLimitWindowMs: 15 * 60 * 1000, // 15 minutes
    rateLimitMax: 100 // requests per window
  },
  validation: {
    nameMinLength: 2,
    nameMaxLength: 50,
    passwordMinLength: 8,
    emailDomainWhitelist: process.env.ALLOWED_EMAIL_DOMAINS?.split(',')
  }
};
```

## Summary

**Issues Found:** 7  
**Critical:** 4  
**High:** 2  
**Medium:** 1  

**Primary Concerns:**
1. Critical security vulnerabilities (SQL injection, exposed credentials)
2. Missing input validation and access controls
3. Poor error handling and logging
4. Performance bottlenecks in search functionality

**Recommended Actions:**
1. **Immediate:** Fix SQL injection and input validation (Critical)
2. **High Priority:** Implement access controls and proper ID generation
3. **Medium Priority:** Optimize search performance and add comprehensive testing
4. **Long Term:** Refactor architecture for better separation of concerns

**Estimated Effort:** 2-3 days for critical fixes, 1-2 weeks for complete refactoring
```

## Advanced Analysis Features

### Machine Learning Insights
- **Code Smell Detection**: Identify potential design issues
- **Bug Prediction**: Predict likely bug locations based on complexity
- **Refactoring Suggestions**: AI-powered code improvement recommendations
- **Security Pattern Recognition**: Detect known vulnerability patterns

### Integration Capabilities
- **CI/CD Pipeline**: Integrate with GitHub Actions, Jenkins, GitLab CI
- **IDE Extensions**: Support for VS Code, IntelliJ, Vim
- **Code Quality Gates**: Block deployments on critical issues
- **Team Collaboration**: Share reviews and track improvements

### Custom Rule Sets
```yaml
# .claudereview.yml
rules:
  security:
    - no-sql-injection
    - require-input-validation
    - no-hardcoded-secrets
    - require-https
  
  performance:
    - no-n-plus-one-queries
    - require-database-indexes
    - limit-memory-usage
  
  style:
    - consistent-naming
    - max-function-length: 50
    - max-file-length: 500
    - require-documentation

ignore:
  - "*.test.js"
  - "node_modules/**"
  - "dist/**"

thresholds:
  critical: 0
  high: 5
  medium: 20
```