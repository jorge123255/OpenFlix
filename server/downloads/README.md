# OpenFlix App Downloads

Place built app files here for distribution through the server.

## Supported File Types

| Extension | Platform | Description |
|-----------|----------|-------------|
| `.apk` | Android/Android TV | Android package |
| `.ipa` | iOS/tvOS | iOS app archive |
| `.dmg` | macOS | Mac disk image |
| `.exe`/`.msi` | Windows | Windows installer |
| `.deb`/`.AppImage` | Linux | Linux package |

## File Naming Convention

Use this format for automatic version detection:
```
OpenFlix-{platform}-{version}.{ext}
```

Examples:
- `OpenFlix-AndroidTV-1.0.0.apk`
- `OpenFlix-tvOS-1.0.0.ipa`

## Building the Apps

### Android TV APK

```bash
cd android-native
./gradlew assembleRelease
# APK at: app/build/outputs/apk/release/app-release.apk
cp app/build/outputs/apk/release/app-release.apk ../server/downloads/OpenFlix-AndroidTV-1.0.0.apk
```

### tvOS IPA

Requires Xcode and Apple Developer account:
```bash
cd OpenFlix-tvOS
xcodebuild -scheme OpenFlix-tvOS -configuration Release -archivePath build/OpenFlix.xcarchive archive
xcodebuild -exportArchive -archivePath build/OpenFlix.xcarchive -exportPath build/ -exportOptionsPlist ExportOptions.plist
cp build/OpenFlix-tvOS.ipa ../server/downloads/OpenFlix-tvOS-1.0.0.ipa
```

## API Endpoints

- `GET /downloads` - List available downloads
- `GET /downloads/:filename` - Download specific file

Files placed here will automatically appear in the server's download section.
