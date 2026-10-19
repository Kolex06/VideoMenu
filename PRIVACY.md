# VideoMenu Privacy Policy

Effective October 19, 2026.

VideoMenu manages the macOS menu bar during full-screen video in Chromium browsers. It requires a separate local Mac helper.

## Information processed locally

The extension checks whether a full-screen web element contains a visible video. It uses the active tab and focused browser window to decide whether to hide the menu bar. These checks take place on your computer. It does not read video content, passwords, form entries, or page text for this purpose.

The extension sends only two boolean values, enabled and hide, to the local helper using native messaging. It stores your enabled/disabled preference locally. Temporary full-screen state is kept in memory. The helper checks the foreground application's identifier and changes the macOS full-screen menu-bar preference.

## No remote collection or sharing

VideoMenu does not transmit browsing history, URLs, page content, video titles, or personal information to a remote server. It has no analytics, advertising, remote account, or data sale. Extension updates and store services are provided by your browser and the Chrome Web Store under their own privacy policies.

## Permissions

Website access detects full-screen video, including embedded players. Native messaging connects to the Mac helper. Local storage remembers whether the extension is enabled.

## Control and removal

Pause VideoMenu using its toolbar icon or disable/remove it from the browser's extension settings. Normal helper disconnection restores the previous full-screen menu-bar preference. If the helper is forcibly killed, restore visibility in macOS System Settings. Uninstalling the helper removes its browser registration files.

## Contact

Report questions or requests at https://github.com/Kolex06/VideoMenu/issues .
