# Contributor Guidelines

This repository is an iOS app written in SwiftUI. It uses CocoaPods and Fastlane for dependency and build management. The project depends on MobileVLCKit (the VLCKit CocoaPods distribution) for media playback.

## Setup

1. Install Ruby gems with `bundle install`.
2. Install iOS dependencies with `pod install` and open `swiftchan.xcworkspace`.
3. SwiftLint is included via CocoaPods. Run `Pods/SwiftLint/swiftlint autocorrect && Pods/SwiftLint/swiftlint` before committing.
4. Tests can be executed with `bundle exec fastlane tests` (requires macOS/Xcode). If Xcode isn't available, mention this in your PR summary.

## Contribution

- Follow the style enforced by SwiftLint and the existing `.swiftlint.yml` file.
- Ensure builds succeed and existing tests pass after your changes.
- MobileVLCKit is referenced from the Podfile; consult VLCKit documentation when modifying video playback logic.
- Use Pull Requests for changes. Keep commit messages concise.
