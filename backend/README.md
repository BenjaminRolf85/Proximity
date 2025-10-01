# Proximity Social Backend

Dart/Shelf backend server for the Proximity Social mobile app.

## Features

- ✅ REST API with JWT authentication
- ✅ WebSocket support for real-time updates
- ✅ PostgreSQL with PostGIS for geospatial queries
- ✅ Proximity matching algorithm
- ✅ Direct messaging & broadcasts
- ✅ Location tracking & nearby users

## Tech Stack

- **Framework:** Dart Shelf
- **Database:** PostgreSQL 15+ with PostGIS extension
- **Auth:** JWT tokens
- **Realtime:** WebSockets

## Prerequisites

- Dart SDK 3.9+
- PostgreSQL 15+ with PostGIS extension
- Docker (optional, for easy PostgreSQL setup)

## Quick Start

### 1. Install PostgreSQL with PostGIS

**Using Docker (Recommended):**
```bash
docker run --name proximity-db \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=proximity_social \
  -p 5432:5432 \
  -d postgis/postgis:15-3.4
```

**Or install locally:**
- macOS: `brew install postgresql postgis`
- Linux: `apt-get install postgresql postgresql-15-postgis-3`

### 2. Setup Environment

```bash
cd backend
cp .env.example .env
# Edit .env with your settings
```

### 3. Install Dependencies

```bash
dart pub get
```

### 4. Run Server

```bash
dart run bin/server.dart
```

Server will start on `http://localhost:8080`

## API Documentation

### Authentication

**Register:**
```bash
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

**Login:**
```bash
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "2025-10-01T..."
  },
  "token": "jwt_token_here"
}
```

### Proximity

**Update Location:**
```bash
POST /proximity/location
Authorization: Bearer <token>
Content-Type: application/json

{
  "latitude": 52.5200,
  "longitude": 13.4050,
  "accuracy": 10.0
}
```

**Get Nearby Users:**
```bash
GET /proximity/nearby?maxDistance=5000&limit=50
Authorization: Bearer <token>
```

Response:
```json
{
  "users": [
    {
      "user": {
        "id": "uuid",
        "name": "Jane Doe",
        "avatarUrl": "https://..."
      },
      "distanceMeters": 234.5,
      "bearing": 45.2
    }
  ],
  "count": 1
}
```

### Messages

**Send Message:**
```bash
POST /messages/send
Authorization: Bearer <token>
Content-Type: application/json

{
  "toUserId": "recipient-uuid",
  "text": "Hello!"
}
```

**Send Broadcast:**
```bash
POST /messages/broadcast
Authorization: Bearer <token>
Content-Type: application/json

{
  "text": "Anyone nearby?"
}
```

**Get Conversation:**
```bash
GET /messages/conversation/<otherUserId>?limit=50
Authorization: Bearer <token>
```

### WebSocket

Connect to `ws://localhost:8080/ws`

**Authenticate:**
```json
{
  "type": "authenticate",
  "userId": "your-user-id"
}
```

**Location Update:**
```json
{
  "type": "location_update",
  "latitude": 52.5200,
  "longitude": 13.4050
}
```

**Receive Events:**
```json
{
  "type": "newMessage",
  "data": {
    "message": {...}
  },
  "timestamp": "2025-10-01T..."
}
```

## Database Schema

### users
- `id` (UUID, primary key)
- `email` (unique)
- `password_hash`
- `name`
- `avatar_url`
- `bio`
- `created_at`
- `last_seen`

### user_locations
- `user_id` (UUID, foreign key)
- `location` (PostGIS geography point)
- `accuracy` (double)
- `updated_at`

### messages
- `id` (UUID)
- `from_user_id` (UUID)
- `to_user_id` (UUID, nullable for broadcasts)
- `text`
- `type` (text|broadcast|ping)
- `created_at`
- `is_read`

## Development

**Run with hot reload:**
```bash
dart run bin/server.dart
```

**Run tests:**
```bash
dart test
```

**Format code:**
```bash
dart format .
```

**Analyze:**
```bash
dart analyze
```

## Deployment

### Docker

```bash
docker build -t proximity-backend .
docker run -p 8080:8080 --env-file .env proximity-backend
```

### Railway/Fly.io

1. Add PostgreSQL database
2. Set environment variables
3. Deploy with `dart compile exe` or Docker

## Environment Variables

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=proximity_social
DB_USER=postgres
DB_PASSWORD=your_password

PORT=8080
HOST=0.0.0.0

JWT_SECRET=your_secret_min_32_chars

ENVIRONMENT=production
```

## Performance Tips

- Enable PostGIS spatial indexes (automatically created)
- Use connection pooling for high load
- Set up Redis for session caching
- Enable gzip compression
- Use CDN for static assets

## Security Considerations

- Always use HTTPS in production
- Rotate JWT secrets regularly
- Implement rate limiting
- Validate all user inputs
- Use prepared statements (built-in with postgres package)
- Set up CORS properly

## License

MIT

