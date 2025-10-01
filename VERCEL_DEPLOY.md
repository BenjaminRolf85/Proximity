# 🚀 Vercel Deployment - Schritt für Schritt

## Voraussetzungen
- ✅ Flutter Web Build erstellt (`build/web` existiert)
- GitHub Account (kostenlos)
- Vercel Account (kostenlos)

---

## 🎯 Methode 1: Vercel CLI (Schnellste)

### 1. Vercel CLI installieren
```bash
npm install -g vercel
```

### 2. In build/web Ordner wechseln
```bash
cd build/web
```

### 3. Deployen
```bash
vercel --prod
```

**Fertig!** Vercel gibt dir eine URL wie:
```
https://proximity-social-xyz.vercel.app
```

---

## 🎯 Methode 2: Via Vercel Dashboard (Empfohlen)

### 1. Code zu GitHub pushen

**Falls noch nicht im Git:**
```bash
cd /Users/ben/proximity_social
git init
git add .
git commit -m "Proximity Social v0.1"
git branch -M main
git remote add origin https://github.com/DEIN_USERNAME/proximity_social.git
git push -u origin main
```

### 2. Vercel Account erstellen
1. Gehe zu [vercel.com](https://vercel.com)
2. **Sign Up with GitHub**
3. Autorisiere Vercel

### 3. New Project
1. Click **"Add New..."** → **"Project"**
2. **Import Git Repository**
3. Wähle `proximity_social`

### 4. Configure Project
```
Framework Preset: Other
Root Directory: ./
Build Command: flutter build web --release --no-tree-shake-icons
Output Directory: build/web
Install Command: (leer lassen)
```

### 5. Environment Variables
**Keine nötig für jetzt!**  
(Backend URL ist hardcoded in api_config.dart)

### 6. Deploy!
Click **"Deploy"**

⏱️ Deployment dauert ~2-3 Minuten

---

## 🔧 Nach dem Deployment

### Deine URLs:
```
Production: https://proximity-social.vercel.app
Preview:    https://proximity-social-git-main-username.vercel.app
```

### App testen:
1. Öffne die Vercel URL
2. Erstelle Account oder login:
   - alice@test.com / test123
   - bob@test.com / test123
3. Erlaube Location (Browser fragt)
4. Sieh dir den Radar an!

---

## 🌐 Custom Domain (Optional)

### In Vercel Dashboard:
1. Settings → Domains
2. Add Domain: `proximity.deinedomain.de`
3. DNS konfigurieren (Vercel zeigt Anleitung)

---

## ⚙️ Backend URL Update (Wichtig!)

**Problem:** App zeigt aktuell auf `localhost:8080`

**Lösung:** Backend auch deployen oder API Config ändern

### Option A: Temporary - Mock Mode
Für jetzt läuft die App im **Mock Mode** (ohne Backend).  
User sehen Test-Daten - perfekt für UI-Demo!

### Option B: Backend auch deployen
Siehe `DEPLOYMENT_GUIDE.md` → Railway Setup

Dann update `lib/api/api_config.dart`:
```dart
static const String baseUrl = 'https://dein-backend.up.railway.app';
static const String wsUrl = 'wss://dein-backend.up.railway.app';
```

Und rebuild:
```bash
flutter build web --release --no-tree-shake-icons
vercel --prod
```

---

## 🐛 Troubleshooting

### Build schlägt fehl
```bash
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
```

### Vercel zeigt weiße Seite
- Check Browser Console für Errors
- Vercel Logs checken
- Base href korrekt? (`/`)

### Icons fehlen
```bash
flutter build web --release --no-tree-shake-icons
```
(`--no-tree-shake-icons` ist wichtig!)

---

## 📊 Vercel Features

**Automatisch inkludiert:**
- ✅ HTTPS/SSL
- ✅ Global CDN
- ✅ Automatic Compression
- ✅ Analytics (optional)
- ✅ Preview Deployments (Git branches)
- ✅ Rollbacks
- ✅ Custom Domains

**Free Tier Limits:**
- 100 GB Bandwidth/month
- Unlimited deployments
- Unlimited team members

**Kosten:** $0/Monat für persönliche Projekte! 🎉

---

## ✅ Checklist

- [ ] Git Repository erstellt
- [ ] Code zu GitHub gepusht
- [ ] Vercel Account erstellt
- [ ] Projekt importiert
- [ ] Build Settings konfiguriert
- [ ] Deployed!
- [ ] URL getestet
- [ ] Mit Freunden geteilt

---

## 🎊 Fertig!

Deine App ist jetzt **live im Internet**!

Teile die URL und lass Leute testen! 🚀

