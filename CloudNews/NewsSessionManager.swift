//
//  NewsSessionManager.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/20/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import Alamofire

class NewsSessionManager: Alamofire.SessionManager {

    static let shared = NewsSessionManager()
    
    init() {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.peterandlinda.CloudNews.background")
        super.init(configuration: configuration)
    }
    
}


class NewsManager {
    
    static let shared = NewsManager()

    func addFeed(url: String) {
        let router = Router.createFeed(url: url, folder: 0)
        
        NewsSessionManager.shared.request(router).responseDecodable(completionHandler: { (response: DataResponse<Feeds>) in
            debugPrint(response)
        })
    }
    
    func addFolder(name: String) {
        let router = Router.createFolder(name: name)
        
        NewsSessionManager.shared.request(router).responseDecodable(completionHandler: { (response: DataResponse<Folders>) in
            debugPrint(response)
        })
    }

    /*
     Initial sync
     
     1. unread articles: GET /items?type=3&getRead=false&batchSize=-1
     2. starred articles: GET /items?type=2&getRead=true&batchSize=-1
     3. folders: GET /folders
     4. feeds: GET /feeds
     */
    
    func initialSync() {
        
        // 1.
        let unreadParameters: Parameters = ["type": 3,
                                            "getRead": false,
                                            "batchSize": -1]
        
        let unreadItemRouter = Router.items(parameters: unreadParameters)
        
        NewsSessionManager.shared.request(unreadItemRouter).responseDecodable(completionHandler: { (response: DataResponse<Items>) in
//            debugPrint(response)
            if let items = response.value?.items {
                CDItem.update(items: items)
            }
        })

        // 2.
//        let starredParameters: Parameters = ["type": 2,
//                                             "getRead": true,
//                                             "batchSize": -1]
//        
//        let starredItemRouter = Router.items(parameters: starredParameters)
//        
//        NewsSessionManager.shared.request(starredItemRouter).responseDecodable(completionHandler: { (response: DataResponse<Items>) in
//            debugPrint(response)
//        })

        // 3.
        NewsSessionManager.shared.request(Router.folders).responseDecodable(completionHandler: { (response: DataResponse<Folders>) in
//            debugPrint(response)
            if let folders = response.value?.folders {
                CDFolder.update(folders: folders)
            }
        })

        // 4.
        NewsSessionManager.shared.request(Router.feeds).responseDecodable(completionHandler: { (response: DataResponse<Feeds>) in
//            debugPrint(response)
            if let newestItemId = response.value?.newestItemId, let starredCount = response.value?.starredCount {
                CDFeeds.update(starredCount: starredCount, newestItemId: newestItemId)
            }
            if let feeds = response.value?.feeds {
                CDFeed.update(feeds: feeds)
            }
        })
    }
    
    
    /*
     Syncing
     
     When syncing, you want to push read/unread and starred/unstarred items to the server and receive new and updated items, feeds and folders. To do that, call the following routes:
     
     1. Notify the News app of unread articles: PUT /items/unread/multiple {"items": [1, 3, 5] }
     2. Notify the News app of read articles: PUT /items/read/multiple {"items": [1, 3, 5]}
     3. Notify the News app of starred articles: PUT /items/starred/multiple {"items": [{"feedId": 3, "guidHash": "adadafasdasd1231"}, ...]}
     4. Notify the News app of unstarred articles: PUT /items/unstarred/multiple {"items": [{"feedId": 3, "guidHash": "adadafasdasd1231"}, ...]}
     5. Get new folders: GET /folders
     6. Get new feeds: GET /feeds
     7. Get new items and modified items: GET /items/updated?lastModified=12123123123&type=3

     */
    func sync() {
        
        // 5.
        NewsSessionManager.shared.request(Router.folders).responseDecodable(completionHandler: { (response: DataResponse<Folders>) in
            //            debugPrint(response)
            if let folders = response.value?.folders {
                CDFolder.update(folders: folders)
            }
        })
        
        // 6.
        NewsSessionManager.shared.request(Router.feeds).responseDecodable(completionHandler: { (response: DataResponse<Feeds>) in
            //            debugPrint(response)
            if let newestItemId = response.value?.newestItemId, let starredCount = response.value?.starredCount {
                CDFeeds.update(starredCount: starredCount, newestItemId: newestItemId)
            }
            if let feeds = response.value?.feeds {
                CDFeed.update(feeds: feeds)
            }
        })

        // 7.
        let updatedParameters: Parameters = ["type": 3,
                                            "lastModified": CDItem.lastModified()]
        
        let updatedItemRouter = Router.updatedItems(paramters: updatedParameters)
        
        NewsSessionManager.shared.request(updatedItemRouter).responseDecodable(completionHandler: { (response: DataResponse<Items>) in
            //            debugPrint(response)
            if let items = response.value?.items {
                CDItem.update(items: items)
            }
        })

        
    }
}
