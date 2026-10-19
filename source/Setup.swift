import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.activate(ignoringOtherApps: true)
let bundle = Bundle.main.bundleURL
let folder = bundle.deletingLastPathComponent()
let hostFolders = ["BraveSoftware/Brave-Browser", "Google/Chrome", "Chromium", "Microsoft Edge", "Vivaldi", "com.operasoftware.Opera"].map { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/\($0)/NativeMessagingHosts") }
func alert(_ title: String, _ text: String) {
    let a = NSAlert(); a.messageText = title; a.informativeText = text; a.runModal()
}
let dialog = NSAlert()
dialog.messageText = "VideoMenu for Chromium Browsers"
dialog.informativeText = "Keep the menu bar visible while browsing, including full-screen Chromium browsers. Hide it during full-screen videos.\n\nInstall the helper and the VideoMenu extension from the Chrome Web Store. Refresh your video tabs afterward. For a developer build, use chrome://extensions and Load unpacked.\n\nKeep this folder in its current location after installing. The extension reads video full-screen state on websites; it sends only two booleans to this local helper. No network service, account, or Accessibility permission is needed.\n\nThis is an experimental local build. It uses an undocumented macOS setting notification."
dialog.addButton(withTitle:"Install Helper")
dialog.addButton(withTitle:"Show Extension Folder")
dialog.addButton(withTitle:"Uninstall Helper")
dialog.addButton(withTitle:"Cancel")
switch dialog.runModal() {
case .alertFirstButtonReturn:
    do {
        let executable = bundle.appendingPathComponent("Contents/MacOS/VideoMenuHost").path
        let extids = try String(contentsOf: bundle.appendingPathComponent("Contents/Resources/extension-id.txt"), encoding:.utf8).split(whereSeparator: \.isNewline)
        let manifest: [String:Any] = ["name":"local.videomenu.helper","description":"VideoMenu full-screen video helper","path":executable,"type":"stdio","allowed_origins":extids.map { "chrome-extension://\($0)/" }]
        for hostFolder in hostFolders {
            try FileManager.default.createDirectory(at:hostFolder,withIntermediateDirectories:true)
            try JSONSerialization.data(withJSONObject:manifest,options:.prettyPrinted).write(to:hostFolder.appendingPathComponent("local.videomenu.helper.json"),options:.atomic)
        }
        NSWorkspace.shared.open(folder.appendingPathComponent("extension"))
        alert("Helper installed", "Install VideoMenu from the Chrome Web Store, or load the extension folder in Developer mode at chrome://extensions. Refresh existing tabs.\n\nClick the extension icon to pause or resume. A red ! badge means the helper is disconnected.")
    } catch { alert("Installation failed",error.localizedDescription) }
case .alertSecondButtonReturn:
    NSWorkspace.shared.open(folder.appendingPathComponent("extension"))
case .alertThirdButtonReturn:
    do {
        // Disconnect the extension first so its live host restores the original preference.
        alert("First disable VideoMenu in your browser", "Open chrome://extensions and disable or remove VideoMenu. This disconnects the helper and restores your previous menu-bar preference. Then click OK to remove its registration.")
        for hostFolder in hostFolders {
            let manifestURL = hostFolder.appendingPathComponent("local.videomenu.helper.json")
            if FileManager.default.fileExists(atPath:manifestURL.path) { try FileManager.default.removeItem(at:manifestURL) }
        }
        alert("Helper unregistered", "You can now delete the VideoMenu folder. If the helper was forcibly killed, set Automatically hide and show the menu bar to Never in System Settings.")
    } catch { alert("Could not unregister helper",error.localizedDescription) }
default: break
}
