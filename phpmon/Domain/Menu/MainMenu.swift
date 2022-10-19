//
//  MainMenu.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSWindowDelegate, NSMenuDelegate, PhpSwitcherDelegate {

    static let shared = MainMenu()

    override init() {
        super.init()
        statusItem.isVisible = !isRunningSwiftUIPreview
    }

    weak var menuDelegate: NSMenuDelegate?

    /**
     The status bar item with variable length.
     */
    let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )

    // MARK: - UI related

    /**
     Rebuilds the menu (either asynchronously or synchronously).
     Defaults to rebuilding the menu asynchronously.
     */
    func rebuild(async: Bool = true) {
        if !async {
            self.rebuildMenu()
            return
        }

        // Update the menu item on the main thread
        Task { @MainActor [self] in
            self.rebuildMenu()
        }
    }

    /**
     Update the menu's contents, based on what's going on.
     This will rebuild the entire menu, so this can take a few moments.
     
     Use `rebuild(async:)` to ensure the rebuilding happens in the background.
     */
    private func rebuildMenu() {
        let menu = StatusMenu()
        menu.addMenuItems()
        menu.items.forEach({ (item) in
            item.target = self
        })
        statusItem.menu = menu
        statusItem.menu?.delegate = self
    }

    /**
     Sets the status bar image based on a version string.
     */
    @MainActor func setStatusBarImage(version: String) {
        setStatusBar(
            image: (Preferences.preferences[.iconTypeToDisplay] as! String != MenuBarIcon.noIcon.rawValue)
                ? MenuBarImageGenerator.textToImageWithIcon(text: version)
                : MenuBarImageGenerator.textToImage(text: version)
        )
    }

    /**
     Sets the status bar image, based on the provided NSImage.
     The image will be used as a template image.
     */
    @MainActor func setStatusBar(image: NSImage) {
        if let button = statusItem.button {
            image.isTemplate = true
            button.image = image
        }
    }

    // MARK: - User Interface

    /** Reloads which PHP versions is currently active. */
    @objc func refreshActiveInstallation() {
        if !PhpEnv.shared.isBusy {
            PhpEnv.shared.currentInstall = ActivePhpInstallation()
            updatePhpVersionInStatusBar()
        } else {
            Log.perf("Skipping version refresh due to busy status")
        }
    }

    /** Updates the icon (refresh icon) and rebuilds the menu. */
    @objc func updatePhpVersionInStatusBar() {
        refreshIcon()
        rebuild()
    }

    /**
     Reloads the menu in the foreground.
     This mimics the exact behaviours of `asyncExecution` as set in the method below.
     */
    @MainActor @objc func reloadPhpMonitorMenuInForeground() async {
        refreshActiveInstallation()
        refreshIcon()
        Task { @MainActor in
            self.rebuild(async: false)
        }
        await ServicesManager.loadHomebrewServices()
    }

    /**
     Shows the Welcome Tour screen, again.
     Did this need a comment? No, probably not.
     */
    @objc func showWelcomeTour() {
        Task { @MainActor in
            OnboardingWindowController.show()
        }
    }

    /** Reloads the menu in the background, using `asyncExecution`. */
    @objc func reloadPhpMonitorMenuInBackground() {
        asyncExecution({
            // This automatically reloads the menu
            Log.info("Reloading information about the PHP installation (in the background)...")
        }, behaviours: [
            .setsBusyUI,
            .reloadsPhpInstallation,
            .broadcastServicesUpdate,
            .updatesMenuBarContents
        ])
    }

    /** Refreshes the icon with the PHP version. */
    @objc func refreshIcon() {
        Task { @MainActor [self] in
            if PhpEnv.shared.isBusy {
                setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
            } else {
                if Preferences.preferences[.shouldDisplayDynamicIcon] as! Bool == false {
                    // Static icon has been requested
                    setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIconStatic"))!)
                } else {
                    // The dynamic icon has been requested
                    let long = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool
                    setStatusBarImage(version: long ? PhpEnv.phpInstall.version.long  : PhpEnv.phpInstall.version.short)
                }
            }
        }
    }

    /** Updates the icon to be displayed as busy. */
    @objc func setBusyImage() {
        Task { @MainActor [self] in
            setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        }
    }

    // MARK: - Menu Item Functionality

    @objc func openAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }

    @objc func openPrefs() {
        PreferencesWindowController.show()
    }

    @objc func openWarnings() {
        WarningsWindowController.show()
    }

    @objc func openDomainList() {
        DomainListVC.show()
    }

    @objc func openDonate() {
        NSWorkspace.shared.open(Constants.Urls.DonationPage)
    }

    @objc func terminateApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc func checkForUpdates() async {
        await AppUpdateChecker.checkIfNewerVersionIsAvailable(initiatedFromBackground: false)
    }

    // MARK: - Menu Delegate

    func menuWillOpen(_ menu: NSMenu) {
        // Make sure the shortcut key does not trigger this when the menu is open
        App.shared.shortcutHotkey?.isPaused = true
        Task { // Reload Homebrew services information asynchronously
            await ServicesManager.loadHomebrewServices()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        // When the menu is closed, allow the shortcut to work again
        App.shared.shortcutHotkey?.isPaused = false
    }
}
