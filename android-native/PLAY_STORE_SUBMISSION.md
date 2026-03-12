# Play Store Submission Guide

## Prerequisites

1. **Google Play Developer Account** - https://play.google.com/console ($25 one-time fee)
2. **Signing Keystore** - Generate once and keep safe forever

## Step 1: Generate Release Keystore

```bash
cd android-native

# Generate keystore (SAVE THE PASSWORDS!)
keytool -genkey -v -keystore openflix-release.keystore \
  -alias openflix \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

When prompted:
- **Keystore password**: Choose a strong password
- **Key password**: Can be the same as keystore password
- **First and last name**: Your name or company name
- **Organization**: Your company/organization
- **City, State, Country**: Your location

**IMPORTANT**: Back up `openflix-release.keystore` and passwords securely. If lost, you cannot update the app!

## Step 2: Configure Signing

```bash
# Copy template
cp keystore.properties.template keystore.properties

# Edit with your passwords
nano keystore.properties
```

Update `keystore.properties`:
```properties
storeFile=../openflix-release.keystore
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=openflix
keyPassword=YOUR_KEY_PASSWORD
```

## Step 3: Build Release Bundle

```bash
# Build Android App Bundle (AAB) - required for Play Store
./gradlew bundleRelease

# Output: app/build/outputs/bundle/release/app-release.aab
```

## Step 4: Create Play Store Listing

### Required Graphics

| Asset | Size | Format |
|-------|------|--------|
| App Icon | 512x512 | PNG (32-bit, no alpha) |
| Feature Graphic | 1024x500 | PNG or JPG |
| TV Banner | 1280x720 | PNG or JPG |
| TV Screenshots | 1920x1080 | PNG or JPG (min 4) |

### Store Listing Text

Already created in `fastlane/metadata/android/en-US/`:
- `title.txt` - App name (30 chars max)
- `short_description.txt` - Tagline (80 chars max)
- `full_description.txt` - Full description (4000 chars max)

## Step 5: Play Console Setup

1. Go to https://play.google.com/console
2. Click "Create app"
3. Fill in:
   - **App name**: OpenFlix - Media Server & DVR
   - **Default language**: English (US)
   - **App or game**: App
   - **Free or paid**: Free

4. Complete the app content sections:
   - **Privacy policy**: https://raw.githubusercontent.com/jorge123255/OpenFlix/main/PRIVACY.md
   - **App access**: All functionality available without restrictions
   - **Ads**: No ads
   - **Content rating**: Complete questionnaire
   - **Target audience**: Not designed for children
   - **News app**: No
   - **COVID-19 apps**: No
   - **Data safety**: Fill based on PRIVACY.md

5. Set up store listing:
   - Upload graphics
   - Copy text from fastlane metadata files
   - Select category: **Video Players & Editors** or **Entertainment**
   - Add tags: media server, streaming, IPTV, DVR, movies

6. Upload AAB:
   - Go to "Release" > "Production"
   - Create new release
   - Upload `app-release.aab`
   - Add release notes from `changelogs/1.txt`

7. Submit for review

## Step 6: Content Rating

Answer the questionnaire:
- **Violence**: None
- **Sexual content**: None
- **Language**: None
- **Controlled substances**: None
- **Gambling**: None

Result should be: **PEGI 3** / **Everyone**

## Updating the App

1. Increment version in `app/build.gradle.kts`:
   ```kotlin
   versionCode = 2  // Increment this
   versionName = "1.1.0"
   ```

2. Build new AAB:
   ```bash
   ./gradlew bundleRelease
   ```

3. Upload to Play Console and submit

## Troubleshooting

### "App not signed correctly"
- Ensure `keystore.properties` has correct paths and passwords
- Verify keystore file exists at the specified path

### "APK/AAB not found"
- Run `./gradlew clean bundleRelease`
- Check `app/build/outputs/bundle/release/`

### "Deobfuscation file missing" warning
- Optional: Upload `mapping.txt` from `app/build/outputs/mapping/release/`
- Helps with crash reports

## Files to Keep Safe

- `openflix-release.keystore` - **CRITICAL** - Cannot update app if lost
- `keystore.properties` - Contains passwords (in .gitignore)
- Play Console credentials
