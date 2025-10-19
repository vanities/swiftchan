# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Swiftchan is an open-source iOS imageboard app written in SwiftUI using MVVM architecture. The app provides native webm and gif playback support through MobileVLCKit and is distributed via TestFlight.

## Development Commands

### Setup and Dependencies
```bash
# Install Ruby dependencies for build tools
bundle install

# Install iOS dependencies (CocoaPods)
pod install

# Open the project - ALWAYS use the workspace file
open swiftchan.xcworkspace
```

### Building and Testing
```bash
# Run tests via Fastlane
bundle exec fastlane tests

# Build and deploy to TestFlight
bundle exec fastlane beta

# Build directly with xcodebuild
xcodebuild -workspace swiftchan.xcworkspace -scheme swiftchan -configuration Debug build
```

### Code Quality
```bash
# Run SwiftLint (auto-correct and check)
Pods/SwiftLint/swiftlint autocorrect && Pods/SwiftLint/swiftlint

# SwiftLint is configured in .swiftlint.yml with:
# - Line length: 1000
# - Type/identifier names: min length 1
# - Disabled: shorthand_operator
```

### Certificate Management
```bash
# Renew certificates (requires proper auth)
make renew_certs

# Get certificates
make get_certs
```

## Architecture

### Core Structure
- **Main Entry**: `swiftchan/swiftchanApp.swift` - SwiftUI app entry point with cache cleanup on launch
- **Navigation**: `swiftchan/Views/ContentView.swift` - Tab-based navigation with biometric authentication
- **State Management**: `swiftchan/Environment/AppState.swift` - Observable app-wide state using Swift's @Observable macro
- **API Layer**: `swiftchan/Services/FourchanService.swift` - Async/await based API service using FourChanAPI package

### Key Architectural Patterns

1. **MVVM Pattern**: ViewModels (`swiftchan/ViewModels/`) manage business logic and state for views
   - `BoardsViewModel` - Manages board listing with async loading
   - `CatalogViewModel` - Handles catalog/thread browsing
   - `ThreadViewModel` - Thread display and auto-refresh logic
   - `VLCVideoViewModel` - Video playback state management

2. **Media Handling**: Complex media system for images, GIFs, and webm videos
   - Native webm support via MobileVLCKit (CocoaPod dependency)
   - Image caching with Kingfisher (Swift Package)
   - Custom VLC integration in `swiftchan/Views/Media/VLC/`

3. **Service Layer** (`swiftchan/Services/`):
   - `CacheService` - Media and data caching
   - `CommentParser` - Parses imageboard markup
   - `Prefetcher` / `VideoPrefetcher` - Preloads media content
   - `DeepLinker` - URL scheme handling

4. **View Organization**:
   - `Boards/` - Board selection and catalog browsing
   - `Media/` - Image, GIF, and video viewing components
   - `Utility/` - Reusable UI components (Toast, Blur, Privacy)

### Dependencies

**CocoaPods** (Podfile):
- MobileVLCKit - Video playback
- SwiftLint - Code linting

**Swift Package Manager** (via Xcode project):
- FourChan API - Custom fork at https://github.com/vanities/FourChanAPI.git
- Kingfisher - Image caching
- ToastUI - Toast notifications
- Defaults - User preferences
- SwiftUI-Introspect - SwiftUI introspection
- ConfettiSwiftUI - Visual effects

### Testing Strategy
- Unit tests in `swiftchanTests/`
- UI tests in `swiftchanUITests/`
- Test via Fastlane: `bundle exec fastlane tests`
- Tests run on iPhone 14 simulator by default
- Performance tests can be skipped in CI

### Build & Deployment
- Fastlane manages TestFlight deployments
- GitHub Actions CI on pull requests (.github/workflows/build_and_test.yml)
- Automatic version bumping on beta releases
- Certificates managed via Fastlane match

## Important Notes

- ALWAYS use `swiftchan.xcworkspace`, not the `.xcodeproj` file
- Run SwiftLint before committing changes
- The app requires iOS 15.0 minimum
- Biometric authentication is integrated throughout the app
- Media URLs are constructed using the FourChan API package
- VLC integration requires careful handling of the MobileVLCKit pod
