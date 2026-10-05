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

Build 1.3 (5) uses the full available catalog width on iPad, with approximately 140 pt per OP card and at least two columns. Tapping a card pushes a full-screen thread. Back returns to the existing catalog and scroll position. This same navigation applies to compact phones and Duo, including Tabletop. Compact phones, the closed Duo, and active Duo divisions keep two catalog columns. The catalog is not a persistent sidebar or upper pane. Thread scrolling tracks post identity with `scrollPosition(id:anchor:)`, so resizing and activation can retain the reading post.

Use debug-only in-memory catalog/thread/media fixtures. `testCatalogOpensThreadsFullScreenAndReturnsToGrid` scrolls to the last invented card, opens its thread, checks that the thread fills the window, and returns to the same visible card. The opt-in walkthrough also checks returning to boards, gallery next-image/filmstrip/dismissal, favorites, settings, following a general, and post actions. The new twelve-card fixture is `--ui-catalog-grid-fixture`. Do not enable Duo pose-test flags on ordinary CI phones.

Historical build 3 and build 4 validation counts describe the former workspace design. Current full-screen captures and validation are kept separately in the review below.

## Review artifacts

The shared workspace review is `../iphone-duo-review/2026-10-04-current/review/`, with per-app `*-ipad-mini` and `*-ipad-pro` MP4/JSON/PNG packets. `validation.json` records passing cases and source provenance; use it to distinguish historical Duo footage from the current build. The local gallery is http://127.0.0.1:8179/ when its server is running. These artifacts do not indicate an App Store Connect or TestFlight submission.

The follow-up catalog grid review is `../iphone-duo-review/2026-10-04-grid/`. Keep its build 4 clips and validation separate from the earlier build 3 Swiftchan footage.

The full-screen navigation review is `../iphone-duo-review/2026-10-05-fullscreen/`, for build 1.3 (5). Its mini portrait and Pro landscape captures verify the actual full-width thread and Back restoring the scrolled catalog.

## Gallery controls

Build 1.3 (6) opens each gallery page without the image/thumbnail search button or media counter. A single media tap reveals both, and another hides them. The optional thumbnail strip follows the same tap. Paging, zooming, and seeking clear the overlays; the close button and long-press media actions remain available when not zoomed. Check preview enabled and disabled, double-tap zoom, vertical paging, and returning to the selected post.

The gallery UI regressions use invented image artwork and a local silent WebM fixture. For native recordings, run `testPrepareGalleryCaptureOrientation` with `TEST_RUNNER_GALLERY_CAPTURE_ORIENTATION=portrait` or `landscapeLeft` before starting the recorder; the walkthrough also asserts the app's actual window orientation. Set `TEST_RUNNER_DUO_CAPTURE=1` to pause at capture markers. Leave the orientation override unset when preserving a verified Duo pose.
