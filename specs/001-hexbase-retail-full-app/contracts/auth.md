# API Contract: Authentication

**Base**: `/api/v1`

---

## POST /auth/login

Authenticate a user. Returns a Sanctum token.

**Auth**: None  
**Rate limit**: 10/min per IP

**Request**:
```json
{
  "email": "user@shop.com",
  "password": "secret",
  "device_name": "Flutter Web"
}
```

**Response 200**:
```json
{
  "data": {
    "token": "1|abc123...",
    "user": {
      "id": 1,
      "name": "Ravi Kumar",
      "email": "user@shop.com",
      "roles": ["accountant"],
      "permissions": ["sales_invoice.create", "sales_invoice.view"]
    }
  }
}
```

**Response 422**: Invalid credentials  
**Response 429**: Rate limit exceeded

---

## POST /auth/logout

Revoke the current token.

**Auth**: Required

**Response 200**:
```json
{ "message": "Logged out successfully" }
```

---

## POST /auth/password/forgot

Send password reset link.

**Auth**: None  
**Rate limit**: 10/min per IP

**Request**: `{ "email": "user@shop.com" }`  
**Response 200**: `{ "message": "Reset link sent if account exists" }`

---

## POST /auth/password/reset

Reset password using token from email.

**Auth**: None

**Request**:
```json
{
  "token": "reset-token",
  "email": "user@shop.com",
  "password": "newpassword",
  "password_confirmation": "newpassword"
}
```

**Response 200**: `{ "message": "Password reset successfully" }`  
**Response 422**: Token expired or invalid

---

## GET /auth/profile

Get current user profile.

**Auth**: Required  
**Roles**: Any

**Response 200**:
```json
{
  "data": {
    "id": 1,
    "name": "Ravi Kumar",
    "email": "user@shop.com",
    "mobile": "9876543210",
    "roles": ["accountant"],
    "permissions": ["..."]
  }
}
```

---

## PUT /auth/profile

Update current user's name, mobile, and password.

**Auth**: Required  
**Roles**: Any

**Request**:
```json
{
  "name": "Ravi Kumar",
  "mobile": "9876543210",
  "current_password": "old",
  "password": "new",
  "password_confirmation": "new"
}
```

**Response 200**: Updated user profile

---

## User Management (Admin only)

### GET /users
List all users. **Roles**: admin

### POST /users
Create user. **Roles**: admin  
**Request**: `{ "name", "email", "password", "password_confirmation", "role", "mobile" }`

### GET /users/{id}
Get user. **Roles**: admin

### PUT /users/{id}
Update user. **Roles**: admin

### DELETE /users/{id}
Deactivate user (soft). **Roles**: admin
