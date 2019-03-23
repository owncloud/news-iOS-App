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

    let prefsWindowController = PrefsWindowController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        ValueTransformer.setValueTransformer(SummaryValueTransformer(), forName: .summaryValueTransformerName)
        ValueTransformer.setValueTransformer(TitleValueTransformer(), forName: .titleValueTransformerName)


        self.writeCss()
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
        NewsManager.shared.sync {
            NotificationCenter.default.post(name: .syncComplete, object: nil)
        }
    }

    @IBAction func onPreferences(_ sender: Any) {
        self.prefsWindowController.showWindow(nil)
    }

    private func writeCss() {
        if let templateURL = Bundle.main.url(forResource: "rss", withExtension: "css") {
            do {
                let css = try String(contentsOf: templateURL, encoding: .utf8)
                if let saveUrl = ArticleHelper.documentsFolderURL?
                    .appendingPathComponent("rss")
                    .appendingPathExtension("css") {
                    try css.write(to: saveUrl, atomically: true, encoding: .utf8)
                }
            } catch {
                print("Error copying css from bundle")
            }
        }
    }
    
}

/*
NextCloud New keyboard shortcuts

 // j, n, right arrow
Next item

 // k, p, left arrow
Previous item

 // u
toggle unread

 // e
expand item

 // s, i, l
toggle star

 // h
toggle star, go to next

 // o
open link

 // r
refresh

 // f
next feed

 // d
previous feed

 // c
 previous folder

 // a
 } else if ([65].indexOf(keyCode) >= 0) {

 event.preventDefault();
 scrollToActiveNavigationEntry(navigationArea);

 // v
 next folder

 // q
 search

 // shift + a
 mark all read
 */
