//
//  NewsRouter.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/20/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Alamofire
import KeychainAccess

enum Router: URLRequestConvertible {
    case feeds
    case createFeed(url: String, folder: Int)
    case deleteFeed(id: Int)
    case moveFeed(id: Int, folder: Int)
    case renameFeed(id: Int, newName: String)
    case markFeedRead(id: Int, newestItemId: Int)

    case folders
    case createFolder(name: String)
    case deleteFolder(id: Int)
    case renameFolder(id: Int, newName: String)
    case markFolderRead(id: Int, newestItemId: Int)
    
    case items(parameters: Parameters)
    case updatedItems(parameters: Parameters)
    case itemRead(id: Int)
    case itemsRead(parameters: Parameters)
    case itemUnread(id: Int)
    case itemsUnread(parameters: Parameters)
    case itemStarred(id: Int, guid: String)
    case itemsStarred(parameters: Parameters)
    case itemUnstarred(id: Int, guid: String)
    case itemsUnstarred(parameters: Parameters)
    case allItemsRead

    var method: HTTPMethod {
        switch self {
        case .feeds, .folders, .items, .updatedItems:
            return .get
        case .createFeed, .createFolder:
            return .post
        case .deleteFeed, .deleteFolder:
            return .delete
        case .moveFeed, .renameFeed, .markFeedRead, .renameFolder, .markFolderRead, .itemRead, .itemsRead, .itemUnread, .itemsUnread, .itemStarred,. itemsStarred, .itemUnstarred, .itemsUnstarred, .allItemsRead:
            return .put
        }
    }
    
    var path: String {
        switch self {
        case .feeds:
            return "/feeds"
        case .createFeed(_ , _):
            return "/feeds"
        case .deleteFeed(let id):
            return "/feeds/\(id)"
        case .moveFeed(let id, _):
            return "/feeds/\(id)/move"
        case .renameFeed(let id, _):
            return "/feeds/\(id)/rename"
        case .markFeedRead(let id, _):
            return "/feeds/\(id)/read"

        case .folders:
            return "/folders"
        case .createFolder(_):
            return "/folders"
        case .deleteFolder(let id):
            return "/folders/\(id)"
        case .renameFolder(let id, _):
            return "/folders/\(id)"
        case .markFolderRead(let id, _):
            return "/folders/\(id)/read"

        case .items:
            return "/items"
        case .updatedItems(_):
            return "/items/updated"
        case .itemRead(let id):
            return "/item/\(id)/read"
        case .itemsRead(_):
            return "/items/read/multiple"
        case .itemUnread(let id):
            return "/item/\(id)/unread"
        case .itemsUnread(_):
            return "/items/unread/multiple"
        case .itemStarred(let id, let guid):
            return "/item/\(id)/\(guid)/star"
        case .itemsStarred(_):
            return "/items/star/multiple"
        case .itemUnstarred(let id, let guid):
            return "/item/\(id)/\(guid)/unstar"
        case .itemsUnstarred(_):
            return "/items/unstar/multiple"
        case .allItemsRead:
            return "/items/read"
        }
    }
    
    // MARK: URLRequestConvertible
    
    func asURLRequest() throws -> URLRequest {
        let baseURLString = "\(UserDefaults.standard.string(forKey: "server") ?? "")/apps/news/api/v1-2"
        let url = try baseURLString.asURL()
      
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        let keychain = Keychain(service: "com.peterandlinda.CloudNews")
        let username = keychain["username"] ?? ""
        let password = keychain["password"] ?? ""
        if let authorizationHeader = Request.authorizationHeader(user: username, password: password) {
            urlRequest.setValue(authorizationHeader.value, forHTTPHeaderField: authorizationHeader.key)
        }
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        switch self {
//        case .feeds:
//            urlRequest = try URLEncoding.default.encode(urlRequest)
        case .createFeed(let url, let folder):
            let parameters = ["url": url, "folder": folder] as [String : Any]
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)

//        deleteFeed
//            moveFeed
//            renameFeed
//        markFeedRead
        
        case .createFolder(let name):
            let parameters = ["name": name]
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
//            deleteFolder
//            renameFolder
//            markFolderRead
        
        case .items(let parameters), .updatedItems(let parameters):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            
        case .itemsRead(let parameters), .itemsStarred(let parameters):
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)

        default:
            break
        }
        
        return urlRequest
    }
}
