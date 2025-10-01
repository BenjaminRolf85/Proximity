# 🚂 Railway Backend Deployment - Step by Step

## ✅ Was du brauchst:
- GitHub Account (hast du ✅)
- Railway Account (kostenlos)
- 5 Minuten Zeit

---

## 🚀 Schritt-für-Schritt Anleitung

### **1. Railway Account erstellen**

1. Gehe zu **[railway.app](https://railway.app)**
2. Click **"Login"** → **"Login with GitHub"**
3. Autorisiere Railway
4. **Trial starten** (kostenlos, keine Kreditkarte nötig)

---

### **2. Neues Projekt erstellen**

1. Click **"New Project"**
2. Wähle **"Deploy from GitHub repo"**
3. Suche **"Proximity"**
4. Click **"Deploy Now"**

---

### **3. PostgreSQL Database hinzufügen**

1. Im Railway Dashboard → Click **"+ New"**
2. Wähle **"Database"** → **"PostgreSQL"**
3. Railway erstellt die Datenbank automatisch

**Wichtig:** PostGIS Extension hinzufügen!

4. Click auf die PostgreSQL Service
5. Gehe zu **"Data"** Tab
6. Click **"Query"**
7. Führe aus:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

---

### **4. Backend Service konfigurieren**

1. Click auf die **Backend Service** (dein Proximity Repo)
2. Gehe zu **"Settings"**
3. **Root Directory:** `/backend`
4. **Build Command:** (leer lassen, nutzt Dockerfile)
5. Click **"Save"**

---

### **5. Environment Variables setzen**

1. In der Backend Service → **"Variables"** Tab
2. Click **"+ New Variable"**

**Füge hinzu:**
```
JWT_SECRET=dein_super_sicherer_secret_key_mindestens_32_zeichen_lang
ENVIRONMENT=production
```

**PostgreSQL Variablen** werden automatisch gesetzt von Railway:
- `PGHOST`
- `PGPORT`
- `PGDATABASE`
- `PGUSER`
- `PGPASSWORD`

---

### **6. Deployment starten**

1. Railway deployt automatisch!
2. Watch den **"Deployments"** Tab
3. Build dauert ~3-5 Minuten

---

### **7. Backend URL erhalten**

1. Gehe zur Backend Service
2. Click **"Settings"** → **"Networking"**
3. Click **"Generate Domain"**

Railway gibt dir eine URL wie:
```
https://proximity-production-xxxx.up.railway.app
```

**Kopiere diese URL!** Du brauchst sie gleich.

---

### **8. Frontend auf neue Backend-URL updaten**

Jetzt müssen wir die Flutter App auf das Railway Backend zeigen lassen.

**Update `lib/api/api_config.dart`:**
```dart
static const String baseUrl = 'https://proximity-production-xxxx.up.railway.app';
static const String wsUrl = 'wss://proximity-production-xxxx.up.railway.app';
```

**Dann:**
```bash
cd /Users/ben/proximity_social
flutter build web --release --no-tree-shake-icons
git add .
git commit -m "Update API to Railway backend"
git push
```

Vercel deployed automatisch die neue Version!

---

### **9. Testen!**

**Jetzt können echte User miteinander interagieren!**

1. Öffne deine Vercel URL: `https://proximity-xyz.vercel.app`
2. Registriere dich: `test1@test.com`
3. Teile URL mit Freund
4. Freund registriert sich: `test2@test.com`
5. **Beide setzen Location auf Berlin:**
   - Chrome DevTools → Sensors → Location: Berlin
6. **Sie sehen sich gegenseitig!** 🎉

---

## 💰 Kosten

**Railway Free Trial:**
- $5 Credit gratis
- ~500 Stunden Runtime/Monat
- Perfekt für MVP Testing

**Nach Trial:**
- ~$5-10/Monat für Backend + DB
- Pay-as-you-go
- Kein Lock-in

---

## 🐛 Troubleshooting

### Build schlägt fehl

**Check Root Directory:**
- Settings → Root Directory = `/backend`
- Dockerfile sollte erkannt werden

### PostgreSQL Connection Error

**Check Variables:**
- Sind PGHOST, PGPORT etc. gesetzt?
- Railway verbindet automatisch

### Backend startet nicht

**Check Logs:**
- Deployments → Click auf aktuelles Deployment
- Scroll zu Logs
- Suche nach Error Messages

---

## ✅ Checklist

Backend Deployment:
- [ ] Railway Account erstellt
- [ ] PostgreSQL hinzugefügt
- [ ] PostGIS Extension installiert
- [ ] Backend Service deployed
- [ ] Environment Variables gesetzt
- [ ] Domain generiert
- [ ] URL kopiert

Frontend Update:
- [ ] api_config.dart mit Railway URL updated
- [ ] Web neu gebaut
- [ ] Zu GitHub gepusht
- [ ] Vercel auto-deployed

Testing:
- [ ] Vercel URL geöffnet
- [ ] User registriert
- [ ] Backend antwortet
- [ ] Daten in PostgreSQL
- [ ] Multi-User Test erfolgreich

---

## 🎊 Fertig!

**Sobald alles deployed ist, hast du:**

✅ Öffentlich zugängliche App (Vercel)  
✅ Öffentliches Backend (Railway)  
✅ PostgreSQL Datenbank (Railway)  
✅ HTTPS/WSS (automatisch)  
✅ Echte User-Interaktion möglich  
✅ Teilbar mit jedem im Internet  

**Deine App ist dann LIVE! 🌍**

