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
    @IBOutlet weak var shareButton: NSButton!
    @IBOutlet weak var syncSpinner: NSProgressIndicator!

    @IBOutlet var itemsArrayController: NSArrayController!

    @objc dynamic let managedContext: NSManagedObjectContext = NewsData.mainThreadContext
    @objc dynamic let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
    @objc dynamic var itemsFilterPredicate: NSPredicate? = nil

    var toplevelArray = [Any]()

    private var currentItemId: Int32 = -1
    private var currentFeedRowIndex: Int = 0

    private var selectionObserver: Any? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.leftTopView.wantsLayer = true
        self.centerTopView.wantsLayer = true
        self.rightTopView.wantsLayer = true
        self.splitView.delegate = self

        NotificationCenter.default.addObserver(forName: NSNotification.Name("SyncInitiated"), object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.syncSpinner.startAnimation(self)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("SyncComplete"), object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.itemsArrayController.fetch(nil)
            self?.rebuildFoldersAndFeedsList()
            self?.feedOutlineView.reloadData()
            self?.itemsTableView.reloadData()
            self?.syncSpinner.stopAnimation(self)
        }

        self.rebuildFoldersAndFeedsList()
        self.feedOutlineView.selectRowIndexes(IndexSet(integer: self.currentFeedRowIndex), byExtendingSelection: false)
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
        NotificationCenter.default.post(name: NSNotification.Name("SyncInitiated"), object: nil)
        NewsManager.shared.sync {
            NotificationCenter.default.post(name: NSNotification.Name("SyncComplete"), object: nil)
        }
    }

    @IBAction func onShowHideRead(_ sender: Any) {
        let notification = Notification(name: Notification.Name(""), object: self.feedOutlineView, userInfo: nil)
        self.outlineViewSelectionDidChange(notification)
    }

    @IBAction func onMarkRead(_ sender: Any) {
        if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
            let filteredItems = items.filter { (item) -> Bool in
                return item.unread == true
            }
            self.markItems(items: filteredItems, unread: false)
        }
    }

    @IBAction func onMarkUnread(_ sender: Any) {
        if let currentItem = self.itemsArrayController.selectedObjects.first as? CDItem {
            self.markItems(items: [currentItem], unread: !currentItem.unread)
        }
    }

    @IBAction func onStar(_ sender: Any) {
        if let currentItem = self.itemsArrayController.selectedObjects.first as? CDItem {
            let newState = !currentItem.starred
            if newState == true {
                CDStarred.update(items: [currentItem.id])
                CDFeeds.adjustStarredCount(increment: true)
            } else {
                CDUnstarred.update(items: [currentItem.id])
                CDFeeds.adjustStarredCount(increment: false)
            }
            NewsManager.shared.markStarred(item: currentItem, starred: newState) { [weak self] in
                self?.feedOutlineView.reloadItem(self?.toplevelArray[1])
            }
        }
    }
    
    @IBAction func onShare(_ sender: Any) {
        //See https://github.com/hawkfalcon/CustomSharingService on how to customize this
        if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
            let currentId = self.currentItemId
            if items.count > 0 && currentId > -1 {
                let filteredItems = items.filter({ return $0.id == currentId })
                if let currentItem = filteredItems.first {
                    if let url = URL(string: currentItem.url ?? "") {
                        let shareItems = [url]
                        let sharingPicker:NSSharingServicePicker = NSSharingServicePicker.init(items: shareItems)
                        sharingPicker.show(relativeTo: self.shareButton.bounds, of: self.shareButton, preferredEdge: .minY)
                    }
                }
            }
        }
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
    }

    func markItems(items: [CDItem], unread: Bool) {
        if items.count > 0 {
            let changingIds = items.map { $0.id }
            if unread {
                CDUnread.update(items: changingIds)
            } else {
                CDRead.update(items: changingIds)
            }
            for item in items {
                if var feed = CDFeed.feed(id: item.feedId) {
                    var feedUnreadCount = feed.unreadCount
                    if unread {
                        feedUnreadCount += 1
                    } else {
                        feedUnreadCount -= 1
                    }
                    feed.unreadCount = feedUnreadCount
                    CDFeed.update(feeds: [feed])
                    if let folder = CDFolder.folder(id: feed.folderId) {
                        var folderUnreadCount = folder.unreadCount
                        if unread {
                            folderUnreadCount += 1
                        } else {
                            folderUnreadCount -= 1
                        }
                        folder.unreadCount = folderUnreadCount
                        CDFolder.update(folders: [folder])
                    }
                }
            }
            NewsManager.shared.markRead(itemIds: changingIds, state: unread) { [weak self] in
                let selectedRowIndexes = self?.feedOutlineView.selectedRowIndexes
                self?.feedOutlineView.reloadData()
                self?.feedOutlineView.selectRowIndexes(selectedRowIndexes!, byExtendingSelection: false)
                NewsManager.shared.updateBadge()
            }
        }
    }
    
    @IBAction func onArticleView(_ sender: Any) {
        self.tableViewSelectionDidChange(Notification(name: NSTableView.selectionDidChangeNotification, object: self.itemsTableView, userInfo: nil))
    }

    @IBAction func onPreviousFeed(_ sender: Any) {
        var selectedIndexes = self.feedOutlineView.selectedRowIndexes
        if selectedIndexes.count == 0 {
            selectedIndexes = IndexSet(integer: self.currentFeedRowIndex)
        }
        if let min = selectedIndexes.min(), min > 0 {
            self.feedOutlineView.selectRowIndexes(IndexSet(integer: min - 1), byExtendingSelection: false)
        }
    }

    @IBAction func onNextFeed(_ sender: Any) {
        var selectedIndexes = self.feedOutlineView.selectedRowIndexes
        if selectedIndexes.count == 0 {
            selectedIndexes = IndexSet(integer: self.currentFeedRowIndex)
        }
        if let min = selectedIndexes.min(), min >= 0 {
            self.feedOutlineView.selectRowIndexes(IndexSet(integer: min + 1), byExtendingSelection: false)
        }
    }

    @IBAction func onPreviousArticle(_ sender: Any) {
        let selectedIndexes = self.itemsTableView.selectedRowIndexes
        if let min = selectedIndexes.min(), min > 0 {
            self.itemsTableView.selectRowIndexes(IndexSet(integer: min - 1), byExtendingSelection: false)
        }
    }

    @IBAction func onNextArticle(_ sender: Any) {
        let selectedIndexes = self.itemsTableView.selectedRowIndexes
        if let min = selectedIndexes.min(), min >= 0 {
            self.itemsTableView.selectRowIndexes(IndexSet(integer: min + 1), byExtendingSelection: false)
        }
    }

    @IBAction func onSummary(_ sender: Any) {
        self.articleSegmentedControl.selectSegment(withTag: 0)
        self.onArticleView(self)
    }

    @IBAction func onWeb(_ sender: Any) {
        self.articleSegmentedControl.selectSegment(withTag: 1)
        self.onArticleView(self)
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
        self.currentFeedRowIndex = selectedIndex
        if selectedIndex == 0 {
            print("All articles selected")
            if NSUserDefaultsController.shared.defaults.integer(forKey: "hideRead") == 0 {
                self.itemsFilterPredicate = NSPredicate(format: "unread == true")
            } else {
                self.itemsFilterPredicate = nil
            }
        } else if selectedIndex == 1 {
            print("Starred articles selected")
            self.itemsFilterPredicate = NSPredicate(format: "starred == true")
        } else if let folder = outlineView.item(atRow: selectedIndex) as? CDFolder {
            print("Folder: \(folder.name ?? "") selected")
            if let feedIds = CDFeed.idsInFolder(folder: folder.id) {
                if NSUserDefaultsController.shared.defaults.integer(forKey: "hideRead") == 0 {
                    let unreadPredicate = NSPredicate(format: "unread == true")
                    let feedPredicate = NSPredicate(format:"feedId IN %@", feedIds)
                    self.itemsFilterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unreadPredicate, feedPredicate])
                } else {
                    self.itemsFilterPredicate = NSPredicate(format:"feedId IN %@", feedIds)
                }
            }
        } else if let feed = outlineView.item(atRow: selectedIndex) as? CDFeed {
            print("Feed: \(feed.title ?? "") selected")
            if NSUserDefaultsController.shared.defaults.integer(forKey: "hideRead") == 0 {
                let unreadPredicate = NSPredicate(format: "unread == true")
                let feedPredicate = NSPredicate(format: "feedId == %d", feed.id)
                self.itemsFilterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unreadPredicate, feedPredicate])
            } else {
                self.itemsFilterPredicate = NSPredicate(format: "feedId == %d", feed.id)
            }
        }
        self.itemsTableView.scrollRowToVisible(0)
    }

}

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ItemCell"), owner: nil) as? ArticleCellView {
                return cell
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
                self.currentItemId = item.id
                if item.unread {
                    self.markItems(items: [item], unread: false)
                }
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

extension ViewController: NSUserInterfaceValidations {

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(onStar(_:)) {
//            print("validating item \(item)")
            if let currentItem = self.itemsArrayController.selectedObjects.first as? CDItem {
                if let menuItem = item as? NSMenuItem {
                    if currentItem.starred {
                        menuItem.title = "Unstar"
                    } else {
                        menuItem.title = "Star"
                    }
                }
            }
        } else if item.action == #selector(onMarkUnread(_:)) {
            if let currentItem = self.itemsArrayController.selectedObjects.first as? CDItem {
                if let menuItem = item as? NSMenuItem {
                    if currentItem.unread {
                        menuItem.title = "Mark Read"
                    } else {
                        menuItem.title = "Mark Unread"
                    }
                }
            }
        }

        return true

    }

}
