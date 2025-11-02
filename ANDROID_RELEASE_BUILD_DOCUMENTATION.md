# Digital Twin Fashion - Android Release Build Documentation

## Overview

This document provides comprehensive instructions for building, testing, and deploying the Digital Twin Fashion app to Google Play Store.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Build Configuration](#build-configuration)
3. [Signing Setup](#signing-setup)
4. [Build Process](#build-process)
5. [Testing & Quality Assurance](#testing--quality-assurance)
6. [Deployment](#deployment)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

1. **Flutter SDK 3.16.0 or later**
   ```bash
   flutter --version
   flutter doctor
   ```

2. **Android SDK**
   - API Level 34 (Android 14)
   - Build Tools 34.0.0
   - Platform Tools
   - Android Emulator (for testing)

3. **Java Development Kit**
   - JDK 17 or later

4. **Git**
   - For version control

### Environment Setup

```bash
# Set environment variables
export ANDROID_HOME=/path/to/android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

## Build Configuration

### 1. Build Types

The app supports three build types:

- **Debug**: For development and testing
- **Profile**: For performance testing
- **Release**: For production deployment

### 2. Build Features

- **Code Obfuscation**: R8/ProGuard enabled for release builds
- **Resource Shrinking**: Reduces APK size
- **Architecture Support**: ARM64, ARMv7, x86_64
- **Multi-Dex**: Supports large applications
- **Vector Drawables**: Optimized graphics

### 3. Build Optimization

```gradle
buildTypes {
    release {
        debuggable false
        minifyEnabled true
        shrinkResources true
        zipAlignEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

## Signing Setup

### 1. Generate Keystore

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Configure Signing

1. Copy `keystore.properties.template` to `keystore.properties`
2. Update with your keystore details:

```properties
MYAPP_UPLOAD_STORE_FILE=upload-keystore.jks
MYAPP_UPLOAD_STORE_PASSWORD=your_password
MYAPP_UPLOAD_KEY_ALIAS=upload
MYAPP_UPLOAD_KEY_PASSWORD=your_key_password
```

### 3. Secure Keystore

- Store keystore in secure location
- Never commit to version control
- Backup keystore securely
- Share passwords securely with team

## Build Process

### 1. Automated Build Script

Use the provided build script for automated builds:

```bash
./build_release.sh
```

This script:
- Checks prerequisites
- Cleans previous builds
- Analyzes code
- Runs tests
- Builds APK and AAB
- Validates output
- Generates build information

### 2. Manual Build Commands

#### Debug Build
```bash
flutter build apk --debug
```

#### Release Build
```bash
flutter build apk --release
flutter build appbundle --release
```

#### Performance Testing
```bash
flutter build apk --profile
```

### 3. Build Output

After successful build:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- Build info: `releases/build-info.json`

## Testing & Quality Assurance

### 1. Automated Tests

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### 2. Manual Testing

#### Device Testing
- Test on multiple Android devices
- Verify camera functionality
- Test 3D model viewer
- Validate payment integration
- Check network connectivity

#### Performance Testing
- Cold start time
- Memory usage
- CPU usage
- Battery consumption

### 3. Quality Assurance Script

Run comprehensive QA testing:

```bash
./qa_test.sh
```

This validates:
- Code quality
- Performance metrics
- Security compliance
- Accessibility standards
- Google Play requirements

## Deployment

### 1. Google Play Console Setup

1. **Create Play Console Account**
   - Developer account registration
   - One-time registration fee

2. **Create App Listing**
   - App name: "Digital Twin Fashion"
   - Description and metadata
   - Screenshots and graphics
   - Privacy policy

3. **Configure Store Listing**
   - App category: Lifestyle
   - Content rating
   - Distribution settings

### 2. Upload Process

#### Option A: Manual Upload
1. Log into Google Play Console
2. Create new app
3. Upload AAB file
4. Complete store listing
5. Submit for review

#### Option B: Automated Upload
```bash
python scripts/upload_to_play_store.py
```

### 3. Release Management

#### Internal Testing
- Upload to internal testing track
- Distribute to QA team
- Gather feedback

#### Alpha/Beta Testing
- Staged rollout to beta users
- Monitor crash reports
- Collect user feedback

#### Production Release
- Gradual rollout (5%, 10%, 20%, 50%, 100%)
- Monitor metrics and reviews
- Prepare rollback if needed

## CI/CD Pipeline

### 1. GitHub Actions

The project includes a comprehensive CI/CD pipeline:

```yaml
name: Android Release Build
on:
  push:
    tags: ['v*']
  workflow_dispatch:
```

Pipeline stages:
1. **Analyze & Test**
   - Code analysis
   - Unit tests
   - Formatting checks

2. **Build Android**
   - Release APK build
   - App Bundle generation
   - Artifact upload

3. **Upload to Play Store**
   - Automatic upload on tagged releases
   - Manual trigger option

### 2. Environment Secrets

Configure these secrets in GitHub repository:

- `KEYSTORE_FILE`: Base64 encoded keystore
- `KEYSTORE_PASSWORD`: Keystore password
- `KEY_ALIAS`: Key alias
- `KEY_PASSWORD`: Key password
- `PLAY_CONSOLE_SERVICE_ACCOUNT`: Service account JSON

### 3. Automated Workflow

```bash
# Trigger release build
git tag v1.0.0
git push origin v1.0.0

# This will:
# 1. Run all tests
# 2. Build release APK/AAB
# 3. Upload to Google Play Console
# 4. Send notification
```

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Issue**: Flutter build fails
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
```

**Issue**: ProGuard errors
- Check proguard-rules.pro
- Add missing keep rules
- Verify dependencies

#### 2. Signing Issues

**Issue**: Keystore not found
- Check keystore.properties file path
- Verify keystore file exists
- Check permissions

**Issue**: Wrong keystore password
- Re-enter correct passwords
- Reset keystore if needed

#### 3. Play Store Upload Errors

**Issue**: AAB validation failed
- Check target SDK version
- Verify app bundle size
- Validate permissions

**Issue**: API level requirements
- Update target SDK to 34+
- Check minimum SDK version
- Update dependencies

### Build Optimization

#### Reduce APK Size
1. Enable R8 code shrinking
2. Remove unused resources
3. Optimize images
4. Use App Bundle instead of APK

#### Improve Build Speed
1. Enable Gradle daemon
2. Use build cache
3. Parallel builds
4. Optimize dependencies

## Security Checklist

- [ ] Code obfuscation enabled
- [ ] No hardcoded secrets
- [ ] Network security configured
- [ ] Proper certificate validation
- [ ] Input validation implemented
- [ ] Secure storage for sensitive data
- [ ] Privacy policy updated
- [ ] Permissions properly declared

## Performance Checklist

- [ ] Cold start time < 3 seconds
- [ ] Memory usage < 150MB
- [ ] Battery efficient
- [ ] Network optimized
- [ ] 60fps animations
- [ ] Smooth scrolling
- [ ] Fast image loading

## Google Play Checklist

- [ ] Target API level 34+
- [ ] 64-bit architecture support
- [ ] App bundle under 150MB
- [ ] Adaptive icon configured
- [ ] Proper permissions
- [ ] Privacy policy URL
- [ ] Store listing complete
- [ ] Screenshots and graphics
- [ ] App description
- [ ] Content rating

## Support

For issues or questions:
1. Check this documentation
2. Review build logs
3. Search Flutter/Android documentation
4. Contact development team

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-02 | Initial release build setup |
| | | Added ProGuard/R8 configuration |
| | | Created automated build scripts |
| | | Implemented CI/CD pipeline |
| | | Added quality assurance testing |
| | | Set up Google Play deployment |

---

**Last Updated**: 2025-11-02
**Document Version**: 1.0