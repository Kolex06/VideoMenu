# VideoMenu for Chromium Browsers

Keep the macOS menu bar visible while browsing in full screen, and hide it during full-screen video.

**macOS only. Requires both the browser extension and the separate native helper.** Only Brave has been tested live. Chrome, Chromium, Edge, Vivaldi, and Opera are configured targets, not yet verified.

## Install

1. [Download the experimental Mac helper (Apple Silicon)](https://github.com/Kolex06/VideoMenu/raw/refs/heads/main/downloads/VideoMenu-macOS-arm64.zip), extract it, and keep the VideoMenu folder in a permanent location.
2. Open VideoMenu.app and choose Install Helper. It registers a local native-messaging host with the configured browsers. This is an ad-hoc signed developer build, not notarized; if macOS blocks it, build it locally from the source instead using Xcode Command Line Tools and `bash build.sh`.
3. Install [VideoMenu from the Chrome Web Store](https://chromewebstore.google.com/detail/videomenu/jklgafbeefjgjolkggngbgkaefgmnolb). This link becomes available after Google approves and publishes it. For development, load the `extension` folder at `chrome://extensions` with Developer mode enabled.
4. Refresh existing video tabs. Use the video player's full-screen button.

Do not move the helper folder after installing; rerun the installer if its location changes. The prebuilt helper is Apple Silicon only. Intel Macs can build from source with `bash build.sh`.

## Behavior

- Ordinary full-screen browsing: menu bar visible.
- Standard full-screen video: menu bar hides, even when paused.
- Leave video full screen or switch away: menu bar returns.
- Toolbar icon: pause/resume. OFF means paused; VID means hiding was requested; ! means the helper is disconnected.

Use VideoMenu in one browser/profile at a time. Exit the other browser using VideoMenu before switching. A single helper owns the global full-screen preference to prevent multiple processes fighting over it.

## Privacy

Processing is local. The extension sends only enabled/hide booleans to the native helper. No analytics, accounts, advertising, page-content upload, or remote browsing-data collection. [Privacy policy](PRIVACY.md).

## Remove

Disable/remove the extension first to restore your previous full-screen menu-bar preference. Open the helper app and choose Uninstall Helper, then delete its folder. No login item or independent background daemon is installed.

## Experimental limitations

The helper uses an undocumented macOS preference notification and may need updates after macOS changes. Custom canvas players, closed shadow-root players, restricted pages, or blocked content scripts may not be detected. Moving the pointer to the top can still reveal the menu bar. On a non-notched display, the window may resize when the menu bar changes. Per-app preference overrides can interfere.

Normal disconnection/termination restores the previous preference. A forcibly killed or crashed helper may leave the last setting behind. Recover in macOS System Settings by choosing Never for Automatically hide and show the menu bar. The desktop auto-hide setting is not modified.

## Source

`extension/` contains the Manifest V3 extension. `source/` contains the Swift helper and setup app. `bash build.sh` builds locally with Xcode Command Line Tools. No third-party runtime dependency is needed.

Mechanism reference: [houdini's menu-bar toggler](https://github.com/mgxv/houdini/blob/main/Sources/MenuBarToggler.swift). Protocol: [Chrome native messaging](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging).

Report problems through [GitHub Issues](https://github.com/Kolex06/VideoMenu/issues). Store status: draft, not published yet.
