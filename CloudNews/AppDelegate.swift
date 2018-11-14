//
//  AppDelegate.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/20/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import Alamofire

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        NewsManager.shared.updateBadge()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func onNewFeed(_ sender: Any) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Add Feed"
        alert.informativeText = "Enter the address of the new feed"
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField
        alert.beginSheetModal(for: NSApp.keyWindow!, completionHandler: { [weak textField] (response) in
            if (response == .alertFirstButtonReturn) {
                if let incoming = textField?.stringValue {
                    NewsManager.shared.addFeed(url: incoming)
                }
            }
        })
    }
    
    @IBAction func onNewFolder(_ sender: Any) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Add Folder"
        alert.informativeText = "Enter the name of the new folder"
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField
        alert.beginSheetModal(for: NSApp.keyWindow!, completionHandler: { [weak textField] (response) in
            if (response == .alertFirstButtonReturn) {
                if let incoming = textField?.stringValue {
                    NewsManager.shared.addFolder(name: incoming)
                }
            }
        })
    }

    @IBAction func onRefresh(_ sender: Any) {
        NewsManager.shared.sync()
    }

}
