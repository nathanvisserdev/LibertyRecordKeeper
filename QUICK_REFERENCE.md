# Liberty Record Keeper - Quick Reference

## 🚀 Quick Start

```bash
1. Open LibertyRecordKeeper.xcodeproj
2. Select your development team
3. Connect iOS device or select "My Mac"
4. Build and Run (⌘R)
5. Authenticate with Face ID/Touch ID
6. Grant all permissions
```

## 🔑 Key Commands

### Build & Run
- Build: `⌘B`
- Run: `⌘R`
- Clean: `⇧⌘K`
- Stop: `⌘.`

### Testing
- Test: `⌘U`
- Test Selected: `⌘⌥U`

## 📱 App Structure

```
Tab 1: Screen Recordings → Start/Stop Recording
Tab 2: Videos → Setup Camera → Record/Stop
Tab 3: Photos → Setup Camera → Capture Photo
Tab 4: Audio → Start/Stop Recording
Tab 5: Screenshots → Auto-monitored
Tab 6: AI Chat Logs → Coming Soon
```

## 🔐 Security Flow

```
Launch → Biometric Auth → Key Retrieval → DB Init → App Ready
```

## 💾 Data Flow

```
Capture → Checksum → Encrypt → Save Local → Sync CloudKit
```

## 📊 Database Quick Reference

### Tables
- `screen_recordings`
- `videos`
- `photos`
- `audio_recordings`
- `screenshots`
- `ai_chat_logs`

### Common Queries
```sql
-- View all recordings
SELECT * FROM screen_recordings ORDER BY created_at DESC;

-- Check integrity
SELECT id, checksum_sha256 FROM photos;

-- Chain of custody
SELECT id, custody_json FROM videos WHERE id = ?;
```

## 🛠️ Common Tasks

### Add New Permission
1. Add key to `Info.plist`
2. Add description string
3. Request in service
4. Test on device

### Add New Record Type
1. Add to `ForensicRecord.swift`
2. Add table in `DatabaseService.swift`
3. Add save/fetch methods
4. Add CloudKit upload
5. Create ViewModel
6. Create View
7. Add to TabView

### Debug Authentication
```swift
// Bypass for testing (DEV ONLY!)
#if DEBUG
isAuthenticated = true
#else
// Normal auth flow
#endif
```

### View Database
```bash
# Find app container
xcrun simctl get_app_container booted com.yourteam.LibertyRecordKeeper data

# Open database
sqlite3 Documents/forensic_records.db
```

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails | Clean build folder (⇧⌘K) |
| Auth fails | Check biometrics enabled |
| Camera not working | Grant permissions in Settings |
| CloudKit error | Check team & container ID |
| Database locked | Close other connections |
| Keychain error | Reset keychain item |

## 📞 Support Contacts

- **Technical Issues**: Development team
- **Legal Questions**: Legal counsel
- **CloudKit Issues**: Apple Developer Support
- **Security Concerns**: Security team

## 🔗 Quick Links

- [Apple Developer Portal](https://developer.apple.com)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
- [TestFlight](https://testflight.apple.com)
- [App Store Connect](https://appstoreconnect.apple.com)

## 📋 Checklist Before Commit

- [ ] Build successful
- [ ] No warnings
- [ ] Tested on device
- [ ] Permissions working
- [ ] CloudKit syncing
- [ ] No debug code
- [ ] Documentation updated
- [ ] No hardcoded values
- [ ] Encryption keys not committed

## 🎯 Performance Targets

- App launch: < 2 seconds
- Auth: < 1 second
- Recording start: < 500ms
- Database query: < 100ms
- CloudKit sync: < 5 seconds
- Photo capture: < 200ms

## 🔢 Version Info

- **Current Version**: 1.0
- **Build**: 1
- **Min iOS**: 17.0
- **Min macOS**: 14.0
- **Swift**: 5.9+
- **Xcode**: 15.0+

---

**Last Updated**: December 12, 2025  
**Status**: Production Ready ✅
