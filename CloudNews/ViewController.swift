//
//  ViewController.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/20/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController {

    @IBOutlet var splitView: NSSplitView!
    @IBOutlet var leftTopView: NSView!
    @IBOutlet var centerTopView: NSView!
    @IBOutlet var rightTopView: NSView!
    
    @IBOutlet var feedOutlineView: NSOutlineView!
    @IBOutlet var itemsTableView: NSTableView!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var articleSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var starButton: NSButton!

    @IBOutlet var itemsArrayController: NSArrayController!

    var toplevelArray = [Any]()

    private var currentItemIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.leftTopView.wantsLayer = true
        self.centerTopView.wantsLayer = true
        self.rightTopView.wantsLayer = true
        self.splitView.delegate = self
        
        self.itemsArrayController.managedObjectContext = NewsData.mainThreadContext
        self.itemsArrayController.entityName = "CDItem"
        let sortDescription = NSSortDescriptor(key: "id", ascending: false)
        self.itemsArrayController.sortDescriptors = [sortDescription]
        self.itemsArrayController.automaticallyRearrangesObjects = true
        
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SyncComplete"), object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.rebuildFoldersAndFeedsList()
            self?.feedOutlineView.reloadData()
            self?.itemsTableView.reloadData()
        }

        self.rebuildFoldersAndFeedsList()
        self.feedOutlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
//        try? self.itemsArrayController.fetch(with: nil, merge: false)
//        self.itemsTableView.reloadData()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.leftTopView.layer?.backgroundColor = NSColor(calibratedRed: 0.886, green: 0.890, blue: 0.894, alpha: 1.00).cgColor
        self.centerTopView.layer?.backgroundColor = NSColor(calibratedRed: 0.965, green: 0.965, blue: 0.965, alpha: 1.00).cgColor
        self.rightTopView.layer?.backgroundColor = NSColor(calibratedRed: 0.965, green: 0.965, blue: 0.965, alpha: 1.00).cgColor
        self.feedOutlineView.backgroundColor = NSColor(calibratedRed: 0.886, green: 0.890, blue: 0.894, alpha: 1.00)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func onSync(_ sender: Any) {
        NewsManager.shared.sync {
            NotificationCenter.default.post(name: NSNotification.Name("SyncComplete"), object: nil)
        }
    }
  
    @IBAction func onMarkRead(_ sender: Any) {
        if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
            self.markItemsRead(items: items)
        }
    }
    
    @IBAction func onStar(_ sender: Any) {
        if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
            let currentIndex = self.currentItemIndex
            if items.count > 0 && currentIndex > -1 && currentIndex < items.count {
                let item = items[self.currentItemIndex]
                let newState = !item.starred
                if newState == true {
                    CDStarred.update(items: [Int32(currentIndex)])
                    CDFeeds.adjustStarredCount(increment: true)
                } else {
                    CDUnstarred.update(items: [Int32(currentIndex)])
                    CDFeeds.adjustStarredCount(increment: false)
                }
                CDItem.markStarred(itemId: Int32(currentIndex), state: newState) { [weak self] in
                    self?.feedOutlineView.reloadData()
                    if newState {
                        self?.starButton.image = NSImage(named: "starred_mac")
                    } else {
                        self?.starButton.image = NSImage(named: "unstarred_mac")
                    }
                    if let cellView = self?.itemsTableView.view(atColumn: 0, row: currentIndex, makeIfNecessary: false) as? ArticleCellView {
                        cellView.refresh()
                    }
                }
            }
        }
    }
    
    @IBAction func onShare(_ sender: Any) {
    }
    
    func rebuildFoldersAndFeedsList() {
        self.toplevelArray.removeAll()
        self.toplevelArray.append("All Articles")
        self.toplevelArray.append("Starred Articles")
        if let folders = CDFolder.all() {
            self.toplevelArray.append(contentsOf: folders)
        }
        if let feeds = CDFeed.inFolder(folder: 0) {
            self.toplevelArray.append(contentsOf: feeds)
        }
        self.feedOutlineView.reloadData()
        try? self.itemsArrayController.fetch(with: nil, merge: false)
        self.itemsTableView.reloadData()
    }
    
    @objc func contextDidSave(_ notification: Notification) {
        print(notification)
        self.feedOutlineView.beginUpdates()
        self.itemsTableView.beginUpdates()
        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
            if let _ = insertedObjects.first as? CDFolder {
                self.rebuildFoldersAndFeedsList()
            } else if let _ = insertedObjects.first as? CDFeed {
                self.rebuildFoldersAndFeedsList()
            } else {
                self.itemsTableView.reloadData()
            }
        }
        
        if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
            if let _ = deletedObjects.first as? CDFolder {
                self.rebuildFoldersAndFeedsList()
            } else if let _ = deletedObjects.first as? CDFeed {
                self.rebuildFoldersAndFeedsList()
            } else {
                self.itemsTableView.reloadData()
            }
        }

        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
            print(updatedObjects)
            for object in updatedObjects {
                if let folder = object as? CDFolder {
                    self.feedOutlineView.reloadItem(folder)
                } else if let feed = object as? CDFeed {
                    self.feedOutlineView.reloadItem(feed)
                } else {
                    self.itemsTableView.reloadData()
                }
            }
        }

        if let refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>, !refreshedObjects.isEmpty {
            print(refreshedObjects)
        }
        
        if let invalidatedObjects = notification.userInfo?[NSInvalidatedObjectsKey] as? Set<NSManagedObject>, !invalidatedObjects.isEmpty {
            print(invalidatedObjects)
        }
        
        if let areInvalidatedAllObjects = notification.userInfo?[NSInvalidatedAllObjectsKey] as? Bool {
            print(areInvalidatedAllObjects)
        }
        self.itemsTableView.endUpdates()
        self.feedOutlineView.endUpdates()
    }

    func markItemsRead(items: [CDItem]) {
        let unreadItems = items.filter { (item) -> Bool in
            return item.unread == true
        }
        var selectedIndexes = [Int]()
        if let allItems = self.itemsArrayController.arrangedObjects as? [CDItem] {
            let myselectedItems = allItems.filter({ (item) -> Bool in
                unreadItems.firstIndex(of: item) != nil
            })
            selectedIndexes = myselectedItems.map({ allItems.index(of: $0) }).compactMap({ $0 })
        }
        
        if unreadItems.count > 0 {
            let unreadIds = unreadItems.map { $0.id }
            CDRead.update(items: unreadIds)
            for item in unreadItems {
                if var feed = CDFeed.feed(id: item.feedId) {
                    let feedUnreadCount = feed.unreadCount - 1
                    feed.unreadCount = feedUnreadCount
                    CDFeed.update(feeds: [feed])
                    if let folder = CDFolder.folder(id: feed.folderId) {
                        let folderUnreadCount = folder.unreadCount - 1
                        folder.unreadCount = folderUnreadCount
                        CDFolder.update(folders: [folder])
                    }
                }
            }
            CDItem.markRead(itemIds: unreadIds, completion: {
                self.feedOutlineView.reloadData()
                for i in selectedIndexes {
                    if let cellView = self.itemsTableView.view(atColumn: 0, row: i, makeIfNecessary: false) as? ArticleCellView {
                        cellView.refresh()
                    }
                }
                NewsManager.shared.updateBadge()
            })
        }
    }
    
    @IBAction func onArticleView(_ sender: Any) {
        self.tableViewSelectionDidChange(Notification(name: NSTableView.selectionDidChangeNotification, object: self.itemsTableView, userInfo: nil))
    }
    
}

extension ViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let folder = item as? FolderProtocol {
            return CDFeed.inFolder(folder: folder.id)?.count ?? 0
        }
        return self.toplevelArray.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _ = item as? FolderProtocol {
            return true
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let folder = item as? FolderProtocol {
            if let feedArray = CDFeed.inFolder(folder: folder.id) {
                return feedArray[index]
            }
        }
        return self.toplevelArray[index]
    }

}

extension ViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let feedView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedCell"), owner: self) as? FeedCellView {
            if let special = item as? String {
                if special == "All Articles" {
                    feedView.special(name: special, starred: false)
                } else {
                    feedView.special(name: special, starred: true)
                }
            } else if let folder = item as? FolderProtocol {              
                feedView.folder = folder
            } else if let feed = item as? FeedProtocol {
                feedView.feed = feed
            }
            return feedView
        }
        return nil
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView else {
            return
        }

        let selectedIndex = outlineView.selectedRow
        
        if selectedIndex == 0 {
            print("All articles selected")
            self.itemsArrayController.filterPredicate = nil
        } else if selectedIndex == 1 {
            print("Starred articles selected")
            let predicate = NSPredicate(format: "starred == true")
            self.itemsArrayController.filterPredicate = predicate
        } else if let folder = outlineView.item(atRow: selectedIndex) as? CDFolder {
            print("Folder: \(folder.name ?? "") selected")
            if let feedIds = CDFeed.idsInFolder(folder: folder.id) {
                let predicate = NSPredicate(format:"feedId IN %@", feedIds)
                self.itemsArrayController.filterPredicate = predicate
            }
        } else if let feed = outlineView.item(atRow: selectedIndex) as? CDFeed {
            print("Feed: \(feed.title ?? "") selected")
            let predicate = NSPredicate(format: "feedId == %d", feed.id)
            self.itemsArrayController.filterPredicate = predicate
        }
        self.itemsTableView.reloadData()
        self.itemsTableView.scrollRowToVisible(0)
    }

}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
            return items.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
            return items[row]
        }
        return nil
    }
}


extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
            let item = items[row]
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ItemCell"), owner: nil) as? ArticleCellView {
                cell.item = item
                return cell
            }
            return nil
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let _ = notification.object as? NSTableView else {
            return
        }
        
        let selectedIndex = self.itemsTableView.selectedRow
        if selectedIndex > -1 {
            if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
                let item = items[selectedIndex]
                self.currentItemIndex = selectedIndex
                self.markItemsRead(items: [item])
                switch self.articleSegmentedControl.selectedSegment {
                case 0:
                    if let summary = item.body {
                        let feed = CDFeed.feed(id: item.feedId)
                        if let url = ArticleHelper.writeAndLoadHtml(html: summary, item: item as ItemProtocol, feedTitle: feed?.title) {
                            if let containerURL = ArticleHelper.documentsFolderURL {
                                self.webView.loadFileURL(url, allowingReadAccessTo: containerURL)
                            }
                        }
                    }
                case 1:
                    if let itemUrl = item.url {
                        let url = URL(string: itemUrl)
                        if let url = url {
                            self.webView.load(URLRequest(url: url))
                        }
                    }
                default:
                    break
                }
            }
            self.feedOutlineView.reloadData()
        }
    }
    
}

extension ViewController: NSSplitViewDelegate {
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        var result: CGFloat = 5000.0
        switch dividerIndex {
        case 0:
            result = 400.0
        case 1:
            result = self.leftTopView.frame.width + 700.0
        default:
            result = 5000.0
        }
        return result
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        var result: CGFloat = 300.0
        switch dividerIndex {
        case 0:
            result = 100.0
        case 1:
            result = self.leftTopView.frame.width + 100.0
        default:
            result = 300.0
        }
        return result
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        if view == self.leftTopView || view == self.centerTopView {
            return false
        }
        return true
    }
    
}

extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView != self.webView {
            decisionHandler(.allow)
            return
        }

        if let url = navigationAction.request.url, let scheme = url.scheme {
            if (scheme == "file" || scheme.starts(with: "itms"))  {
                if url.absoluteString.contains("itunes.apple.com") {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel);
                    return;
                }
            }
        }

        if navigationAction.navigationType != .other {
            if let url = navigationAction.request.url {
                let showingSummary = (webView.url?.scheme == "file" || webView.url?.scheme == "about")
                if showingSummary {
                    self.webView?.load(URLRequest(url: url))
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Starting navigation to \(navigation.debugDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
}
