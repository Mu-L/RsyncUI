//
//  AppDelegate.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/01/2021.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
        // Decide if:
        // 1: First time start, use new profilepath
        // 2: Old profilepath is copied to new, use new profilepath
        // 3: Use old profilepath
        // ViewControllerReference.shared.usenewconfigpath = true or false (default true)
        _ = Neworoldprofilepath()
        // Create base profile catalog
        CatalogProfile().createrootprofilecatalog()
        // Must read userconfig when loading main view, view only load once
        if let userconfiguration = PersistentStorageUserconfiguration().readuserconfiguration() {
            _ = Userconfiguration(userconfigRsyncOSX: userconfiguration)
        }
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 950, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView:
            RsyncUIView()
                .environmentObject(RsyncOSXViewGetRsyncversion())
                .environmentObject(Profilenames()))
        window.makeKeyAndOrderFront(nil)
        window.title = "RsyncUI"
        window.isMovableByWindowBackground = true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate {
    @IBAction func AboutPanel(_ sender: Any?) {
        let content = NSViewController()
        content.title = NSLocalizedString("About", comment: "about")
        let view = NSHostingView(rootView: AboutView())
        view.frame.size = view.fittingSize
        content.view = view
        let panel = NSPanel(contentViewController: content)
        panel.styleMask = [.closable, .titled]
        panel.orderFront(sender)
        panel.makeKey()
    }

    @IBAction func showPreferences(_ sender: Any?) {
        let content = NSViewController()
        content.title = NSLocalizedString("RsyncUI settings", comment: "settings")
        let view = NSHostingView(rootView: Usersettings()
            .environmentObject(SharedReference.shared.errorobject!)
            .environmentObject(RsyncOSXViewGetRsyncversion()))
        view.frame.size = view.fittingSize
        content.view = view
        let panel = NSPanel(contentViewController: content)
        panel.styleMask = [.closable, .titled, .resizable]
        panel.orderFront(sender)
        panel.makeKey()
    }

    @IBAction func logview(_ sender: Any?) {
        let content = NSViewController()
        content.title = NSLocalizedString("RsyncUI logfile", comment: "settings")
        let view = NSHostingView(rootView: LogfileView())
        view.frame.size = view.fittingSize
        content.view = view
        let panel = NSPanel(contentViewController: content)
        panel.styleMask = [.closable, .titled, .resizable]
        panel.orderFront(sender)
        panel.makeKey()
    }

    @IBAction func executeselected(_: Any?) {
        SharedReference.shared.shortcutobject?.execute = true
    }

    @IBAction func estimateselected(_: Any?) {
        print("estimate")
    }
}
