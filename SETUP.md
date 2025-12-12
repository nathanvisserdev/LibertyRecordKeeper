# Liberty Record Keeper - Setup Guide

## Prerequisites

Before building and running the app, ensure you have:

1. **macOS Ventura (13.0) or later**
2. **Xcode 15.0 or later**
3. **Apple Developer Account** (for code signing and CloudKit)
4. **Physical iOS/macOS device** (for biometric authentication testing)

## Step-by-Step Setup

### 1. Xcode Configuration

1. Open `LibertyRecordKeeper.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to "Signing & Capabilities"
4. Select your development team from the dropdown
5. Xcode will automatically configure:
   - Bundle Identifier
   - Provisioning Profile
   - Code Signing Certificate

### 2. CloudKit Setup

CloudKit will be configured automatically when you select your team, but verify:

1. In "Signing & Capabilities", check that "iCloud" capability is enabled
2. CloudKit container should show: `iCloud.$(CFBundleIdentifier)`
3. If needed, click "+" and add "iCloud" capability
4. Ensure "CloudKit" is checked under Services

### 3. Entitlements Verification

The `.entitlements` file should include:
- ✅ iCloud (CloudKit)
- ✅ Camera access
- ✅ Microphone access
- ✅ Photo Library access
- ✅ App Sandbox (macOS)
- ✅ Network Client

### 4. Build Settings

No changes needed - defaults are configured correctly.

### 5. First Build

```bash
# Clean build folder (if needed)
Product → Clean Build Folder (⇧⌘K)

# Build the project
Product → Build (⌘B)
```

### 6. Running on Device

**Important**: Biometric authentication requires a physical device.

#### iOS Device:
1. Connect iPhone/iPad via USB
2. Select device from the device dropdown
3. Click Run (⌘R)
4. On first run, iOS may prompt "Untrusted Developer"
   - Settings → General → VPN & Device Management
   - Trust your developer certificate

#### macOS:
1. Select "My Mac" from device dropdown
2. Click Run (⌘R)
3. Grant permissions when prompted

### 7. Permissions on First Launch

The app will request:
1. **Face ID / Touch ID** - Required for authentication
2. **Camera** - For photos and videos
3. **Microphone** - For audio and video recording
4. **Screen Recording** - For screen recordings (iOS 14+, macOS)
5. **Photo Library** - For screenshot monitoring

Grant all permissions for full functionality.

## Troubleshooting

### Build Errors

**Error: "No such module 'SQLite3'"**
- This shouldn't occur as SQLite3 is built into iOS/macOS
- If it does: Add `libsqlite3.tbd` to "Frameworks and Libraries"

**Error: "Failed to register bundle identifier"**
- Your bundle ID may be taken
- Change it in: Target → General → Bundle Identifier

**Error: CloudKit entitlement issue**
- Ensure you've selected a valid development team
- Check that iCloud is enabled in Capabilities
- May need to manually configure CloudKit container in Apple Developer portal

### Runtime Errors

**Biometric authentication fails:**
- Ensure device has Face ID/Touch ID enabled
- Simulator won't work - use physical device
- Check device Settings → Face ID & Passcode

**Camera/Microphone not working:**
- Grant permissions in Settings
- iOS: Settings → Privacy & Security → Camera/Microphone
- macOS: System Settings → Privacy & Security → Camera/Microphone

**Screen recording fails:**
- iOS: Settings → Control Center → Add Screen Recording
- macOS: System Settings → Privacy & Security → Screen Recording
- Grant permission to the app

**Database errors:**
- Clear app data and reinstall
- Check file permissions in app sandbox

## Development Tips

### Testing Without Physical Device

Some features can be tested in Simulator:
- ✅ UI and navigation
- ✅ Database operations
- ❌ Biometric authentication (requires bypass)
- ❌ Camera/recording
- ❌ CloudKit sync (limited)

To bypass biometric auth for testing:
1. Comment out authentication check in `LibertyRecordKeeperApp.swift`
2. Generate test encryption key
3. **Remember to re-enable for production!**

### Debugging

Enable debug logging:
```swift
// Add to each service
#if DEBUG
print("[ServiceName] Debug message")
#endif
```

View SQLite database:
```bash
# Find app documents directory
xcrun simctl get_app_container booted com.yourteam.LibertyRecordKeeper data

# Open database
sqlite3 Documents/forensic_records.db
```

### Performance

- **Large files**: Videos/recordings can be large, test with limited storage
- **CloudKit**: Has upload size limits (1MB asset size for free tier)
- **Encryption**: Real-time encryption may impact performance on older devices

## CloudKit Dashboard

Monitor your CloudKit data:

1. Visit [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your app's container
3. View schema and records
4. Query and debug data

Record types created automatically:
- ScreenRecording
- Video
- Photo
- AudioRecording
- Screenshot
- AIChatLog

## Deployment Checklist

Before submitting to App Store:

- [ ] Update version numbers
- [ ] Remove debug code
- [ ] Test on multiple devices
- [ ] Verify all permissions descriptions
- [ ] Test CloudKit in production environment
- [ ] Create App Store screenshots
- [ ] Prepare privacy policy
- [ ] Review legal requirements for your jurisdiction

## Support Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [ReplayKit Documentation](https://developer.apple.com/documentation/replaykit)
- [AVFoundation Documentation](https://developer.apple.com/documentation/avfoundation)

## Common Use Cases

### Adding New Record Type

1. Create new struct conforming to `ForensicRecord` in `Models/ForensicRecord.swift`
2. Add database table in `DatabaseService.swift`
3. Add save/fetch methods in `DatabaseService.swift`
4. Add upload method in `CloudKitService.swift`
5. Create ViewModel in `ViewModels/`
6. Create View in `Views/`
7. Add to TabView in `ContentView.swift`

### Customizing Forensic Metadata

Edit `ForensicMetadata` struct in `Models/ForensicRecord.swift`:
- Add location tracking
- Add network information
- Add custom device details
- Add compliance certifications

### Export Functionality

To add export with maintained chain of custody:
1. Add export method to ViewModels
2. Update chain of custody with export event
3. Export as encrypted archive with metadata
4. Include verification instructions

## Security Best Practices

1. **Never commit encryption keys**
2. **Use strong biometric policies**
3. **Rotate CloudKit credentials regularly**
4. **Audit chain of custody regularly**
5. **Test integrity verification**
6. **Backup encryption keys securely**
7. **Document all modifications**

## Legal Compliance

Consult legal counsel regarding:
- Recording consent laws
- Privacy regulations (GDPR, CCPA, etc.)
- Evidence handling procedures
- Data retention policies
- Cross-border data transfer
- Industry-specific regulations

---

**Need Help?** Contact the development team or file an issue.
