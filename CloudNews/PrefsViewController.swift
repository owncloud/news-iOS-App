//
//  PrefsViewController.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/23/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import KeychainAccess
import Alamofire

class PrefsViewController: NSViewController {
    
    @IBOutlet var serverTextField: NSTextField!
    @IBOutlet var usernameTextField: NSTextField!
    @IBOutlet var passwordTextField: NSSecureTextField!
    @IBOutlet var connectionActivityIndicator: NSProgressIndicator!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var tabView: NSTabView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let keychain = Keychain(service: "com.peterandlinda.CloudNews")
        let username = keychain["username"]
        let password = keychain["password"]
        let server = UserDefaults.standard.string(forKey: "server")
        let version = UserDefaults.standard.string(forKey: "version")
        self.serverTextField.stringValue = server ?? ""
        self.usernameTextField.stringValue = username ?? ""
        self.passwordTextField.stringValue = password ?? ""
        if server == nil || server?.count == 0 {
            self.tabView.selectLastTabViewItem(nil)
        }
        if let version = version, version.count > 0 {
            self.statusLabel.stringValue = "News version \(version) found on server"
        } else {
            self.statusLabel.stringValue = "Not connected to News on a server"
        }
    }
    
    @IBAction func onConnect(_ sender: Any) {
        self.connectionActivityIndicator.startAnimation(nil)
        
        let urlString = "\(self.serverTextField.stringValue)/apps/news/api/v1-2"
        if let url = URL(string: urlString)?.appendingPathComponent("/status") {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = HTTPMethod.get.rawValue
            let username = self.usernameTextField.stringValue
            let password = self.passwordTextField.stringValue
            if let authorizationHeader = Request.authorizationHeader(user: username, password: password) {
                urlRequest.setValue(authorizationHeader.value, forHTTPHeaderField: authorizationHeader.key)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                Alamofire.request(urlRequest).responseDecodable(completionHandler: { [weak self] (response: DataResponse<Status>) in
                    if let status = response.value {
                        print(status)
                        let keychain = Keychain(service: "com.peterandlinda.CloudNews")
                        keychain["username"] = username
                        keychain["password"] = password
                        UserDefaults.standard.set(self?.serverTextField.stringValue, forKey: "server")
                        UserDefaults.standard.set(status.version, forKey: "version")
                        self?.statusLabel.stringValue = "News version \(status.version ?? "") found on server"
                    }
                    self?.connectionActivityIndicator.stopAnimation(nil)
                })
            } else {
                self.connectionActivityIndicator.stopAnimation(nil)
            }
        } else {
            self.connectionActivityIndicator.stopAnimation(nil)
        }
    }
}

