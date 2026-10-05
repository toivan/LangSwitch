//
//  AppDelegate.swift
//  LangSwitch
//

import AppKit
import Carbon
import Foundation
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusBarItem: NSStatusItem?
    private var aboutWindow: NSWindow?
    private var loginItemMenuItem: NSMenuItem?
    private var eventMonitor: Any?
    private var updateTask: URLSessionDataTask?
    private var anotherClicked = false
    private var lastPressTime: TimeInterval?
    private let longPressThreshold: TimeInterval = 0.2

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem?.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "LangSwitch")

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        addMenuItem(to: menu, title: "About LangSwitch", action: #selector(showAboutWindow))
        loginItemMenuItem = addMenuItem(to: menu, title: "Launch at Login", action: #selector(toggleLaunchAtLogin))
        if #available(macOS 13.0, *) {
            addMenuItem(to: menu, title: "Login Items Settings…", action: #selector(openLoginItemSettings))
        }
        menu.addItem(.separator())
        addMenuItem(to: menu, title: "Hide Icon", action: #selector(hideStatusBarIcon))
        addMenuItem(to: menu, title: "Exit", action: #selector(exitAction))
        statusBarItem?.menu = menu
        updateLoginItemMenu()

        // Hiding is session-only; old versions persisted a preference that hid all controls.
        UserDefaults.standard.removeObject(forKey: "hideStatusBarIcon")
        statusBarItem?.isVisible = true
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)

        // Registering a login item is an explicit menu action, never a launch side effect.
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierEvent(event)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Opening the running app from Finder or Spotlight restores access to its menu.
        showStatusBarIcon()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        updateTask?.cancel()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateLoginItemMenu()
    }

    @discardableResult
    private func addMenuItem(to menu: NSMenu, title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    private func handleModifierEvent(_ event: NSEvent) {
        guard event.keyCode == 63 else { return }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.function) {
            anotherClicked = false
            lastPressTime = ProcessInfo.processInfo.systemUptime
        }
        if !flags.intersection([.shift, .control, .option, .command]).isEmpty {
            anotherClicked = true
        }

        if flags.subtracting(.capsLock).isEmpty && !anotherClicked {
            guard let lastPressTime else { return }
            self.lastPressTime = nil
            if ProcessInfo.processInfo.systemUptime - lastPressTime < longPressThreshold {
                switchKeyboardLanguage()
            }
        }
    }

    @objc private func showAboutWindow() {
        if aboutWindow == nil {
            let windowWidth: CGFloat = 300
            let windowHeight: CGFloat = 180
            let windowContent = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown version"

            let versionLabel = NSTextField(labelWithString: "LangSwitch v\(version)")
            versionLabel.frame = NSRect(x: (windowWidth - 150) / 2, y: 130, width: 150, height: 20)
            versionLabel.alignment = .center
            windowContent.addSubview(versionLabel)

            let gitHubButton = NSButton(title: "GitHub Page", target: self, action: #selector(openGitHub))
            gitHubButton.frame = NSRect(x: (windowWidth - 100) / 2, y: 90, width: 100, height: 30)
            windowContent.addSubview(gitHubButton)

            let checkUpdatesButton = NSButton(title: "Check for Updates", target: self, action: #selector(checkForUpdates))
            checkUpdatesButton.frame = NSRect(x: (windowWidth - 150) / 2, y: 50, width: 150, height: 30)
            windowContent.addSubview(checkUpdatesButton)

            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = windowContent
            window.center()
            aboutWindow = window
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateLoginItemMenu() {
        guard let loginItemMenuItem else { return }
        if #available(macOS 13.0, *) {
            loginItemMenuItem.isEnabled = true
            switch SMAppService.mainApp.status {
            case .enabled:
                loginItemMenuItem.state = .on
            case .requiresApproval:
                loginItemMenuItem.state = .mixed
            case .notRegistered, .notFound:
                loginItemMenuItem.state = .off
            @unknown default:
                loginItemMenuItem.isEnabled = false
                loginItemMenuItem.state = .off
            }
        } else {
            loginItemMenuItem.title = "Launch at Login (macOS 13+)"
            loginItemMenuItem.isEnabled = false
        }
    }

    @objc private func toggleLaunchAtLogin() {
        guard #available(macOS 13.0, *) else { return }
        do {
            switch SMAppService.mainApp.status {
            case .enabled, .requiresApproval:
                try SMAppService.mainApp.unregister()
            case .notRegistered, .notFound:
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval {
                    showAlert(message: "Allow LangSwitch in Login Items Settings to enable launch at login.")
                }
            @unknown default:
                showAlert(message: "Unable to determine the launch at login status.")
            }
        } catch {
            showAlert(message: "Failed to change launch at login: \(error.localizedDescription)")
        }
        updateLoginItemMenu()
    }

    @objc private func openLoginItemSettings() {
        if #available(macOS 13.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    @objc private func openGitHub() {
        guard let url = URL(string: "https://github.com/toivan/LangSwitch") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func checkForUpdates() {
        guard updateTask == nil else { return }
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let currentVersion = ReleaseVersion(versionString) else {
            showAlert(message: "Unable to determine the current app version.")
            return
        }
        guard let url = URL(string: "https://api.github.com/repos/toivan/LangSwitch/releases/latest") else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        updateTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let message: String
            let releasesPage = "https://github.com/toivan/LangSwitch/releases"
            if error != nil {
                message = "The update check failed because of a network error. Check your connection and try again."
            } else if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200:
                    if let data,
                       let release = try? JSONDecoder().decode(GitHubRelease.self, from: data),
                       release.tagName.utf8.count <= 128,
                       let latestVersion = ReleaseVersion(release.tagName) {
                        message = latestVersion > currentVersion
                            ? "New version \(release.tagName) is available! Download it from GitHub."
                            : "You're up to date."
                    } else {
                        message = "Invalid version information received from GitHub."
                    }
                case 404:
                    message = "GitHub has no public release information for this repository. Check the fork's Releases page: \(releasesPage)"
                case 429:
                    message = "GitHub's request limit has been reached. Try again later, or check the Releases page: \(releasesPage)"
                case 403:
                    if response.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0"
                        || response.value(forHTTPHeaderField: "Retry-After") != nil {
                        message = "GitHub's request limit has been reached. Try again later, or check the Releases page: \(releasesPage)"
                    } else {
                        message = "GitHub denied this update check (HTTP 403), possibly because of a request limit. Try again later, or check the Releases page: \(releasesPage)"
                    }
                default:
                    message = "GitHub returned HTTP \(response.statusCode) while checking for updates. Please try again later."
                }
            } else {
                message = "GitHub returned an unexpected response while checking for updates. Please try again later."
            }
            DispatchQueue.main.async { [weak self] in
                self?.updateTask = nil
                self?.showAlert(message: message)
            }
        }
        updateTask?.resume()
    }

    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }

    @objc private func hideStatusBarIcon() {
        let alert = NSAlert()
        alert.messageText = "Hide the LangSwitch icon?"
        alert.informativeText = "To show the icon again, open LangSwitch from Finder or Spotlight. It also reappears when LangSwitch next starts."
        alert.addButton(withTitle: "Hide Icon")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        statusBarItem?.isVisible = false
    }

    private func showStatusBarIcon() {
        statusBarItem?.isVisible = true
    }

    @objc private func exitAction() {
        NSApplication.shared.terminate(nil)
    }

    private func switchKeyboardLanguage() {
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            print("Failed to get the current keyboard input source.")
            return
        }
        let inputSources = getInputSources()
        guard !inputSources.isEmpty,
              let currentIndex = inputSources.firstIndex(where: { $0 == currentSource }) else {
            print("Failed to find the current keyboard input source.")
            return
        }
        let nextSource = inputSources[(currentIndex + 1) % inputSources.count]
        guard TISSelectInputSource(nextSource) == noErr else {
            print("Failed to select the next keyboard input source.")
            return
        }
    }

    private func getInputSources() -> [TISInputSource] {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return sources.filter {
            $0.category == kTISCategoryKeyboardInputSource as String && $0.isSelectable
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }
}

private extension TISInputSource {
    func property(_ key: CFString) -> AnyObject? {
        guard let value = TISGetInputSourceProperty(self, key) else { return nil }
        // TISGetInputSourceProperty follows the Get rule; the source owns this value.
        return Unmanaged<AnyObject>.fromOpaque(value).takeUnretainedValue()
    }

    var category: String? {
        property(kTISPropertyInputSourceCategory) as? String
    }

    var isSelectable: Bool {
        property(kTISPropertyInputSourceIsSelectCapable) as? Bool ?? false
    }
}
