# Proximity Social - Setup Guide

## 🚀 Quick Start

### 1. Backend Setup

**Option A: Docker (Einfachster Weg)**
```bash
cd backend
docker-compose up
```

**Option B: Lokale Installation**
```bash
# PostgreSQL mit PostGIS starten
docker run --name proximity-db \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=proximity_social \
  -p 5432:5432 \
  -d postgis/postgis:15-3.4

# Backend starten
cd backend
dart pub get
dart run bin/server.dart
```

Backend läuft auf: `http://localhost:8080`

### 2. Flutter App Setup

**API Konfiguration anpassen:**

Öffne `lib/api/api_config.dart` und passe die URLs an:

```dart
// Für iOS Simulator
static const String baseUrl = 'http://localhost:8080';

// Für Android Emulator
static const String baseUrl = 'http://10.0.2.2:8080';

// Für echtes Gerät (ersetze mit deiner Computer-IP)
static const String baseUrl = 'http://192.168.1.XXX:8080';
```

**Dependencies installieren:**
```bash
flutter pub get
```

**App starten:**
```bash
flutter run
```

## 📱 App Verwendung

### Erster Start

1. **Registrierung:**
   - Öffne die App
   - Klicke auf "Register"
   - Gib Email, Passwort und Namen ein
   - Klicke auf "Register"

2. **Location Permissions:**
   - Die App wird nach Standort-Berechtigung fragen
   - Erlaube "While Using the App" oder "Always"

3. **Hauptscreen:**
   - Radar-Ansicht zeigt Personen in der Nähe
   - Liste unten zeigt Details
   - Filter oben für Gruppen

### Features

- **Radar View:** Zeigt Personen in 4 Quadranten (Nachbarschaft, Stadt, Land, Weiter)
- **Chat:** Direktnachrichten an Personen in der Nähe
- **Broadcast:** Nachricht an alle innerhalb 100m
- **Ping:** "I'm nearby" Benachrichtigung
- **Groups:** Organisiere Kontakte in Gruppen
- **Profile:** Avatar und Bio bearbeiten

## 🔧 Entwicklung

### Backend testen

```bash
# Health Check
curl http://localhost:8080/health

# User registrieren
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "test123",
    "name": "Test User"
  }'

# Login
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "test123"
  }'
```

### Mock Mode vs. Backend Mode

Die App funktioniert in 2 Modi:

**Mock Mode (Offline):**
- Ohne Login
- Zeigt Test-Daten
- Keine echten Location-Updates

**Backend Mode (Online):**
- Nach Login
- Echte Proximity-Daten
- Location-Updates alle 30 Sekunden
- Realtime WebSocket Updates

### Debug-Logs

Backend:
```bash
cd backend
dart run bin/server.dart
# Zeigt alle API-Requests und WebSocket-Events
```

Flutter:
```bash
flutter run --verbose
# Zeigt API-Calls und Errors
```

## 🌍 Multi-User Testing

Um mit mehreren Benutzern zu testen:

1. **2 Emulatoren starten:**
```bash
# Terminal 1
flutter run -d emulator-5554

# Terminal 2
flutter run -d emulator-5556
```

2. **Verschiedene Accounts registrieren**
   - User1: test1@test.com
   - User2: test2@test.com

3. **Location simulieren:**
   - Android: Über Extended Controls → Location
   - iOS: Debug → Location → Custom Location

4. **Testen:**
   - Beide User in ähnlicher Location
   - Sollten sich gegenseitig auf Radar sehen
   - Chat/Broadcast/Ping testen

## ⚙️ API Configuration für Produktion

### Backend Environment Variables

```env
DB_HOST=your-db-host
DB_PORT=5432
DB_NAME=proximity_social
DB_USER=your-user
DB_PASSWORD=your-secure-password
PORT=8080
JWT_SECRET=your-very-secure-secret-min-32-chars
ENVIRONMENT=production
```

### Flutter API Config

Für Production solltest du verschiedene Configs haben:

```dart
class ApiConfig {
  static String get baseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod':
        return 'https://api.yourdomain.com';
      case 'staging':
        return 'https://staging-api.yourdomain.com';
      default:
        return 'http://localhost:8080';
    }
  }
}
```

Build mit:
```bash
flutter build apk --dart-define=ENV=prod
```

## 🐛 Troubleshooting

### Backend startet nicht
- PostgreSQL läuft: `psql -U postgres -d proximity_social`
- PostGIS Extension: `psql -d proximity_social -c "SELECT PostGIS_version();"`
- Port 8080 frei: `lsof -i :8080`

### App kann Backend nicht erreichen
- Backend läuft: `curl http://localhost:8080/health`
- Firewall erlaubt Port 8080
- Richtige IP in `api_config.dart`
- Android Emulator: Nutze `10.0.2.2` statt `localhost`

### Location funktioniert nicht
- Permissions gewährt in Systemeinstellungen
- Location Services aktiviert
- GPS-Simulation im Emulator aktiv

### Keine Nearby Users
- Beide User haben Location geteilt
- Location-Updates laufen (Check Backend Logs)
- maxDistance groß genug (30km default)
- Mindestens ein anderer User online

## 📊 Performance Tipps

- Location Update Intervall anpassen: `people_provider.dart` → `Timer.periodic`
- Nearby Users Limit: `proximity_api.dart` → `getNearbyUsers(limit: X)`
- WebSocket Reconnect: `websocket_service.dart` → `_maxReconnectAttempts`
- Database Indexes sind bereits optimiert (PostGIS spatial index)

## 🔐 Security Checklist für Production

- [ ] HTTPS/WSS für alle Connections
- [ ] JWT Secret > 32 chars und rotieren
- [ ] Rate Limiting implementieren
- [ ] Input Validation auf Backend
- [ ] PostgreSQL Passwort ändern
- [ ] Firewall Rules konfigurieren
- [ ] CORS richtig einstellen
- [ ] Logs in Production-Ready System
- [ ] Backup-Strategie für DB
- [ ] Monitoring (Sentry, DataDog, etc.)

## 📝 Nächste Steps

**MVP fertigstellen:**
- [x] Backend API
- [x] Flutter Integration
- [x] Authentication
- [x] Location Tracking
- [x] Proximity Matching
- [x] Chat & Broadcasts

**Production Ready:**
- [ ] Push Notifications
- [ ] File Upload (Avatars)
- [ ] Groups Backend API
- [ ] Rate Limiting
- [ ] Error Tracking
- [ ] Analytics

**Optional Features:**
- [ ] Voice Messages
- [ ] Image Sharing
- [ ] Meetup Scheduling
- [ ] In-App Map View
- [ ] Social Sharing

