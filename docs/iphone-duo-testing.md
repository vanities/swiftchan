# iPhone Duo simulator testing

Verified locally on 2026-10-04 with Xcode Duo 27.1 (24A94403), the iOS 27.1 simulator (24A94401), and `agent-device@0.21.20`. This is local simulator evidence; physical-device and hosted-CI pose control have not been verified.

## Toolchain and tool versions

Scope the Duo toolchain to each command. Keep the normal Xcode selection intact:

```sh
export DEVELOPER_DIR=/Applications/Xcode-Duo-beta.app/Contents/Developer
xcrun simctl list devices available
```

Select the intended simulator by its full UDID. Our review simulator is `3C2C0377-69D7-432C-A82A-0DEA70E77A5B`; another machine must use its own. Swiftchan's current dependency build additionally needs the installed 27.2 beta toolchain; pose commands use the Duo 27.1 toolchain.

The previously installed XcodeBuildMCP CLI was 2.6.2. Upstream 2.7.0 adds Xcode 27 Device Hub support; 2.7.1 renames the package to **MobileBuildMCP**. Pinned `npx --yes mobilebuildmcp@2.7.1 --version` and its simulator inventory worked here. Its inspected tool inventory has no fold/pose setter. Updating that package alone does not provide hinge control. No global MCP configuration change is required for the commands below.

## Working native hinge control

`agent-device@0.21.20` sends a simulator HID hinge event and verifies the resulting angle with CoreDevice. It does not need Device Hub accessibility or host UI scripting. The upstream headless amendment supersedes its older Device Hub accessibility instructions.

First open an installed app to establish the session. A fold request without an active session was refused even when supplied a UDID:

```sh
npx --yes agent-device@0.21.20 open APP_BUNDLE_ID \
  --session duo-review --platform ios --udid SIMULATOR_UDID --foreground --json
npx --yes agent-device@0.21.20 fold open --session duo-review --json
npx --yes agent-device@0.21.20 fold half-open --session duo-review --json
npx --yes agent-device@0.21.20 fold closed --session duo-review --json
```

Replace both uppercase placeholders. Run mutations sequentially. A successful local readback was:

| Command | Measured hinge angle | Lit panel | App viewport observed by the native probe |
| --- | --- | --- | --- |
| `fold open` | 180 degrees | `LCD-1` / display 3 | 951 x 669 pt; division inactive |
| `fold half-open` | 130 degrees | `LCD-1` / display 3 | 951 x 669 pt; active vertical division |
| `fold closed` | 0 degrees | `LCD` / display 1 | 466 x 678 pt; no division |

The book-pose division measured x=455.5, width=40, height=669 pt, with 20 pt leading/trailing margins. These numbers describe this test device, not layout constants. Production layouts must use the native reserved-region frame and margins. Re-query app window geometry and accessibility elements after every pose change; old coordinates and references are stale. CoreDevice's native panel size (669 x 951 pt here) is not the oriented app viewport.

When finished, end the session without shutting down the simulator:

```sh
npx --yes agent-device@0.21.20 close --session duo-review --json
```

The hinge helper depends on private simulator HID behavior and the selected simulator SDK. Keep the version pinned and verify readback after toolchain updates. Do not substitute `simctl io screenConfig power`: switching display power does not change the actual hinge state.

## Book, flat, and tabletop

**Flat** means fully open. **Book** means partially open with the hinge vertical in the app. **Tabletop** is the laptop-like pose with the lower half lying flat, the upper half raised, and the hinge horizontal. It is not a separate verified CLI preset: it needs a partial fold plus the corresponding physical quarter-turn.

`orientation portrait` and `orientation landscape-right` returned success here, but the live native probe still reported the same 951 x 669 pt viewport and active vertical division. Therefore automated tabletop rotation is **unverified**. Do not label a book capture as tabletop, or treat an orientation command's success message as proof. A tabletop check must observe an active horizontal division in the app and inspect the actual rendered controls. Use the simulator's physical rotation control when available, and retain this manual requirement until app-visible geometry confirms a working automation path.

The user's physical quarter-turn was verified on 2026-10-04: the native viewport became 669 x 951 pt, with an active horizontal division at y=455.5, height=40, width=669 pt, and 20 pt top/bottom margins. This proves the manual tabletop geometry; it does not prove an automated rotation command. Capture harnesses must preserve that orientation instead of setting landscape again during setup. The full-screen catalog/thread navigation must preserve this physical orientation during capture.

## Screenshots, video, and continuity evidence

Always name the lit display. On this simulator:

```sh
# Inner display: fully open or book.
xcrun simctl io SIMULATOR_UDID screenshot --display=3 inner.png
xcrun simctl io SIMULATOR_UDID recordVideo --codec=h264 --display=3 inner.mp4
# Outer display: closed.
xcrun simctl io SIMULATOR_UDID screenshot --display=1 outer.png
```

Stop `recordVideo` with SIGINT so the file is finalized. An implicit screenshot can capture the dark inner panel while closed and still exit successfully. Inspect actual image content and decode the video before delivering it. Use `uv run` for Python capture and validation helpers.

A single-panel recording can show a live flat/book transition, but does not prove a continuous inner/outer transition after the active panel switches. Record the correct panel(s) and disclose any recording gap. Verify a real passing test case and the final test suite, not just a zero exit code or a preparation screenshot. If a timed test has already ended, a later pose change cannot make its earlier video a continuity pass.

Distinguish these outcomes: a prepared state; saved state restored after reopening; an existing process reactivated after a pose change; and the same app staying foreground throughout a recorded fold. Assert visible content and interaction, not only an offscreen DOM title or a retained model identifier.

## Physical quarter-turn verification

On 2026-10-04 a scoped Xcode 27.1 XCTest set XCUIDevice.shared.orientation to landscapeLeft while the Duo was in Tabletop. Its real landscape-window expectation failed. The fresh native probe still reported viewport 669 x 951 and an active horizontal division at y=455.5, height 40, with top/bottom margins 20. Standard iPad XCTest orientation preparation passes; do not infer Duo physical rotation support from it. Native agent-device hinge changes remain verified. Use the Simulator's manual quarter-turn for Duo, then read native region geometry. This establishes the tested limitation of these current commands, not a claim that every future automation path is unavailable.

## App-specific checks

Use the workspace. Build 1.3 (5) uses a full-screen catalog and ordinary pushed thread navigation on every device. Tapping a card replaces the catalog with the thread; Back returns to the same scrolled catalog. Tabletop must not retain a catalog above a half-height thread, and iPad must not retain a catalog sidebar. Keep the post-ID scroll position binding for reading restoration. Navigation no longer depends on workspace mode or transient background geometry.

The closed outer display and an active native division keep two catalog columns. Flat Duo derives more columns from the full catalog width. For an active vertical division, use its native frame and margins to keep the two card columns clear of the hinge. The twelve-card fixture (`--ui-catalog-grid-fixture`) is debug-only.

`testCatalogOpensThreadsFullScreenAndReturnsToGrid` checks a scrolled catalog, full-screen thread geometry, and Back restoring the same visible card. `testDuoCatalogGridExpandsAndRefoldsThenOpensThreadFullScreen` additionally checks a live 130-to-180-to-130-degree transition, opening and returning from threads, and reply 205 surviving background activation. Run it with `TEST_RUNNER_CATALOG_GRID_CAPTURE=1`, preserve the verified manual tabletop quarter-turn, and use native hinge watchers at `CATALOG_GRID_READY_TO_UNFOLD` and `CATALOG_GRID_READY_TO_FOLD`. Other opt-in cases cover full-screen Tabletop, background activation, and a vertical catalog hinge gutter. Do not enable native pose flags on ordinary CI phones.

Historical build 3 and build 4 catalog/thread workspace checks remain in `../iphone-duo-review/2026-10-04-current/` and `../iphone-duo-review/2026-10-04-grid/`. They show the previous design. The current full-screen review belongs in `../iphone-duo-review/2026-10-05-fullscreen/`; keep its version, source, test results, and native PNG/video provenance separate.

Installed app bundle ID: `vanities.swiftchan`.

## Sources

Read the complete relevant Apple documents and upstream tool instructions when changing this workflow:

- [Apple: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [Apple: Configuring the environment of a simulated device](https://developer.apple.com/documentation/xcode/configuring-the-environment-of-a-simulated-device)
- [Apple: Interacting with your app in the iOS or iPadOS Simulator](https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-the-ios-or-ipados-simulator)
- [MobileBuildMCP 2.7.0](https://github.com/getsentry/MobileBuildMCP/releases/tag/v2.7.0) and [2.7.1](https://github.com/getsentry/MobileBuildMCP/releases/tag/v2.7.1)
- [Agent Device foldable-panel ADR](https://github.com/callstack/agent-device/blob/main/docs/adr/0025-foldable-apple-panels.md), especially the 2026-09-22 headless amendment and the accepted quarter-turn evidence gap

## Gallery controls

Build 1.3 (6) opens each gallery page without the image/thumbnail search button or media counter. A single media tap reveals both, and another hides them. The optional thumbnail strip follows the same tap. Paging, zooming, and seeking clear the overlays; the close button and long-press media actions remain available when not zoomed. Check preview enabled and disabled, double-tap zoom, vertical paging, and returning to the selected post.

The gallery UI regressions use invented image artwork and a local silent WebM fixture. For native recordings, run `testPrepareGalleryCaptureOrientation` with `TEST_RUNNER_GALLERY_CAPTURE_ORIENTATION=portrait` or `landscapeLeft` before starting the recorder; the walkthrough also asserts the app's actual window orientation. Set `TEST_RUNNER_DUO_CAPTURE=1` to pause at capture markers. Leave the orientation override unset when preserving a verified Duo pose.
