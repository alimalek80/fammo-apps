# FAMMO - Play Store Release Guide

## 📋 Pre-Release Checklist

### 1. Version Update
Before each release, update the version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # format: major.minor.patch+buildNumber
```
- **Increment build number** for every Play Store upload
- Update version name for user-facing changes

### 2. Signing Configuration
Ensure your signing key is configured:

1. Copy `android/key.properties.example` to `android/key.properties`
2. Fill in your keystore details:
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=YOUR_KEY_ALIAS
   storeFile=/path/to/your/keystore.jks
   ```
3. **NEVER commit `key.properties` to version control!**

### 3. Generate Keystore (First Release Only)
If you don't have a keystore yet:
```bash
keytool -genkey -v -keystore ~/fammo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fammo
```
**⚠️ IMPORTANT: Keep this keystore safe! You'll need it for all future updates.**

---

## 🏗️ Building the Release

### Option 1: Using the Build Script
```bash
chmod +x build_release.sh
./build_release.sh
```

### Option 2: Manual Build
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The app bundle will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 📤 Upload to Play Store

### 1. Access Google Play Console
- Go to: https://play.google.com/console
- Sign in with your developer account

### 2. Create/Select App
- If first release: Create a new app
- If update: Select your existing app

### 3. Store Listing (First Release)
Update your store listing with content from:
- **Title**: `android/fastlane/metadata/android/en-US/title.txt`
- **Short Description**: `android/fastlane/metadata/android/en-US/short_description.txt`
- **Full Description**: `android/fastlane/metadata/android/en-US/full_description.txt`

Repeat for other languages:
- Turkish (tr-TR)
- Finnish (fi-FI)
- Dutch (nl-NL)

### 4. Graphics Assets
Upload screenshots from `/screenshots/` folder:
- Phone screenshots (at least 2)
- Tablet screenshots (optional)
- Feature graphic (1024x500)
- App icon (512x512)

### 5. Create Release
1. Go to **Release** > **Production** (or Testing track)
2. Click **Create new release**
3. Upload the `.aab` file
4. Add release notes from changelog:
   - `android/fastlane/metadata/android/en-US/changelogs/1.txt`
5. Review and roll out

---

## 📝 Store Listing Content

### App Information
| Field | Value |
|-------|-------|
| **App Name** | FAMMO - AI Pet Care |
| **Category** | Health & Fitness |
| **Content Rating** | Everyone |
| **Package Name** | ai.fammo.app |

### Contact Information
| Field | Value |
|-------|-------|
| **Email** | support@fammo.ai |
| **Website** | https://fammo.ai |
| **Privacy Policy** | https://fammo.ai/privacy |

### Target Audience
- Ages: 13+
- No ads
- No in-app purchases (initial release)

---

## 🌍 Supported Languages
| Language | Code | Status |
|----------|------|--------|
| English | en-US | ✅ Default |
| Turkish | tr-TR | ✅ Complete |
| Finnish | fi-FI | ✅ Complete |
| Dutch | nl-NL | ✅ Complete |

---

## 📱 App Requirements

### Minimum Requirements
- **Android**: 5.0 (API 21) and above
- **Target SDK**: Latest stable

### Permissions Required
- Internet access
- Location (for nearby clinics)
- Camera (for pet photos)
- Storage (for saving photos)
- Biometrics (for secure login)

---

## 🔄 Release History

### Version 1.0.0 (Build 1) - Initial Release
**Release Date:** January 2026

**Features:**
- Pet management with detailed profiles
- AI-powered nutrition plans
- AI health reports and recommendations
- Veterinary clinic discovery and search
- Clinic registration for veterinarians
- Multi-language support (4 languages)
- Biometric authentication
- Beautiful UI with dark/light mode

---

## ⚠️ Important Notes

1. **Keystore Backup**: Store your keystore file and passwords securely
2. **Version Numbers**: Always increment build number before upload
3. **Review Time**: Initial review may take several days
4. **App Signing**: Consider enrolling in Google Play App Signing

---

## 🆘 Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### Signing Issues
- Verify `key.properties` file exists
- Check keystore path is correct
- Ensure passwords match

### Upload Errors
- Check bundle size limits
- Verify package name matches Play Console
- Ensure version code is higher than previous release

---

## 📞 Support

For technical issues:
- Email: support@fammo.ai
- Website: https://fammo.ai
