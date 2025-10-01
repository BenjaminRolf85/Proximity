# 🚀 Quick Test Guide

## ✅ Backend läuft bereits!
- PostgreSQL: Port 5432
- API Server: http://localhost:8080
- WebSocket: ws://localhost:8080/ws

## 📱 App startet in Chrome...

### Sobald Chrome öffnet:

#### 1. Register Screen
Du siehst:
- **Orange Theme** (Material 3)
- Input-Felder für Email/Password/Name
- Register/Login Buttons

#### 2. Ersten Account erstellen:
```
Email:    alice@test.com
Password: test123
Name:     Alice
```
→ Klick **"Register"**

**Was passiert:**
- Loading indicator
- Backend erstellt User
- Token wird gespeichert
- Auto-Login zu Home Screen

#### 3. Home Screen
Du siehst:
- **Radar View** (leer, weil keine anderen User)
- **Grüner Punkt** oben rechts = WebSocket connected
- **"0 people"** unten
- Navigation: Groups, Broadcast, Profile, Logout

#### 4. Profile testen:
1. Click Profile Icon (Person)
2. Click auf Avatar → Wähle Icon
3. Name ändern
4. Bio hinzufügen: "Test User"
5. Click "Speichern"

**Backend Log zeigt:**
```
PATCH /auth/me
→ Profile updated
```

#### 5. Broadcast senden:
1. Click "Broadcast" FAB
2. Type: "Hello from Alice!"
3. Click "Send"

**Du siehst:**
- Overlay-Text auf Radar
- Fades out nach 5 Sekunden
- Schöne Animation

**Backend Log:**
```
POST /messages/broadcast
→ Broadcast sent to 0 nearby users
```
(0 users weil noch keine anderen online)

#### 6. Mock Mode testen:
1. Click Logout
2. Browse App ohne Login

**Du siehst:**
- Mock-Users im Radar (Alex, Sam, Jordan, etc.)
- Alles funktioniert offline
- Keine Backend-Calls

## ⏱️ Timing:
- Chrome öffnet in ~30-60 Sek
- Backend antwortet in <100ms
- Location updates alle 30 Sek
- Broadcasts verschwinden nach 5 Sek

## 📊 Was ich sehe (Backend Logs):
Sobald du registrierst, sehe ich:
```
POST /auth/register
→ User alice@test.com created
→ JWT token generated
→ Response 200 OK

WebSocket connected: <userId>
→ Active connections: 1
```

## 🎯 Nächster Test:
Sobald Chrome funktioniert, können wir:
- **Zweiten Browser-Tab** öffnen für Multi-User Test
- **Beide Users** sehen sich im Radar
- **Chat** zwischen Alice & Bob
- **Broadcast** empfangen

## ❓ Probleme?
Sag Bescheid und ich helfe sofort! 🚀

