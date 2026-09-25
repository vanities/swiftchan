# Contributor Guidelines

`CLAUDE.md` is a compatibility symlink to this file.

Swiftchan is a SwiftUI imageboard app using MVVM, SwiftData, and Swift Package Manager. The app requires iOS 18.0 or later. Video playback uses KSPlayer and FFmpegKit; CocoaPods and MobileVLCKit are no longer used.

## Setup and validation

- Use Xcode 26.6 (CI uses this version); updated packages require at least Swift 6.2 / Xcode 26.
- Always open and build `swiftchan.xcworkspace`.
- Run `bundle install` for Fastlane. Use `bundle update` when intentionally updating the Ruby dependency lockfile.
- Resolve packages with `xcodebuild -resolvePackageDependencies -workspace swiftchan.xcworkspace -scheme swiftchan -clonedSourcePackagesDirPath build/SourcePackages -onlyUsePackageVersionsFromResolvedFile`.
- Run tests with `bundle exec fastlane tests`. The default simulator is iPhone 17; override it with `TEST_DEVICE="iPhone Air" bundle exec fastlane tests`.
- Install SwiftLint with `brew install swiftlint`. Before committing, run `swiftlint lint --fix` on changed Swift files, then `swiftlint lint`. Builds only lint; they must not rewrite source files or dependencies.
- If macOS/Xcode is unavailable, state that tests could not be run in the PR summary.
- Keep changes on a branch and use a pull request. Keep commit messages concise.

## Architecture

- `swiftchan/swiftchanApp.swift`: entry point, Kingfisher limits, SwiftData model container.
- `Environment/AppState.swift`: observable app state and navigation.
- `Environment/UserSettings.swift`: preferences and sorting notifications.
- `ViewModels/`: observable main-actor models for boards, catalogs, threads, and recurring favorites.
- `Services/FourchanService.swift`: legacy API helpers and reply indexing; current loaders use the FourChan package's async interface.
- `Services/FourplebsService.swift`: archive retrieval.
- `Services/CacheService.swift`: local media cache and video header validation.
- `Services/Prefetcher.swift` and `VideoPrefetcher.swift`: image and video prefetching.
- `Views/Media/Video/`: KSPlayer integration and playback controls.
- `Views/Media/Gallery/`: gallery paging and transitions.
- `Models/FavoriteThread.swift` and `RecurringFavorite.swift`: persisted favorites. Consider existing stores when changing uniqueness or schema.

## Dependencies

Swift Package Manager manages FourChanAPI, Kingfisher, Defaults, SwiftUI Introspect, ConfettiSwiftUI, and KSPlayer/FFmpegKit. Commit the workspace's `Package.resolved` when updating packages; use HTTPS URLs for public dependencies so contributors and CI do not need SSH keys.

KSPlayer is intentionally pinned to `bb6d367c02f3247ef3f328dc0cfea34e77aef7c5` following an Xcode Cloud Metal compilation failure. Review that constraint before changing the revision. Consult current KSPlayer documentation and verify WebM/MP4 playback, paging, seeking, and gallery dismissal when changing playback behavior.

## Tests and releases

- Unit tests live in `swiftchanTests/`; ensure new files belong to the Xcode test target.
- UI tests live in `swiftchanUITests/` but are not currently part of the shared scheme's test action.
- Add focused regressions for behavior fixes. Prefer fixtures and injected loaders over live network dependencies.
- GitHub Actions builds and runs unit tests for pull requests.
- `bundle exec fastlane beta` signs and uploads a TestFlight release, then bumps the build number. Run it only when releasing is requested.
- Certificates are managed with Fastlane match (`make renew_certs` / `make get_certs`).
