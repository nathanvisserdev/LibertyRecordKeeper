# Liberty Record Keeper

A secure, forensic-grade evidence management application for macOS and iOS that uses industry-standard encryption, biometric authentication, and chain of custody tracking to maintain legally admissible digital records.

## Features

### 🔒 Security
- **Biometric Authentication**: Face ID/Touch ID required for app access
- **AES-256 Encryption**: Database and files encrypted with AES-256-GCM
- **Keychain Integration**: Encryption keys securely stored in iOS/macOS Keychain
- **Chain of Custody**: Every record includes complete audit trail with cryptographic checksums

### 📱 Record Types
1. **Screen Recordings**: Capture and store screen recordings with metadata
2. **Videos**: Record videos with camera including audio
3. **Photos**: Capture photos with detailed metadata
4. **Audio Recordings**: High-quality audio recording with AAC encoding
5. **Screenshots**: Automatic detection and cataloging of screenshots
6. **AI Chat Logs**: Store AI conversation logs (coming soon)

### 🔐 Forensic Integrity
- **SHA-256 Checksums**: Every file is hashed for integrity verification
- **Immutable Metadata**: Capture date, device info, OS version, timezone
- **Chain of Custody Events**: Track creation, viewing, export, sync, and verification
- **Tamper Detection**: Cryptographic signatures ensure data integrity

### ☁️ Cloud Sync
- **iCloud Integration**: Automatic backup to user's private iCloud
- **CloudKit Storage**: Secure cloud storage with end-to-end encryption
- **Cross-Device Sync**: Access records from any authorized device

## Architecture

### MVVM with Service Layer
```
Views → ViewModels → Services → Database/CloudKit
```

### Project Structure
```
LibertyRecordKeeper/
├── Models/              # Data models and forensic records
├── Views/               # SwiftUI views for each tab
├── ViewModels/          # MVVM ViewModels
├── Services/            # Business logic layer
│   ├── DatabaseService.swift
│   ├── CloudKitService.swift
│   ├── BiometricAuthService.swift
│   ├── ScreenRecordingService.swift
│   ├── CameraService.swift
│   ├── AudioRecordingService.swift
│   └── ScreenshotMonitorService.swift
└── Utilities/           # Helper functions
```

## Database Schema

### SQLite Tables
- `screen_recordings` - Screen recording metadata and references
- `videos` - Video capture metadata
- `photos` - Photo metadata
- `audio_recordings` - Audio recording metadata
- `screenshots` - Screenshot metadata
- `ai_chat_logs` - AI conversation logs

Each table includes:
- Unique UUID identifier
- Creation and modification timestamps
- Device identifier
- SHA-256 checksum
- File URL and size
- Forensic metadata (JSON)
- Chain of custody events (JSON)

## Security Implementation

### Encryption Key Management
1. User authenticates with biometrics on app launch
2. Encryption key retrieved from Keychain or generated if new install
3. Database initialized with encryption key
4. All file I/O encrypted/decrypted with AES-256-GCM

### Chain of Custody Events
Every record maintains an immutable audit trail:
- `created` - Initial capture
- `viewed` - Record accessed/viewed
- `exported` - Record exported/shared
- `synced` - Uploaded to cloud
- `verified` - Integrity check performed

## Permissions Required

### iOS
- Camera access
- Microphone access
- Photo library access
- Screen recording (iOS 14+)

### macOS
- Camera access
- Microphone access
- Screen recording
- File system access

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Active iCloud account for sync
- Face ID/Touch ID capable device

## Installation

1. Clone the repository
2. Open `LibertyRecordKeeper.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Configure CloudKit container (automatic with proper team)
5. Build and run on device (biometrics require physical device)

## Usage

### First Launch
1. Authenticate with Face ID/Touch ID
2. Grant camera, microphone, and screen recording permissions
3. App automatically creates encrypted database

### Recording Evidence
1. Select appropriate tab (Screen Recording, Video, Photo, Audio, or Screenshot)
2. Tap record/capture button
3. Record is automatically:
   - Encrypted and saved locally
   - Added to SQLite database with metadata
   - Uploaded to iCloud
   - Assigned SHA-256 checksum
   - Given chain of custody entry

### Viewing Records
- Tap any record to view/play
- View forensic metadata and chain of custody
- Export records while maintaining integrity

## Legal Admissibility

This app is designed to meet industry standards for digital forensic evidence:

✅ **Authentication**: Biometric authentication proves user identity  
✅ **Integrity**: SHA-256 checksums detect tampering  
✅ **Chain of Custody**: Complete audit trail of all access  
✅ **Metadata**: Comprehensive capture details (date, time, device, location)  
✅ **Encryption**: Protects confidentiality while maintaining integrity  
✅ **Immutability**: Write-once records with tamper detection  

**Note**: Consult with legal counsel regarding admissibility requirements in your jurisdiction. This app provides the technical foundation, but legal admissibility depends on proper handling, documentation, and compliance with local laws.

## CloudKit Schema

CloudKit record types created automatically:
- `ScreenRecording`
- `Video`
- `Photo`
- `AudioRecording`
- `Screenshot`
- `AIChatLog`

Each includes all metadata fields and file assets.

## Development Notes

### Testing
- Biometric authentication requires physical device
- Screen recording requires iOS 14+ with user permission
- Screenshot monitoring works differently on iOS vs macOS

### Known Limitations
- iOS screenshot monitoring requires user to manually import from Photos
- Screen recording uses ReplayKit which has system limitations
- Maximum file sizes dependent on device storage and iCloud quota

## Privacy

All data remains private to the user:
- No third-party analytics
- No data collection
- All records stored in user's private iCloud
- Encryption keys never leave device
- Biometric data never accessed (handled by OS)

## License

Copyright © 2025. All rights reserved.

## Support

For issues, questions, or feature requests, please contact the development team.

---

**⚠️ Important**: This application is designed for legitimate forensic evidence collection. Users are responsible for compliance with all applicable laws regarding recording, privacy, and evidence handling in their jurisdiction.
