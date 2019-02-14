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
    @IBOutlet weak var leftView: NSView!
    @IBOutlet weak var centerView: NSView!
    @IBOutlet weak var rightView: NSView!

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
    @IBOutlet var feedsTreeController: NSTreeController!

    @objc dynamic let managedContext: NSManagedObjectContext = NewsData.mainThreadContext
    @objc dynamic let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
    @objc dynamic let feedSortDescriptors = [NSSortDescriptor(key: "sortId", ascending: true)]
    @objc dynamic var itemsFilterPredicate: NSPredicate? = nil
    @objc dynamic var nodeArray = [FeedTreeNode]()

    private var currentItemId: Int32 = -1
    private var currentFeedRowIndex: Int = 0

    private var selectionObserver: Any? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.leftTopView.wantsLayer = true
        self.centerTopView.wantsLayer = true
        self.rightTopView.wantsLayer = true

        NotificationCenter.default.addObserver(forName: NSNotification.Name("SyncInitiated"), object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.syncSpinner.startAnimation(self)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("SyncComplete"), object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.itemsArrayController.fetch(nil)
            self?.feedsTreeController.rearrangeObjects()
            self?.syncSpinner.stopAnimation(self)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("FolderSync"), object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            if let added = notification.userInfo?["added"] as? [FolderSync] {
                for addition in added {
                    if let folder = CDFolder.folder(id: addition.id) {
                        self?.nodeArray.append(FolderFeedNode(folder: folder))
                    }
                }
            }
            if let deleted = notification.userInfo?["deleted"] as? [FolderSync] {
                for deletion in deleted {
                    if let folder = CDFolder.folder(id: deletion.id) {
                        let index = self?.nodeArray.firstIndex(where: { (node) -> Bool in
                            if let node = node as? FolderFeedNode {
                                return node.folder.id == folder.id
                            }
                            return false
                        })
                        if let index = index {
                            self?.nodeArray.remove(at: index)
                        }
                    }
                }
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("FeedSync"), object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            if let added = notification.userInfo?["added"] as? [FeedSync] {
                for addition in added {
                    if addition.folderId == 0 {
                        if let feed = CDFeed.feed(id: addition.id) {
                            self?.nodeArray.append(FeedNode(feed: feed))
                        }
                    }
                }
            }
            if let deleted = notification.userInfo?["deleted"] as? [FeedSync] {
                for deletion in deleted {
                    if let feed = CDFeed.feed(id: deletion.id) {
                        let index = self?.nodeArray.firstIndex(where: { (node) -> Bool in
                            if let node = node as? FeedNode {
                                return node.feed.id == feed.id && feed.folderId != 0
                            }
                            return false
                        })
                        if let index = index {
                            self?.nodeArray.remove(at: index)
                        }
                    }
                }
            }
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
                self?.feedOutlineView.reloadItem(self?.nodeArray[1])
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
                        sharingPicker.delegate = self
                        sharingPicker.show(relativeTo: self.shareButton.bounds, of: self.shareButton, preferredEdge: .minY)
                    }
                }
            }
        }
    }

    func setClipboard(url: URL) {
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        clipboard.writeObjects([url as NSPasteboardWriting])
        clipboard.setString(url.absoluteString, forType: .string)
    }

    func rebuildFoldersAndFeedsList() {
        self.nodeArray.removeAll()
        self.nodeArray.append(AllFeedNode())
        self.nodeArray.append(StarredFeedNode())
        if let folders = CDFolder.all() {
            for folder in folders {
                self.nodeArray.append(FolderFeedNode(folder: folder))
            }
        }
        if let feeds = CDFeed.inFolder(folder: 0) {
            for feed in feeds {
                self.nodeArray.append(FeedNode(feed: feed))
            }
        }
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
                if let feed = CDFeed.feed(id: item.feedId) {
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

extension ViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let feedView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedCell"), owner: self) as? FeedCellView {
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

        if let selectedObject = self.feedsTreeController.selectedObjects.first as? FeedTreeNode {

            switch selectedObject {
            case _ as AllFeedNode:
                if NSUserDefaultsController.shared.defaults.integer(forKey: "hideRead") == 0 {
                    self.itemsFilterPredicate = NSPredicate(format: "unread == true")
                } else {
                    self.itemsFilterPredicate = nil
                }
            case _ as StarredFeedNode:
                print("Starred articles selected")
                self.itemsFilterPredicate = NSPredicate(format: "starred == true")
            case let folderNode as FolderFeedNode:
                print("Folder: \(folderNode.folder.name ?? "") selected")
                if let feedIds = CDFeed.idsInFolder(folder: folderNode.folder.id) {
                    if NSUserDefaultsController.shared.defaults.integer(forKey: "hideRead") == 0 {
                        let unreadPredicate = NSPredicate(format: "unread == true")
                        let feedPredicate = NSPredicate(format:"feedId IN %@", feedIds)
                        self.itemsFilterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unreadPredicate, feedPredicate])
                    } else {
                        self.itemsFilterPredicate = NSPredicate(format:"feedId IN %@", feedIds)
                    }
                }

            case let feedNode as FeedNode:
                print("Feed: \(feedNode.feed.title ?? "") selected")
                if NSUserDefaultsController.shared.defaults.integer(forKey: "hideRead") == 0 {
                    let unreadPredicate = NSPredicate(format: "unread == true")
                    let feedPredicate = NSPredicate(format: "feedId == %d", feedNode.feed.id)
                    self.itemsFilterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unreadPredicate, feedPredicate])
                } else {
                    self.itemsFilterPredicate = NSPredicate(format: "feedId == %d", feedNode.feed.id)
                }
            default:
                break
            }
        }
        self.itemsTableView.scrollRowToVisible(0)
    }

}

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ItemCell"), owner: nil) as? ArticleCellView {
                if let items = self.itemsArrayController.arrangedObjects as? [CDItem] {
                    cell.item = items[row]
                }
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
            result = self.leftView.frame.width + 700.0
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
            result = self.leftView.frame.width + 200.0
        default:
            result = 300.0
        }
        return result
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        if view == self.leftView || view == self.centerView {
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

extension ViewController: NSSharingServicePickerDelegate {
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: NSImage.Name("copy")), let image2 = NSImage(named: NSImage.Name("web")) else {
            return proposedServices
        }

        var share = proposedServices
        let customService = NSSharingService(title: "Copy Link", image: image, alternateImage: image, handler: {
            if let url = items.first as? URL {
                self.setClipboard(url: url)
            }
        })
        share.insert(customService, at: 0)
        let customService2 = NSSharingService(title: "Open in Browser", image: image2, alternateImage: image2, handler: {
            if let url = items.first as? URL {
                NSWorkspace.shared.open(url)
            }
        })
        share.insert(customService2, at: 0)

        return share
    }
}
