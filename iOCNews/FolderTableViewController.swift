//
//  FolderTableViewController.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/1/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

@objc
protocol FolderControllerDelegate {
    func folderSelected(folder: Int)
}

@objcMembers
class FolderTableViewController: UITableViewController {

    var delegate: FolderControllerDelegate?
    var feed: Feed?
    var folders = [Folder]()
    
    private var selectedFolderId: Int32 = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.ph_popoverBackground
        NotificationCenter.default.addObserver(forName: Notification.Name("ThemeUpdate"), object: nil, queue: .main) { _ in
            self.tableView.backgroundColor = UIColor.ph_popoverBackground
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedFolderId = self.feed?.folderId ?? 0;
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)

        cell.accessoryType = .none
        if (indexPath.row == 0) {
            cell.textLabel?.text = "(No Folder)"
            if selectedFolderId == 0 {
                cell.accessoryType = .checkmark
            }
        } else {
            let folder = folders[indexPath.row - 1]
            cell.textLabel?.text = folder.name
            let folderIds = folders.compactMap( { $0.myId })
            let folderIdIndex = folderIds.firstIndex(of: selectedFolderId)
            if (folderIdIndex == indexPath.row - 1) {
                cell.accessoryType = .checkmark;
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let delegate = delegate {
            if indexPath.row == 0 {
                selectedFolderId = 0;
                delegate.folderSelected(folder: 0)
            } else {
                let newFolderId = folders.compactMap( { $0.myId })[indexPath.row - 1]
                selectedFolderId = newFolderId
                delegate.folderSelected(folder: Int(selectedFolderId))
            }
        }
        tableView.reloadData()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSave(_ sender: Any) {
        if let feed = feed, feed.folderId != selectedFolderId {
            feed.folderId = selectedFolderId
            OCNewsHelper.shared()?.moveFeedOffline(withId: Int(feed.myId), toFolderWithId: Int(feed.folderId))
        }
        dismiss(animated: true, completion: nil)
    }
    
}
