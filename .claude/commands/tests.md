The `/test-gen` command automatically generates comprehensive test suites for your code with intelligent test case discovery and framework integration.

## Usage

```
/test-gen [options] <file_or_function>
```

## Options

### Test Types
- `--unit` - Generate unit tests (default)
- `--integration` - Generate integration tests
- `--e2e` - Generate end-to-end tests
- `--performance` - Generate performance tests
- `--security` - Generate security tests
- `--accessibility` - Generate accessibility tests

### Framework Selection
- `--jest` - Use Jest testing framework (JavaScript/TypeScript)
- `--vitest` - Use Vitest testing framework
- `--pytest` - Use pytest (Python)
- `--junit` - Use JUnit (Java)
- `--nunit` - Use NUnit (C#)
- `--rspec` - Use RSpec (Ruby)
- `--go-test` - Use Go testing package

### Coverage Options
- `--coverage` - Include code coverage configuration
- `--threshold=90` - Set coverage threshold percentage
- `--coverage-report` - Generate coverage reports

### Test Strategy
- `--tdd` - Test-driven development approach
- `--bdd` - Behavior-driven development with scenarios
- `--property-based` - Generate property-based tests
- `--mutation` - Include mutation testing setup

## Examples

### JavaScript/TypeScript Unit Tests

```javascript
// Source function
function calculateDiscount(price, discountPercentage, customerType) {
  if (price <= 0) throw new Error('Price must be positive');
  if (discountPercentage < 0 || discountPercentage > 100) {
    throw new Error('Discount must be between 0 and 100');
  }
  
  const baseDiscount = price * (discountPercentage / 100);
  const multiplier = customerType === 'premium' ? 1.2 : 1;
  
  return Math.min(baseDiscount * multiplier, price * 0.5);
}

// Generated Jest tests
describe('calculateDiscount', () => {
  describe('valid inputs', () => {
    test('should calculate basic discount correctly', () => {
      const result = calculateDiscount(100, 10, 'regular');
      expect(result).toBe(10);
    });
    
    test('should apply premium multiplier', () => {
      const result = calculateDiscount(100, 10, 'premium');
      expect(result).toBe(12);
    });
    
    test('should cap discount at 50% of price', () => {
      const result = calculateDiscount(100, 60, 'premium');
      expect(result).toBe(50);
    });
  });
  
  describe('edge cases', () => {
    test('should handle zero discount', () => {
      const result = calculateDiscount(100, 0, 'regular');
      expect(result).toBe(0);
    });
    
    test('should handle maximum discount', () => {
      const result = calculateDiscount(100, 100, 'regular');
      expect(result).toBe(50);
    });
  });
  
  describe('error cases', () => {
    test('should throw error for negative price', () => {
      expect(() => calculateDiscount(-10, 10, 'regular'))
        .toThrow('Price must be positive');
    });
    
    test('should throw error for invalid discount percentage', () => {
      expect(() => calculateDiscount(100, -5, 'regular'))
        .toThrow('Discount must be between 0 and 100');
      
      expect(() => calculateDiscount(100, 105, 'regular'))
        .toThrow('Discount must be between 0 and 100');
    });
  });
});
```

### Python Unit Tests

```python
# Source class
class UserValidator:
    def __init__(self, min_age=18):
        self.min_age = min_age
    
    def validate_user(self, user_data):
        errors = []
        
        if not user_data.get('email') or '@' not in user_data['email']:
            errors.append('Invalid email format')
        
        if user_data.get('age', 0) < self.min_age:
            errors.append(f'Age must be at least {self.min_age}')
        
        return len(errors) == 0, errors

# Generated pytest tests
import pytest
from user_validator import UserValidator

class TestUserValidator:
    @pytest.fixture
    def validator(self):
        return UserValidator()
    
    @pytest.fixture
    def custom_validator(self):
        return UserValidator(min_age=21)
    
    def test_valid_user(self, validator):
        user_data = {'email': 'test@example.com', 'age': 25}
        is_valid, errors = validator.validate_user(user_data)
        
        assert is_valid is True
        assert errors == []
    
    def test_invalid_email(self, validator):
        user_data = {'email': 'invalid-email', 'age': 25}
        is_valid, errors = validator.validate_user(user_data)
        
        assert is_valid is False
        assert 'Invalid email format' in errors
    
    def test_missing_email(self, validator):
        user_data = {'age': 25}
        is_valid, errors = validator.validate_user(user_data)
        
        assert is_valid is False
        assert 'Invalid email format' in errors
    
    def test_underage_user(self, validator):
        user_data = {'email': 'test@example.com', 'age': 16}
        is_valid, errors = validator.validate_user(user_data)
        
        assert is_valid is False
        assert 'Age must be at least 18' in errors
    
    def test_custom_min_age(self, custom_validator):
        user_data = {'email': 'test@example.com', 'age': 19}
        is_valid, errors = custom_validator.validate_user(user_data)
        
        assert is_valid is False
        assert 'Age must be at least 21' in errors
    
    @pytest.mark.parametrize('email,expected_valid', [
        ('user@domain.com', True),
        ('user.name@domain.co.uk', True),
        ('invalid-email', False),
        ('', False),
        ('user@', False),
        ('@domain.com', False),
    ])
    def test_email_validation_parametrized(self, validator, email, expected_valid):
        user_data = {'email': email, 'age': 25}
        is_valid, _ = validator.validate_user(user_data)
        
        assert (is_valid and 'Invalid email format' not in _) == expected_valid
```

### Integration Test Example

```javascript
// Generated API integration test
describe('User API Integration', () => {
  let app, server;
  
  beforeAll(async () => {
    app = require('../app');
    server = app.listen(0);
  });
  
  afterAll(async () => {
    await server.close();
  });
  
  beforeEach(async () => {
    await cleanupDatabase();
    await seedTestData();
  });
  
  describe('POST /api/users', () => {
    test('should create user successfully', async () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com',
        age: 30
      };
      
      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);
      
      expect(response.body).toMatchObject({
        id: expect.any(Number),
        name: userData.name,
        email: userData.email,
        age: userData.age,
        createdAt: expect.any(String)
      });
    });
    
    test('should validate user data', async () => {
      const invalidUserData = {
        name: '',
        email: 'invalid-email',
        age: -5
      };
      
      const response = await request(app)
        .post('/api/users')
        .send(invalidUserData)
        .expect(400);
      
      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ field: 'name' }),
          expect.objectContaining({ field: 'email' }),
          expect.objectContaining({ field: 'age' })
        ])
      );
    });
  });
});
```

## Test Configuration

### Jest Configuration
```javascript
// Generated jest.config.js
module.exports = {
  testEnvironment: 'node',
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  coverageThreshold: {
    global: {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    }
  },
  testMatch: [
    '**/__tests__/**/*.test.js',
    '**/?(*.)+(spec|test).js'
  ],
  setupFilesAfterEnv: ['<rootDir>/src/test/setup.js']
};
```

### Pytest Configuration
```ini
# Generated pytest.ini
[tool:pytest]
addopts = 
    --verbose
    --cov=src
    --cov-report=html
    --cov-report=term
    --cov-fail-under=90
    --strict-markers
testpaths = tests
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Slow tests
    security: Security tests
```

## Advanced Features

### Property-Based Testing
```javascript
// Generated property-based test
const fc = require('fast-check');

describe('calculateDiscount property tests', () => {
  test('discount should never exceed 50% of price', () => {
    fc.assert(fc.property(
      fc.float({ min: 0.01, max: 10000 }), // price
      fc.float({ min: 0, max: 100 }),      // discount percentage
      fc.constantFrom('regular', 'premium'), // customer type
      (price, discount, customerType) => {
        const result = calculateDiscount(price, discount, customerType);
        expect(result).toBeLessThanOrEqual(price * 0.5);
      }
    ));
  });
});
```

### Mock Generation
```javascript
// Generated mocks
const mockUserService = {
  getUserById: jest.fn(),
  createUser: jest.fn(),
  updateUser: jest.fn(),
  deleteUser: jest.fn()
};

const mockDatabase = {
  query: jest.fn(),
  transaction: jest.fn(),
  close: jest.fn()
};
```