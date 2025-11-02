#!/bin/bash

# Digital Twin Fashion - Quick Release Commands
# One-stop shop for all release-related tasks

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        print_success "Flutter is installed: $(flutter --version | head -1)"
    else
        print_warning "Flutter not found - please install Flutter SDK"
        return 1
    fi
    
    # Check Android SDK
    if [[ -n "$ANDROID_HOME" ]]; then
        print_success "Android SDK configured: $ANDROID_HOME"
    else
        print_warning "ANDROID_HOME not set - please configure Android SDK"
    fi
    
    # Check Java
    if command -v java &> /dev/null; then
        print_success "Java is installed: $(java -version 2>&1 | head -1)"
    else
        print_warning "Java not found - please install Java 17+"
    fi
    
    print_success "Prerequisites check complete"
}

setup_keystore() {
    print_header "Setting Up Keystore"
    
    KEYSTORE_FILE="android/app/upload-keystore.jks"
    
    if [[ -f "$KEYSTORE_FILE" ]]; then
        print_info "Keystore already exists at $KEYSTORE_FILE"
        return 0
    fi
    
    print_info "Generating new keystore..."
    keytool -genkey -v \
            -keystore "$KEYSTORE_FILE" \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -alias upload \
            -dname "CN=Digital Twin Fashion, OU=Development, O=Company, L=City, S=State, C=US" \
            -storepass android123 \
            -keypass android123
    
    print_success "Keystore generated successfully"
    print_warning "Please secure the keystore and update keystore.properties"
    
    # Create keystore.properties template
    cat > android/keystore.properties << EOF
MYAPP_UPLOAD_STORE_FILE=upload-keystore.jks
MYAPP_UPLOAD_STORE_PASSWORD=android123
MYAPP_UPLOAD_KEY_ALIAS=upload
MYAPP_UPLOAD_KEY_PASSWORD=android123
EOF
    
    print_success "keystore.properties created"
}

update_app_metadata() {
    print_header "Update App Metadata"
    
    print_info "Current version: $(grep 'version:' pubspec.yaml | head -1 | sed 's/version: //')"
    print_info "Please update version in pubspec.yaml"
    
    read -p "Enter new version (e.g., 1.0.0+1): " NEW_VERSION
    if [[ -n "$NEW_VERSION" ]]; then
        sed -i.bak "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
        print_success "Version updated to: $NEW_VERSION"
    fi
}

clean_project() {
    print_header "Cleaning Project"
    
    print_info "Running flutter clean..."
    flutter clean
    
    print_info "Cleaning Android build..."
    cd android && ./gradlew clean && cd ..
    
    print_info "Getting dependencies..."
    flutter pub get
    
    print_success "Project cleaned and dependencies updated"
}

run_tests() {
    print_header "Running Tests"
    
    print_info "Running dart analyze..."
    flutter analyze --no-fatal-infos
    
    print_info "Running unit tests..."
    flutter test
    
    print_success "Tests completed"
}

build_release() {
    print_header "Building Release APK"
    
    print_info "Building APK..."
    flutter build apk --release
    
    print_info "Building App Bundle..."
    flutter build appbundle --release
    
    print_success "Builds completed successfully"
    
    # Display sizes
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk 2>/dev/null | cut -f1 || echo "N/A")
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab 2>/dev/null | cut -f1 || echo "N/A")
    
    print_info "APK Size: $APK_SIZE"
    print_info "AAB Size: $AAB_SIZE"
    
    # Copy to releases directory
    mkdir -p releases
    cp build/app/outputs/flutter-apk/app-release.apk releases/
    cp build/app/outputs/bundle/release/app-release.aab releases/
    
    print_success "Build artifacts copied to releases/ directory"
}

generate_build_info() {
    print_header "Generating Build Information"
    
    BUILD_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    cat > releases/build-info.json << EOF
{
    "app_name": "Digital Twin Fashion",
    "build_time": "$BUILD_TIME",
    "git_commit": "$GIT_COMMIT",
    "version": "$(grep 'version:' pubspec.yaml | head -1 | sed 's/version: //')",
    "flutter_version": "$(flutter --version | head -1)",
    "build_type": "release"
}
EOF
    
    print_success "Build info generated at releases/build-info.json"
}

run_qa_check() {
    print_header "Running QA Checks"
    
    # Check APK structure
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    if [[ -f "$APK_PATH" ]]; then
        print_info "Validating APK structure..."
        if aapt dump badging "$APK_PATH" &> /dev/null; then
            print_success "APK structure is valid"
        else
            print_warning "APK structure validation failed"
        fi
    fi
    
    # Check for common issues
    print_info "Scanning for common issues..."
    
    # Check for hardcoded secrets
    if grep -r "API_KEY\|SECRET\|PASSWORD\|TOKEN" lib/ \
         --exclude-dir=build --exclude-dir=.git 2>/dev/null; then
        print_warning "Potential hardcoded secrets found"
    else
        print_success "No hardcoded secrets detected"
    fi
    
    print_success "QA checks completed"
}

upload_to_play() {
    print_header "Upload to Google Play"
    
    if [[ ! -f "releases/digital-twin-fashion-release.aab" ]]; then
        print_error "AAB file not found. Please run build_release first."
        return 1
    fi
    
    if [[ ! -f "service-account.json" ]]; then
        print_error "Service account file not found. Please setup Google Play credentials."
        return 1
    fi
    
    print_info "Uploading to Google Play Console..."
    python scripts/upload_to_play_store.py
    
    print_success "Upload initiated"
}

show_menu() {
    print_header "Digital Twin Fashion - Release Tools"
    echo ""
    echo "Select an option:"
    echo "1) Check prerequisites"
    echo "2) Setup keystore"
    echo "3) Update app metadata"
    echo "4) Clean project"
    echo "5) Run tests"
    echo "6) Build release (APK + AAB)"
    echo "7) Generate build info"
    echo "8) Run QA checks"
    echo "9) Upload to Google Play"
    echo "10) Full release build"
    echo "11) View documentation"
    echo "12) Exit"
    echo ""
}

run_full_release() {
    print_header "Full Release Build Process"
    
    echo "This will run the complete release build process:"
    echo "1. Check prerequisites"
    echo "2. Clean project"
    echo "3. Run tests"
    echo "4. Build release APK and AAB"
    echo "5. Generate build information"
    echo "6. Run QA checks"
    echo ""
    
    read -p "Continue? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        return 0
    fi
    
    check_prerequisites || exit 1
    clean_project
    run_tests
    build_release
    generate_build_info
    run_qa_check
    
    print_success "Full release build completed!"
    print_info "Artifacts available in releases/ directory"
}

show_documentation() {
    print_header "Documentation"
    echo ""
    echo "Available documentation:"
    echo ""
    echo "📄 RELEASE_BUILD_SUMMARY.md"
    echo "   Complete overview of release build setup"
    echo ""
    echo "📄 ANDROID_RELEASE_BUILD_DOCUMENTATION.md"
    echo "   Detailed build and deployment guide"
    echo ""
    echo "📄 releases/deployment-checklist.md"
    echo "   Pre-release checklist and sign-offs"
    echo ""
    echo "📄 build_release.sh"
    echo "   Automated release build script"
    echo ""
    echo "📄 qa_test.sh"
    echo "   Quality assurance testing script"
    echo ""
}

# Main menu loop
main() {
    cd "$(dirname "$0")"
    
    while true; do
        show_menu
        read -p "Enter your choice (1-12): " choice
        echo ""
        
        case $choice in
            1)
                check_prerequisites
                ;;
            2)
                setup_keystore
                ;;
            3)
                update_app_metadata
                ;;
            4)
                clean_project
                ;;
            5)
                run_tests
                ;;
            6)
                build_release
                ;;
            7)
                generate_build_info
                ;;
            8)
                run_qa_check
                ;;
            9)
                upload_to_play
                ;;
            10)
                run_full_release
                ;;
            11)
                show_documentation
                ;;
            12)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi