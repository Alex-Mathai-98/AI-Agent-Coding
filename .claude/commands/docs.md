The `/docs` command automatically generates comprehensive documentation including API specifications, code examples, tutorials, user guides, and interactive documentation with live examples.

## Usage

```
/docs [options] <file_or_project>
```

## Options

### Documentation Types
- `--api` - Generate API documentation (OpenAPI/Swagger)
- `--code` - Code documentation with JSDoc/docstrings
- `--user` - User guides and tutorials
- `--developer` - Developer documentation and architecture
- `--readme` - Project README and getting started guide
- `--all` - Comprehensive documentation suite (default)

### Output Formats
- `--format=markdown` - Markdown documentation (default)
- `--format=html` - Static HTML documentation
- `--format=interactive` - Interactive documentation with examples
- `--format=pdf` - PDF documentation for distribution
- `--format=confluence` - Confluence wiki format

### Documentation Features
- `--examples` - Include runnable code examples
- `--tutorials` - Generate step-by-step tutorials
- `--diagrams` - Generate architecture and flow diagrams
- `--interactive` - Create interactive API explorer
- `--multilingual` - Generate documentation in multiple languages

### Customization
- `--template=default` - Use default documentation template
- `--template=minimal` - Minimal documentation template
- `--template=enterprise` - Enterprise documentation template
- `--brand=company` - Apply company branding and styling

## Examples

### API Documentation Generation

```javascript
// Express.js API with comprehensive documentation
const express = require('express');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const app = express();

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - name
 *         - email
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique identifier for the user
 *           example: "123e4567-e89b-12d3-a456-426614174000"
 *         name:
 *           type: string
 *           minLength: 2
 *           maxLength: 100
 *           description: User's full name
 *           example: "John Doe"
 *         email:
 *           type: string
 *           format: email
 *           description: User's email address
 *           example: "john.doe@example.com"
 *         age:
 *           type: integer
 *           minimum: 13
 *           maximum: 120
 *           description: User's age in years
 *           example: 30
 *         role:
 *           type: string
 *           enum: [user, admin, moderator]
 *           description: User's role in the system
 *           example: "user"
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: User creation timestamp
 *           example: "2025-09-16T10:30:00Z"
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: Last update timestamp
 *           example: "2025-09-16T14:45:00Z"
 *       example:
 *         id: "123e4567-e89b-12d3-a456-426614174000"
 *         name: "John Doe"
 *         email: "john.doe@example.com"
 *         age: 30
 *         role: "user"
 *         createdAt: "2025-09-16T10:30:00Z"
 *         updatedAt: "2025-09-16T14:45:00Z"
 *   
 *     UserInput:
 *       type: object
 *       required:
 *         - name
 *         - email
 *       properties:
 *         name:
 *           type: string
 *           minLength: 2
 *           maxLength: 100
 *           description: User's full name
 *         email:
 *           type: string
 *           format: email
 *           description: User's email address
 *         age:
 *           type: integer
 *           minimum: 13
 *           maximum: 120
 *           description: User's age in years
 *   
 *     Error:
 *       type: object
 *       properties:
 *         error:
 *           type: string
 *           description: Error message
 *         code:
 *           type: string
 *           description: Error code
 *         details:
 *           type: object
 *           description: Additional error details
 *       example:
 *         error: "Validation failed"
 *         code: "VALIDATION_ERROR"
 *         details:
 *           field: "email"
 *           message: "Invalid email format"
 *   
 *   responses:
 *     NotFound:
 *       description: Resource not found
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Error'
 *           example:
 *             error: "User not found"
 *             code: "USER_NOT_FOUND"
 *     ValidationError:
 *       description: Validation error
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Error'
 *     ServerError:
 *       description: Internal server error
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Error'
 *   
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 */

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Get all users
 *     description: |
 *       Retrieve a paginated list of all users in the system.
 *       
 *       ## Features
 *       - Pagination support with configurable page size
 *       - Filtering by role, status, and creation date
 *       - Sorting by multiple fields
 *       - Search functionality across name and email
 *       
 *       ## Usage Examples
 *       
 *       ### Basic usage
 *       ```
 *       GET /api/users
 *       ```
 *       
 *       ### With pagination
 *       ```
 *       GET /api/users?page=2&limit=20
 *       ```
 *       
 *       ### With filtering
 *       ```
 *       GET /api/users?role=admin&status=active
 *       ```
 *       
 *       ### With search
 *       ```
 *       GET /api/users?search=john&sort=name:asc
 *       ```
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number for pagination
 *         example: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 20
 *         description: Number of users per page
 *         example: 20
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *           maxLength: 100
 *         description: Search term for name or email
 *         example: "john"
 *       - in: query
 *         name: role
 *         schema:
 *           type: string
 *           enum: [user, admin, moderator]
 *         description: Filter by user role
 *         example: "user"
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, inactive, suspended]
 *         description: Filter by user status
 *         example: "active"
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *           pattern: '^(name|email|createdAt|updatedAt):(asc|desc)$'
 *         description: Sort field and direction
 *         example: "name:asc"
 *     responses:
 *       200:
 *         description: List of users retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 users:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                       example: 1
 *                     limit:
 *                       type: integer
 *                       example: 20
 *                     total:
 *                       type: integer
 *                       example: 150
 *                     totalPages:
 *                       type: integer
 *                       example: 8
 *                     hasNext:
 *                       type: boolean
 *                       example: true
 *                     hasPrev:
 *                       type: boolean
 *                       example: false
 *             examples:
 *               success:
 *                 summary: Successful response
 *                 value:
 *                   users:
 *                     - id: "123e4567-e89b-12d3-a456-426614174000"
 *                       name: "John Doe"
 *                       email: "john.doe@example.com"
 *                       age: 30
 *                       role: "user"
 *                       createdAt: "2025-09-16T10:30:00Z"
 *                       updatedAt: "2025-09-16T14:45:00Z"
 *                     - id: "456e7890-e89b-12d3-a456-426614174001"
 *                       name: "Jane Smith"
 *                       email: "jane.smith@example.com"
 *                       age: 28
 *                       role: "admin"
 *                       createdAt: "2025-09-15T09:15:00Z"
 *                       updatedAt: "2025-09-16T11:20:00Z"
 *                   pagination:
 *                     page: 1
 *                     limit: 20
 *                     total: 150
 *                     totalPages: 8
 *                     hasNext: true
 *                     hasPrev: false
 *       401:
 *         description: Unauthorized - Invalid or missing authentication token
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Authentication required"
 *               code: "UNAUTHORIZED"
 *       403:
 *         description: Forbidden - Insufficient permissions
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Insufficient permissions"
 *               code: "FORBIDDEN"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 *   
 *   post:
 *     summary: Create a new user
 *     description: |
 *       Create a new user account in the system.
 *       
 *       ## Validation Rules
 *       - Name must be 2-100 characters long
 *       - Email must be unique and valid format
 *       - Age must be between 13-120 (if provided)
 *       - Password must meet complexity requirements
 *       
 *       ## Business Logic
 *       - New users are created with 'user' role by default
 *       - Email verification is sent upon creation
 *       - Account is initially inactive until email verification
 *       
 *       ## Rate Limiting
 *       - Maximum 5 user creations per hour per IP
 *       - Additional restrictions for automated requests
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UserInput'
 *           examples:
 *             basic:
 *               summary: Basic user creation
 *               value:
 *                 name: "Alice Johnson"
 *                 email: "alice.johnson@example.com"
 *                 age: 25
 *             minimal:
 *               summary: Minimal required fields
 *               value:
 *                 name: "Bob Wilson"
 *                 email: "bob.wilson@example.com"
 *     responses:
 *       201:
 *         description: User created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *                 message:
 *                   type: string
 *                   example: "User created successfully"
 *             example:
 *               user:
 *                 id: "789e0123-e89b-12d3-a456-426614174002"
 *                 name: "Alice Johnson"
 *                 email: "alice.johnson@example.com"
 *                 age: 25
 *                 role: "user"
 *                 createdAt: "2025-09-16T15:30:00Z"
 *                 updatedAt: "2025-09-16T15:30:00Z"
 *               message: "User created successfully"
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       409:
 *         description: Conflict - Email already exists
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Email already exists"
 *               code: "EMAIL_EXISTS"
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
app.get('/api/users', async (req, res) => {
  // Implementation here...
});

app.post('/api/users', async (req, res) => {
  // Implementation here...
});

/**
 * @swagger
 * /api/users/{id}:
 *   get:
 *     summary: Get user by ID
 *     description: |
 *       Retrieve a specific user by their unique identifier.
 *       
 *       ## Access Control
 *       - Users can only access their own profile
 *       - Admins can access any user profile
 *       - Moderators can access non-admin user profiles
 *       
 *       ## Data Privacy
 *       - Sensitive fields are filtered based on access level
 *       - Full profile data only available to user themselves or admins
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *         example: "123e4567-e89b-12d3-a456-426614174000"
 *     responses:
 *       200:
 *         description: User found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       403:
 *         description: Forbidden - Cannot access this user
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *   
 *   put:
 *     summary: Update user
 *     description: |
 *       Update an existing user's information.
 *       
 *       ## Update Rules
 *       - Users can only update their own profile
 *       - Admins can update any user profile
 *       - Email changes require verification
 *       - Role changes restricted to admins
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UserInput'
 *     responses:
 *       200:
 *         description: User updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       403:
 *         description: Forbidden
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *   
 *   delete:
 *     summary: Delete user
 *     description: |
 *       Delete a user account from the system.
 *       
 *       ## Deletion Policy
 *       - Soft delete by default (marks as inactive)
 *       - Hard delete requires admin privileges and confirmation
 *       - Associated data is anonymized or removed
 *       - Action is irreversible and logged for audit
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *       - in: query
 *         name: hard
 *         schema:
 *           type: boolean
 *           default: false
 *         description: Perform hard delete (admin only)
 *     responses:
 *       200:
 *         description: User deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "User deleted successfully"
 *                 deletedAt:
 *                   type: string
 *                   format: date-time
 *                   example: "2025-09-16T16:00:00Z"
 *       404:
 *         $ref: '#/components/responses/NotFound'
 *       403:
 *         description: Forbidden
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
app.get('/api/users/:id', async (req, res) => {
  // Implementation here...
});

app.put('/api/users/:id', async (req, res) => {
  // Implementation here...
});

app.delete('/api/users/:id', async (req, res) => {
  // Implementation here...
});
```

**Generated API Documentation:**

```markdown
# User Management API Documentation

## Overview

The User Management API provides comprehensive functionality for managing user accounts, authentication, and user-related operations. This RESTful API follows OpenAPI 3.0 specifications and includes robust error handling, validation, and security features.

### Base URL
```
https://api.example.com/v1
```

### Authentication
All API endpoints require authentication using JWT Bearer tokens:

```bash
Authorization: Bearer <your-jwt-token>
```

### Rate Limiting
- **Standard endpoints**: 100 requests per 15 minutes
- **Authentication endpoints**: 5 requests per 15 minutes
- **User creation**: 5 requests per hour

### Response Format
All responses are in JSON format with consistent error handling:

```json
{
  "data": {},
  "message": "Success",
  "timestamp": "2025-09-16T10:30:00Z"
}
```

## Quick Start

### 1. Authentication
First, obtain an authentication token:

```bash
curl -X POST https://api.example.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "your-password"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600,
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "John Doe",
    "email": "user@example.com",
    "role": "user"
  }
}
```

### 2. Get All Users
Retrieve a list of users with pagination:

```bash
curl -X GET "https://api.example.com/v1/api/users?page=1&limit=20" \
  -H "Authorization: Bearer <your-token>"
```

### 3. Create a New User
```bash
curl -X POST https://api.example.com/v1/api/users \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "age": 25
  }'
```

### 4. Update User Information
```bash
curl -X PUT https://api.example.com/v1/api/users/123e4567-e89b-12d3-a456-426614174000 \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson-Smith",
    "age": 26
  }'
```

## Code Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

class UserAPIClient {
  constructor(baseURL, token) {
    this.client = axios.create({
      baseURL,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
  }
  
  async getUsers(params = {}) {
    try {
      const response = await this.client.get('/api/users', { params });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }
  
  async createUser(userData) {
    try {
      const response = await this.client.post('/api/users', userData);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }
  
  async getUserById(id) {
    try {
      const response = await this.client.get(`/api/users/${id}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }
  
  handleError(error) {
    if (error.response) {
      // Server responded with error status
      const { status, data } = error.response;
      return new Error(`API Error ${status}: ${data.error || data.message}`);
    } else if (error.request) {
      // Network error
      return new Error('Network error: Unable to reach API');
    } else {
      // Other error
      return new Error(`Request error: ${error.message}`);
    }
  }
}

// Usage example
const userAPI = new UserAPIClient('https://api.example.com/v1', 'your-jwt-token');

// Get paginated users
const users = await userAPI.getUsers({ page: 1, limit: 20, role: 'user' });
console.log('Users:', users);

// Create new user
const newUser = await userAPI.createUser({
  name: 'Bob Wilson',
  email: 'bob@example.com',
  age: 30
});
console.log('Created user:', newUser);
```

### Python

```python
import requests
import json
from typing import Dict, List, Optional

class UserAPIClient:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        })
    
    def get_users(self, page: int = 1, limit: int = 20, **filters) -> Dict:
        """Get paginated list of users with optional filters."""
        params = {'page': page, 'limit': limit, **filters}
        response = self.session.get(f'{self.base_url}/api/users', params=params)
        response.raise_for_status()
        return response.json()
    
    def create_user(self, user_data: Dict) -> Dict:
        """Create a new user."""
        response = self.session.post(
            f'{self.base_url}/api/users',
            json=user_data
        )
        response.raise_for_status()
        return response.json()
    
    def get_user_by_id(self, user_id: str) -> Dict:
        """Get user by ID."""
        response = self.session.get(f'{self.base_url}/api/users/{user_id}')
        response.raise_for_status()
        return response.json()
    
    def update_user(self, user_id: str, updates: Dict) -> Dict:
        """Update user information."""
        response = self.session.put(
            f'{self.base_url}/api/users/{user_id}',
            json=updates
        )
        response.raise_for_status()
        return response.json()
    
    def delete_user(self, user_id: str, hard_delete: bool = False) -> Dict:
        """Delete user (soft delete by default)."""
        params = {'hard': hard_delete} if hard_delete else {}
        response = self.session.delete(
            f'{self.base_url}/api/users/{user_id}',
            params=params
        )
        response.raise_for_status()
        return response.json()

# Usage example
user_api = UserAPIClient('https://api.example.com/v1', 'your-jwt-token')

# Get users with filters
users = user_api.get_users(page=1, limit=10, role='admin', status='active')
print(f"Found {users['pagination']['total']} users")

# Create user
new_user = user_api.create_user({
    'name': 'Carol Davis',
    'email': 'carol@example.com',
    'age': 28
})
print(f"Created user: {new_user['user']['id']}")
```

### curl Examples

```bash
#!/bin/bash

# Set base URL and token
BASE_URL="https://api.example.com/v1"
TOKEN="your-jwt-token"

# Get all users with pagination
echo "Getting users..."
curl -s -X GET "$BASE_URL/api/users?page=1&limit=5" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.users[] | {id, name, email, role}'

# Create a new user
echo "Creating user..."
NEW_USER=$(curl -s -X POST "$BASE_URL/api/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "David Miller",
    "email": "david@example.com",
    "age": 35
  }')

USER_ID=$(echo $NEW_USER | jq -r '.user.id')
echo "Created user with ID: $USER_ID"

# Get the created user
echo "Getting created user..."
curl -s -X GET "$BASE_URL/api/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '{id, name, email, createdAt}'

# Update the user
echo "Updating user..."
curl -s -X PUT "$BASE_URL/api/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "David Miller Jr.",
    "age": 36
  }' \
  | jq '{id, name, age, updatedAt}'

# Search users
echo "Searching users..."
curl -s -X GET "$BASE_URL/api/users?search=david&sort=name:asc" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.users[] | {name, email}'
```

## Error Handling

### Error Response Format
All errors follow a consistent format:

```json
{
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_ERROR_CODE",
  "details": {
    "field": "Additional context",
    "value": "Problematic value"
  },
  "timestamp": "2025-09-16T10:30:00Z",
  "requestId": "req_123456789"
}
```

### Common Error Codes

| Status Code | Error Code | Description | Action |
|-------------|------------|-------------|--------|
| 400 | `VALIDATION_ERROR` | Request validation failed | Check request format and required fields |
| 401 | `UNAUTHORIZED` | Authentication required | Provide valid JWT token |
| 403 | `FORBIDDEN` | Insufficient permissions | Check user role and permissions |
| 404 | `USER_NOT_FOUND` | User does not exist | Verify user ID |
| 409 | `EMAIL_EXISTS` | Email already registered | Use different email address |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests | Wait before retrying |
| 500 | `INTERNAL_ERROR` | Server error | Contact support if persistent |

### Error Handling Best Practices

```javascript
// Comprehensive error handling example
async function handleUserOperation(apiCall) {
  try {
    const result = await apiCall();
    return { success: true, data: result };
  } catch (error) {
    const errorInfo = {
      success: false,
      error: error.message,
      code: error.code,
      timestamp: new Date().toISOString()
    };
    
    // Log error for debugging
    console.error('API Error:', errorInfo);
    
    // Handle specific error types
    switch (error.response?.status) {
      case 400:
        return { ...errorInfo, userMessage: 'Please check your input and try again.' };
      case 401:
        return { ...errorInfo, userMessage: 'Please log in again.', requiresAuth: true };
      case 403:
        return { ...errorInfo, userMessage: 'You don\'t have permission for this action.' };
      case 404:
        return { ...errorInfo, userMessage: 'The requested user was not found.' };
      case 409:
        return { ...errorInfo, userMessage: 'This email is already registered.' };
      case 429:
        return { ...errorInfo, userMessage: 'Too many requests. Please try again later.', retryAfter: 60 };
      case 500:
        return { ...errorInfo, userMessage: 'Server error. Please try again or contact support.' };
      default:
        return { ...errorInfo, userMessage: 'An unexpected error occurred.' };
    }
  }
}

// Usage
const result = await handleUserOperation(() => userAPI.createUser(userData));
if (result.success) {
  console.log('User created:', result.data);
} else {
  showErrorMessage(result.userMessage);
  if (result.requiresAuth) {
    redirectToLogin();
  }
}
```

## SDKs and Libraries

### Official SDKs
- **JavaScript/TypeScript**: `npm install @example/user-api-client`
- **Python**: `pip install example-user-api`
- **Go**: `go get github.com/example/user-api-go`
- **PHP**: `composer require example/user-api-php`

### Community Libraries
- **Ruby**: [user-api-ruby](https://github.com/community/user-api-ruby)
- **Java**: [user-api-java](https://github.com/community/user-api-java)
- **C#**: [UserApi.NET](https://github.com/community/user-api-dotnet)

## Testing

### Postman Collection
Download our [Postman collection](https://api.example.com/postman/user-api.json) with pre-configured requests and environment variables.

### Test Data
Use our test environment with sample data:
- **Base URL**: `https://api-test.example.com/v1`
- **Test Token**: Contact support for test credentials

### Example Test Cases

```javascript
// Jest test examples
describe('User API', () => {
  let userAPI;
  let testUserId;
  
  beforeAll(() => {
    userAPI = new UserAPIClient(
      process.env.TEST_API_URL,
      process.env.TEST_API_TOKEN
    );
  });
  
  test('should create a new user', async () => {
    const userData = {
      name: 'Test User',
      email: `test-${Date.now()}@example.com`,
      age: 25
    };
    
    const result = await userAPI.createUser(userData);
    
    expect(result.user).toMatchObject({
      name: userData.name,
      email: userData.email,
      age: userData.age,
      role: 'user'
    });
    expect(result.user.id).toBeDefined();
    
    testUserId = result.user.id;
  });
  
  test('should get user by ID', async () => {
    const user = await userAPI.getUserById(testUserId);
    
    expect(user.id).toBe(testUserId);
    expect(user.name).toBe('Test User');
  });
  
  test('should update user information', async () => {
    const updates = { name: 'Updated Test User', age: 26 };
    const updatedUser = await userAPI.updateUser(testUserId, updates);
    
    expect(updatedUser.name).toBe(updates.name);
    expect(updatedUser.age).toBe(updates.age);
  });
  
  test('should handle validation errors', async () => {
    const invalidData = { name: '', email: 'invalid-email' };
    
    await expect(userAPI.createUser(invalidData))
      .rejects.toThrow(/validation/i);
  });
  
  afterAll(async () => {
    if (testUserId) {
      await userAPI.deleteUser(testUserId, true); // Hard delete test user
    }
  });
});
```

## Support and Resources

### Documentation
- **API Reference**: [https://docs.example.com/api](https://docs.example.com/api)
- **Interactive API Explorer**: [https://api.example.com/docs](https://api.example.com/docs)
- **Changelog**: [https://docs.example.com/changelog](https://docs.example.com/changelog)

### Support Channels
- **Developer Support**: [dev-support@example.com](mailto:dev-support@example.com)
- **Stack Overflow**: Tag questions with `example-api`
- **Discord Community**: [https://discord.gg/example-dev](https://discord.gg/example-dev)
- **GitHub Issues**: [https://github.com/example/api-issues](https://github.com/example/api-issues)

### Status and Monitoring
- **API Status**: [https://status.example.com](https://status.example.com)
- **Performance Metrics**: [https://metrics.example.com](https://metrics.example.com)
- **Incident Reports**: [https://incidents.example.com](https://incidents.example.com)

---

*Last updated: September 16, 2025*  
*API Version: 1.2.0*  
*Documentation Version: 2.1.0*
```

## Advanced Documentation Features

### Interactive Code Examples
- **Try It Now**: Embedded API explorer with live requests
- **Code Generation**: Auto-generate client code in multiple languages
- **Request/Response Validation**: Real-time validation feedback
- **Environment Switching**: Test against different API environments

### Tutorial Generation
- **Step-by-step Guides**: Progressive tutorials with checkpoints
- **Video Walkthroughs**: Auto-generated video demonstrations
- **Interactive Sandboxes**: Live coding environments
- **Progress Tracking**: Tutorial completion and achievement system

### Documentation Maintenance
- **Auto-sync**: Keep docs in sync with code changes
- **Version Control**: Track documentation versions with releases
- **Translation**: Multi-language documentation support
- **Analytics**: Track documentation usage and effectiveness

This documentation generator creates comprehensive, interactive, and maintainable documentation that enhances developer experience and reduces support overhead.