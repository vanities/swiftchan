# iPad layout and simulator review

Read Apple's complete [Designing for iPadOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados) guidance and [Supporting multiple windows on iPad](https://developer.apple.com/documentation/uikit/supporting-multiple-windows-on-ipad) before changing the layout. Design for the available window, size class, safe areas, and text size, rather than treating device orientation as the layout model. Check portrait, landscape, and narrow windows. These apps have not gained new multiple-window support in this pass.

## Native simulator capture

The review uses iPad mini (A17 Pro) portrait (744 x 1133 pt) and iPad Pro 13-inch (M5) landscape (1376 x 1032 pt), on iPadOS 27.0. Standard iPad uses main display 1. Verify the device with `xcrun simctl list devices` and its displays with `xcrun simctl io <UDID> enumerate`; do not reuse Duo inner display 3.

An XCTest preparation sets `XCUIDevice.shared.orientation` to `.portrait` or `.landscapeLeft`, launches the app, and waits until the actual app window has the requested aspect ratio before starting recordVideo. Then the walkthrough navigates the real app. Native screenshots must have the same requested orientation: mini portrait 1488 x 2266 pixels, Pro landscape 2752 x 2064 pixels. Do not rotate a PNG/video to claim a native orientation passed.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl io <UDID> recordVideo --codec=h264 --display=1 review.mp4
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl io <UDID> screenshot --display=1 review.png
```

Use a scoped DEVELOPER_DIR; do not change global xcode-select. Native Duo APIs require the 27.1/27.2 toolchain described in [iphone-duo-testing.md](iphone-duo-testing.md). The iPad walkthroughs may use that same built binary but run on an ordinary iPad simulator. A passing CLI orientation command alone does not prove app geometry.

Python capture/package helpers run with `uv run --with pillow python`. Run one UI walkthrough per simulator at a time. Package only actual nonempty passing test cases and passing selected suites; reject assertions, empty test restarts, missing/black screenshots, or incomplete videos. Keep original pixels for PNGs. A review MP4 can be scaled for size, without rotating, cropping, or recreating the UI. Verify videos with a full FFmpeg decode and native AVFoundation playback/frame decode.

## App behavior and validation

Regular-width windows at least 580 pt wide use a board and thread workspace. Compact windows retain pushed thread navigation. Keep catalog selection visible, the selected thread readable, and the catalog title inline in the workspace. The sidebar uses the same OP card grid as compact navigation; the detail shows the selected thread and its media/actions. Compact phones and active Duo divisions keep two catalog columns. Flat Duo and regular iPad layouts add columns when the actual catalog pane has room, with approximately 140 pt per card; a narrow iPad sidebar still uses two. Selected cards have an accent outline. On a native horizontal Duo division, the catalog sits above the thread, with the system division and both 20 pt margins kept clear. iPad uses the balanced NavigationSplitView. Thread scrolling tracks post identity with scrollPosition(id:anchor:), so a window resize can keep the reading post visible. Build 1.3 (4) is the app version.

Use debug-only in-memory catalog/thread/media fixtures. Check switching threads, returning to boards, gallery next-image/filmstrip/dismissal, favorites, settings, following a general, and post actions. The normal regression suite passes 95 unit tests and 20 UI tests on iPhone Air 26.5; pose-only cases skip there. After adding the post-ID scroll binding, 95 unit tests and eight focused quote, jump, resume, unread, recent-thread, and linked-post UI regressions pass on the final source. Mini portrait and Pro landscape walkthroughs both pass on that source.

Those counts describe build 3. Build 4 adds `testCompactCatalogKeepsTwoColumnsAndOpensThreads`, which checks real card frames and pushed navigation, and the opt-in `testDuoCatalogGridExpandsAndRefoldsWithoutLosingThread`. The native grid transition passes with two columns at 130 degrees, four at 180 degrees, and two after returning to 130 degrees, while thread 200 and reply 205 remain visible. Use `--ui-catalog-grid-fixture` for twelve invented catalog cards. Do not enable pose-test flags on ordinary CI phones.

## Review artifacts

The shared workspace review is `../iphone-duo-review/2026-10-04-current/review/`, with per-app `*-ipad-mini` and `*-ipad-pro` MP4/JSON/PNG packets. `validation.json` records passing cases and source provenance; use it to distinguish historical Duo footage from the current build. The local gallery is http://127.0.0.1:8179/ when its server is running. These artifacts do not indicate an App Store Connect or TestFlight submission.

The follow-up catalog grid review is `../iphone-duo-review/2026-10-04-grid/`. Keep its build 4 clips and validation separate from the earlier build 3 Swiftchan footage.
