# Proximity Social - Testing Guide

## 🧪 Complete Testing Checklist

### Phase 1: Backend Setup & Verification

#### 1.1 Start Backend
```bash
cd backend
docker-compose up
```

**Expected:**
- ✅ PostgreSQL starts on port 5432
- ✅ Backend starts on port 8080
- ✅ "Database initialized successfully" message
- ✅ "Server running on http://0.0.0.0:8080"

#### 1.2 Test Backend Health
```bash
curl http://localhost:8080/health
```
**Expected:** `OK`

#### 1.3 Test User Registration
```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@test.com",
    "password": "test123",
    "name": "Alice"
  }'
```

**Expected Response:**
```json
{
  "user": {
    "id": "uuid-here",
    "email": "alice@test.com",
    "name": "Alice"
  },
  "token": "jwt-token-here"
}
```

---

### Phase 2: Flutter App Setup

#### 2.1 Configure API URL

Edit `lib/api/api_config.dart`:

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8080';
```

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8080';
```

**For Real Device:**
1. Find your computer's IP:
   ```bash
   # macOS
   ipconfig getifaddr en0
   
   # Linux
   hostname -I
   ```
2. Update config:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8080';
   ```

#### 2.2 Install Dependencies
```bash
flutter pub get
```

#### 2.3 Run App
```bash
flutter run
```

---

### Phase 3: Single User Testing

#### 3.1 Authentication Flow

**Test Registration:**
1. App opens → Auth Screen appears
2. Click "Register"
3. Enter:
   - Email: `alice@test.com`
   - Password: `test123`
   - Name: `Alice`
4. Click "Register"

**Expected:**
- ✅ Loading indicator appears
- ✅ Redirects to Home Screen
- ✅ Token saved (survives app restart)
- ✅ Green dot in app bar (WebSocket connected)

**Test Login:**
1. Logout from Home Screen
2. Click "Login"
3. Enter same credentials
4. Click "Login"

**Expected:**
- ✅ Successfully logs in
- ✅ Returns to Home Screen

**Test Persistence:**
1. Force-quit app
2. Reopen app

**Expected:**
- ✅ Automatically logged in
- ✅ Goes directly to Home Screen

#### 3.2 Location Permission

**Expected:**
- ✅ App requests location permission
- ✅ Grant "While Using the App"
- ✅ No errors in logs

**Check Logs:**
```
flutter run --verbose
```
Look for:
```
✅ Location update successful
✅ WebSocket connected
```

#### 3.3 Mock Mode (Offline Testing)

1. Logout
2. Don't login
3. Browse app

**Expected:**
- ✅ Shows mock users in radar
- ✅ Can navigate screens
- ✅ No crashes

---

### Phase 4: Multi-User Testing

#### 4.1 Setup Two Devices

**Option A: Two Emulators**
```bash
# Terminal 1 - iOS Simulator
flutter run -d iPhone

# Terminal 2 - Android Emulator
flutter run -d emulator-5554
```

**Option B: Two Android Emulators**
```bash
# Start two emulators first
emulator -avd Pixel_5_API_33 &
emulator -avd Pixel_6_API_33 &

# Run on both
flutter run -d emulator-5554
flutter run -d emulator-5556
```

#### 4.2 Create Two Users

**Device 1 (Alice):**
- Email: `alice@test.com`
- Password: `test123`
- Name: `Alice`

**Device 2 (Bob):**
- Email: `bob@test.com`
- Password: `test123`
- Name: `Bob`

#### 4.3 Simulate Nearby Locations

**For Android Emulator:**
1. Open Extended Controls (... button)
2. Go to Location
3. Set coordinates:

**Alice's Location:**
- Latitude: `52.5200`
- Longitude: `13.4050`

**Bob's Location (nearby):**
- Latitude: `52.5210`
- Longitude: `13.4060`

**For iOS Simulator:**
1. Debug → Location → Custom Location
2. Enter coordinates above

#### 4.4 Verify Proximity Detection

**On Alice's Device:**
- ✅ Wait 30 seconds (location update interval)
- ✅ Bob should appear in radar
- ✅ Bob shown in "Nearby" list
- ✅ Distance displayed (should be ~1km)

**On Bob's Device:**
- ✅ Alice should appear in radar
- ✅ Alice shown in "Nearby" list

**Backend Logs Should Show:**
```
POST /proximity/location (from Alice)
POST /proximity/location (from Bob)
GET /proximity/nearby (from both)
```

---

### Phase 5: Feature Testing

#### 5.1 Chat (Direct Messages)

**On Alice's Device:**
1. Click on Bob in nearby list
2. Click "Chat" icon (💬)
3. Type: "Hey Bob, testing chat!"
4. Click "Send"

**Expected:**
- ✅ Message appears immediately
- ✅ Shows on right side (sent)
- ✅ Blue/primary color background

**On Bob's Device:**
1. Open chat with Alice
2. Wait a few seconds

**Expected:**
- ✅ Alice's message appears
- ✅ Shows on left side (received)
- ✅ Grey background

**Backend Logs:**
```
POST /messages/send (from Alice)
WebSocket: newMessage event
```

#### 5.2 Broadcast Messages

**On Alice's Device:**
1. Click "Broadcast" button (FAB)
2. Type: "Anyone nearby for coffee?"
3. Click "Send"

**Expected on Alice:**
- ✅ Success snackbar appears
- ✅ Broadcast overlay shows on radar
- ✅ Fades out after 5 seconds

**Expected on Bob (within 100m):**
- ✅ Broadcast overlay appears on radar
- ✅ Shows Alice's message
- ✅ Fades out after 5 seconds

**Backend Logs:**
```
POST /messages/broadcast
WebSocket: broadcast event to nearby users
```

#### 5.3 Ping Notification

**On Alice's Device:**
1. Find Bob in nearby list
2. Click ping icon (📍)

**Expected:**
- ✅ Snackbar: "Sent: 'I'm nearby' to Bob"

**On Bob's Device:**
- ✅ Backend should log ping received
- ✅ (Optional: show notification)

**Backend Logs:**
```
POST /messages/ping/<bobId>
```

#### 5.4 Profile Management

**Test Profile Update:**
1. Click profile icon
2. Change name to "Alice Smith"
3. Change bio to "Coffee lover"
4. Click "Save"

**Expected:**
- ✅ Updates saved
- ✅ Persists after app restart
- ✅ Backend updated (if authenticated)

#### 5.5 Groups

**Test Group Creation:**
1. Click "Manage groups"
2. Click "New group"
3. Enter: "Coffee Buddies"
4. Click "Create"

**Expected:**
- ✅ Group appears in list
- ✅ Shows in filter bar
- ✅ Persists after app restart

**Test Group Filter:**
1. Go to Home Screen
2. Click group filter chip
3. Select "Coffee Buddies"

**Expected:**
- ✅ Only users in that group shown
- ✅ Radar updates
- ✅ List filters

---

### Phase 6: WebSocket Realtime Testing

#### 6.1 Connection Status

**Test WebSocket Indicator:**
- ✅ Green dot when connected
- ✅ Orange when connecting
- ✅ Grey when disconnected
- ✅ Red on error

**Test Reconnection:**
1. Stop backend (Ctrl+C)
2. Observe app

**Expected:**
- ✅ Dot turns grey
- ✅ Attempts to reconnect
- ✅ Shows in logs: "Reconnecting in Xs"

3. Restart backend

**Expected:**
- ✅ Auto-reconnects
- ✅ Dot turns green
- ✅ Logs: "WebSocket connected"

#### 6.2 Live Location Updates

**Setup:**
1. Alice and Bob both online
2. Both locations set initially

**Test:**
1. Change Alice's location significantly
2. Wait 30 seconds

**Expected on Bob's Device:**
- ✅ Alice's position updates on radar
- ✅ Distance changes
- ✅ No page refresh needed

**Backend Logs:**
```
POST /proximity/location (Alice)
WebSocket: locationUpdate broadcast
GET /proximity/nearby (Bob auto-refreshes)
```

#### 6.3 Real-time Broadcasts

**Test:**
1. Alice sends broadcast
2. Observe Bob's screen simultaneously

**Expected:**
- ✅ Bob sees broadcast within 1-2 seconds
- ✅ No polling delay
- ✅ Appears smoothly on radar

---

### Phase 7: Edge Cases & Error Handling

#### 7.1 Network Errors

**Test Offline Mode:**
1. Turn off WiFi on device
2. Try to send message

**Expected:**
- ✅ Error message shown
- ✅ Message cached locally
- ✅ App doesn't crash

**Test Backend Down:**
1. Stop backend server
2. Try to login

**Expected:**
- ✅ Clear error message
- ✅ "Connection refused" or timeout
- ✅ Can retry

#### 7.2 Invalid Input

**Test Registration:**
- ✅ Empty fields → validation error
- ✅ Invalid email → error
- ✅ Short password (<6 chars) → error
- ✅ Duplicate email → "User already exists"

**Test Location:**
- ✅ Deny permission → graceful fallback
- ✅ No GPS signal → mock data fallback

#### 7.3 Performance

**Test Many Users:**
1. Create 5+ test accounts
2. Set all nearby
3. Observe radar

**Expected:**
- ✅ Smooth rendering
- ✅ No lag in radar
- ✅ List scrolls smoothly
- ✅ Max 9 dots per quadrant

**Test Long Messages:**
1. Send very long message (500+ chars)
2. Check rendering

**Expected:**
- ✅ Message wraps properly
- ✅ Chat scrolls correctly
- ✅ No overflow errors

---

### Phase 8: Data Persistence

#### 8.1 Test Session Persistence

**Test:**
1. Login as Alice
2. Close app completely
3. Reopen app

**Expected:**
- ✅ Auto-logged in
- ✅ Same session
- ✅ No re-authentication needed

#### 8.2 Test Data Caching

**Test:**
1. Load nearby users
2. Go offline
3. Reopen app

**Expected:**
- ✅ Last known users still shown
- ✅ Cached data displayed
- ✅ Clear "offline" indicator

---

## 🐛 Known Issues & Fixes

### Issue 1: Android Emulator Can't Reach Backend

**Symptoms:** Connection refused, timeout

**Fix:**
```dart
// Use 10.0.2.2 instead of localhost
static const String baseUrl = 'http://10.0.2.2:8080';
```

### Issue 2: Location Not Updating

**Symptoms:** Same users always, no changes

**Check:**
1. Location permission granted
2. GPS simulation active in emulator
3. Backend logs show location updates
4. 30-second interval is passing

### Issue 3: WebSocket Won't Connect

**Symptoms:** Grey dot, no realtime updates

**Debug:**
```bash
# Check backend logs
cd backend
docker-compose logs -f backend

# Look for:
"WebSocket connected"
"User <id> connected"
```

**Common Fixes:**
- Restart backend
- Check firewall rules
- Verify WebSocket URL in config
- Check authentication token

### Issue 4: Users Don't See Each Other

**Checklist:**
- ✅ Both users registered
- ✅ Both shared location
- ✅ Locations within 30km
- ✅ At least 30 seconds passed
- ✅ Backend shows both locations in DB

**SQL Debug Query:**
```sql
-- Connect to DB
docker exec -it proximity-db psql -U postgres -d proximity_social

-- Check user locations
SELECT 
  u.name,
  ST_X(ul.location::geometry) as longitude,
  ST_Y(ul.location::geometry) as latitude,
  ul.updated_at
FROM users u
JOIN user_locations ul ON u.id = ul.user_id;
```

---

## 📊 Performance Benchmarks

**Target Metrics:**
- Login time: < 2 seconds
- Location update: < 1 second
- Nearby users query: < 500ms
- Chat message send: < 500ms
- WebSocket latency: < 200ms
- Radar rendering: 60 FPS
- App startup: < 3 seconds

**Test Commands:**
```bash
# Measure API response times
time curl http://localhost:8080/proximity/nearby \
  -H "Authorization: Bearer <token>"

# Flutter performance
flutter run --profile
flutter run --release  # For production testing
```

---

## ✅ Complete Test Checklist

### Backend
- [ ] Backend starts successfully
- [ ] Database initializes
- [ ] Health endpoint works
- [ ] User registration works
- [ ] User login works
- [ ] Location updates save
- [ ] Proximity queries return results
- [ ] Messages send/receive
- [ ] Broadcasts work
- [ ] WebSocket connects
- [ ] WebSocket reconnects after disconnect

### Flutter App - Authentication
- [ ] Registration form validates
- [ ] Registration succeeds
- [ ] Login succeeds
- [ ] Token persists
- [ ] Auto-login works
- [ ] Logout works

### Flutter App - Location
- [ ] Permission requested
- [ ] Location updates send
- [ ] Nearby users load
- [ ] Radar displays users
- [ ] Distance calculated correctly
- [ ] Quadrants work properly

### Flutter App - Chat
- [ ] Chat screen opens
- [ ] Messages load from backend
- [ ] Send message works
- [ ] Messages appear in real-time
- [ ] Scrolling smooth
- [ ] Long messages wrap

### Flutter App - Broadcasts
- [ ] Broadcast sends
- [ ] Overlay appears
- [ ] Fades after 5 seconds
- [ ] Recipients receive
- [ ] WebSocket delivery works

### Flutter App - UI/UX
- [ ] Radar renders smoothly
- [ ] Filters work
- [ ] Profile updates save
- [ ] Groups persist
- [ ] Theme consistent
- [ ] No layout errors
- [ ] Mobile responsive

### Multi-User
- [ ] Two users see each other
- [ ] Chat works bidirectional
- [ ] Broadcasts reach nearby
- [ ] Location updates in real-time
- [ ] Ping notifications work

### Error Handling
- [ ] Offline mode works
- [ ] Network errors show
- [ ] Invalid input validated
- [ ] Backend down handled
- [ ] Graceful degradation

### Performance
- [ ] App starts quickly
- [ ] Radar at 60 FPS
- [ ] No memory leaks
- [ ] Battery efficient
- [ ] Network efficient

---

## 🔍 Debugging Tips

### Enable Verbose Logging

**Flutter:**
```bash
flutter run --verbose
```

**Backend:**
Backend logs are already verbose in development.

### Monitor WebSocket Traffic

**Browser DevTools:**
```javascript
// In Chrome console
ws = new WebSocket('ws://localhost:8080/ws');
ws.onmessage = (e) => console.log('Received:', e.data);
ws.send(JSON.stringify({type: 'authenticate', userId: 'test-id'}));
```

### Database Queries

```bash
# Connect to DB
docker exec -it proximity-db psql -U postgres -d proximity_social

# Useful queries
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM user_locations;
SELECT COUNT(*) FROM messages;

# Check nearby users manually
SELECT 
  u1.name as user1,
  u2.name as user2,
  ST_Distance(ul1.location::geography, ul2.location::geography) as distance_meters
FROM user_locations ul1
CROSS JOIN user_locations ul2
JOIN users u1 ON ul1.user_id = u1.id
JOIN users u2 ON ul2.user_id = u2.id
WHERE ul1.user_id != ul2.user_id;
```

---

## 📝 Test Report Template

After testing, fill out this report:

```
# Proximity Social Test Report
Date: _______
Tester: _______
Environment: iOS Simulator / Android Emulator / Real Device

## Test Results

### Backend
- [ ] All API endpoints working
- [ ] WebSocket stable
- [ ] Database queries fast
- Issues: _______

### Single User
- [ ] Login/Register works
- [ ] Location updates
- [ ] UI smooth
- Issues: _______

### Multi-User
- [ ] Users see each other
- [ ] Chat works
- [ ] Broadcasts work
- Issues: _______

### Performance
- App startup time: _____ seconds
- API response time: _____ ms
- Radar FPS: _____
- Issues: _______

### Critical Bugs Found:
1. _______
2. _______

### Suggestions:
1. _______
2. _______
```

---

## 🎯 Next Steps After Testing

Once all tests pass:
1. ✅ Document any bugs found
2. ✅ Fix critical issues
3. ✅ Optimize performance bottlenecks
4. ✅ Add analytics/monitoring
5. ✅ Prepare for production deployment

Happy Testing! 🚀

