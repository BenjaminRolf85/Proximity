# 🚀 Deployment Guide - Proximity Social

## Backend Deployment (Railway.app)

### 1. Account erstellen
1. Gehe zu [railway.app](https://railway.app)
2. **Sign Up** mit GitHub
3. **New Project** klicken

### 2. PostgreSQL hinzufügen
1. Click **"Add Service"** → **"Database"** → **"PostgreSQL"**
2. Railway erstellt automatisch die DB
3. Notiere dir die Connection Variablen (werden automatisch gesetzt)

### 3. Backend deployen
1. **"Add Service"** → **"GitHub Repo"**
2. Wähle dein `proximity_social` Repository
3. **Root Directory:** `/backend`
4. Railway erkennt automatisch das Dockerfile

### 4. Environment Variables setzen
In Railway Dashboard → Backend Service → **Variables**:

```env
JWT_SECRET=dein_sehr_sicherer_secret_min_32_zeichen_lang_hier
ENVIRONMENT=production
```

Die PostgreSQL Variablen (PGHOST, PGPORT, etc.) werden automatisch gesetzt!

### 5. Domain notieren
Railway gibt dir eine URL wie:
```
https://proximity-backend-production.up.railway.app
```

**Speichere diese URL!**

---

## Frontend Deployment (Vercel)

### 1. Flutter Web Build erstellen

```bash
cd /Users/ben/proximity_social
flutter build web --release
```

### 2. API Config aktualisieren

Erstelle `lib/api/api_config_production.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://DEINE-RAILWAY-URL.up.railway.app';
  static const String wsUrl = 'wss://DEINE-RAILWAY-URL.up.railway.app';
  // ... rest bleibt gleich
}
```

### 3. Neu builden

```bash
flutter build web --release
```

### 4. Vercel deployen

**Option A: Via Vercel CLI**
```bash
npm install -g vercel
cd build/web
vercel --prod
```

**Option B: Via GitHub**
1. Push code zu GitHub
2. [vercel.com](https://vercel.com) → **New Project**
3. Import dein Repo
4. **Root Directory:** `build/web`
5. Deploy!

### 5. Domain erhalten

Vercel gibt dir eine URL wie:
```
https://proximity-social.vercel.app
```

---

## Schnellere Alternative: Alles auf Railway

### Backend + Frontend zusammen

1. Erstelle `backend/public/` Ordner
2. Kopiere `build/web/*` nach `backend/public/`
3. Backend serviert auch Frontend

**Update `backend/bin/server.dart`:**
```dart
// Serve static files
app.mount('/app/', shelf_static.createStaticHandler('public'));

// Fallback to index.html for SPA
app.get('/<any>', (Request request) {
  return shelf_static.createStaticHandler('public/index.html')(request);
});
```

Dann nur **ein** Railway Deployment! 🎯

---

## Noch Schneller: Ngrok (Für Testing)

**Sofort teilen ohne Deploy:**

```bash
# Install ngrok
brew install ngrok

# Backend exposen
ngrok http 8080
```

Ngrok gibt dir eine URL wie:
```
https://abc123.ngrok.io
```

Update `api_config.dart` mit dieser URL und rebuild!

**Vorteil:** Sofort verfügbar
**Nachteil:** URL ändert sich bei Neustart (Paid: feste URL)

---

## Was möchtest du?

**A) Railway + Vercel** (Production-ready, ~10 Min)
**B) Alles auf Railway** (Einfacher, ~5 Min)  
**C) Ngrok** (Sofort, für Testing, ~2 Min) ⚡

Empfehlung: **C für jetzt, dann später B** 🚀

