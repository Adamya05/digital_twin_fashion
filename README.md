# Digital Twin Fashion App

A Flutter application for digital twin fashion with advanced features including camera integration, 3D model viewing, and payment processing.

## Features

- 🖼️ **Camera Integration** - Capture and process fashion images
- 🎭 **3D Model Viewer** - View 3D fashion models using Model Viewer Plus
- 💳 **Payment Integration** - Razorpay payment gateway support
- 📱 **Modern UI** - Card swiper interface with Material 3 design
- 🎬 **Media Processing** - FFmpeg integration for video/image processing
- 📦 **State Management** - Riverpod for robust state management

## Dependencies

- `flutter_riverpod` - State management
- `camera` - Camera functionality
- `model_viewer_plus` - 3D model viewing
- `flutter_card_swiper` - Card interface
- `razorpay_flutter` - Payment processing
- `ffmpeg_kit_flutter` - Media processing
- `http` - Network requests
- `shared_preferences` - Local storage

## Project Structure

```
digital_twin_fashion/
├── android/                 # Android-specific configuration
│   ├── app/
│   │   ├── build.gradle    # Android build configuration
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/     # Kotlin source files
├── lib/                     # Flutter source code
│   └── main.dart           # App entry point
├── assets/                  # App assets
│   ├── images/             # Image resources
│   ├── models/             # 3D model files
│   └── fonts/              # Custom fonts
├── test/                    # Test files
├── ios/                     # iOS-specific configuration
└── pubspec.yaml            # Project dependencies
```

## Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Check Flutter Setup**
   ```bash
   flutter doctor
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

## Android Configuration

### Permissions
The app requires the following permissions:
- `CAMERA` - For capturing photos
- `WRITE_EXTERNAL_STORAGE` - For saving images
- `READ_EXTERNAL_STORAGE` - For accessing photos
- `INTERNET` - For network requests

### Hardware Requirements
- Camera support (required)
- Autofocus (optional)

## iOS Configuration

### Permissions
- `NSCameraUsageDescription` - Camera access
- `NSPhotoLibraryUsageDescription` - Photo library access
- `NSMicrophoneUsageDescription` - Microphone access

## Development Notes

- The app uses Material 3 design system
- Riverpod is used for state management
- All dependencies use latest stable versions
- The project is configured for both Android and iOS platforms

## Build Commands

- **Debug Build**: `flutter run`
- **Release Build**: `flutter build apk` (Android) or `flutter build ios`
- **Test**: `flutter test`
- **Code Analysis**: `flutter analyze`